import Foundation
import AVFoundation
import AppKit

enum MicrophonePermissionState: String {
    case notDetermined
    case granted
    case denied
    case restricted

    var isDenied: Bool {
        self == .denied || self == .restricted
    }

    static func from(_ status: AVAuthorizationStatus) -> MicrophonePermissionState {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .authorized:
            return .granted
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .denied
        }
    }
}

class AudioManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published private(set) var microphonePermissionState: MicrophonePermissionState = .notDetermined
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
    private var converter: AVAudioConverter?
    private var volumeMeter: AVAudioMixerNode?
    private let audioQueue = DispatchQueue(label: "co.blode.commandment.audio")
    private var _isRecordingOnAudioQueue = false

    /// When set, receives PCM16 audio chunks (~100ms each) during recording for real-time streaming.
    var audioChunkHandler: ((Data) -> Void)?
    private var pcm16ChunkBuffer = Data()
    private let chunkSampleThreshold = 2400 // 100ms at 24kHz

    override init() {
        super.init()
        setupRecordingURL()
        refreshMicrophonePermissionState()
    }
    
    // MARK: - Audio Recording Setup
    
    func refreshMicrophonePermissionState() {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        let mappedState = MicrophonePermissionState.from(status)
        if Thread.isMainThread {
            microphonePermissionState = mappedState
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.microphonePermissionState = mappedState
            }
        }
    }

    var isMicrophonePermissionDenied: Bool {
        microphonePermissionState.isDenied
    }

    func openMicrophoneSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func requestMicrophonePermissionIfNeeded(completion: ((Bool) -> Void)? = nil) {
        ensureMicrophonePermission { granted in
            completion?(granted)
        }
    }

    private func ensureMicrophonePermission(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        microphonePermissionState = MicrophonePermissionState.from(status)

        switch status {
        case .authorized:
            completion(true)

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.refreshMicrophonePermissionState()
                    completion(granted)
                }
            }

        case .denied, .restricted:
            completion(false)

        @unknown default:
            completion(false)
        }
    }
    
    private func setupRecordingURL() {
        let tempPath = FileManager.default.temporaryDirectory
        let url = tempPath.appendingPathComponent("commandment-recording.wav")
        recordingURL = url
        try? FileManager.default.removeItem(at: url)
        logInfo("AudioManager: Recording temp file path set to \(url.path)")
    }
    
    private func setupAudioEngine() {
        logInfo("AudioManager: Setting up audio engine")
        
        // Clean up existing engine if any
        cleanupAudioEngine()
        
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        inputNode = audioEngine.inputNode
        guard let inputNode = inputNode else {
            logError("AudioManager: Failed to get input node")
            return
        }
        
        volumeMeter = AVAudioMixerNode()
        guard let volumeMeter = volumeMeter else { return }
        
        audioEngine.attach(volumeMeter)
        
        let inputFormat = inputNode.inputFormat(forBus: 0)
        guard inputFormat.channelCount > 0, inputFormat.sampleRate > 0 else {
            logError("AudioManager: Invalid input format: \(inputFormat)")
            return
        }

        let whisperFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                        sampleRate: 24000,
                                        channels: 1,
                                        interleaved: false)!
        
        logDebug("AudioManager: Input format: \(inputFormat)")
        logDebug("AudioManager: Whisper format: \(whisperFormat)")
        
        volumeMeter.volume = 1.0
        audioEngine.connect(inputNode, to: volumeMeter, format: inputFormat)
        audioEngine.prepare()

        volumeMeter.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] (buffer, time) in
            self?.audioQueue.async { [weak self] in
                guard let self = self,
                      let recordingURL = self.recordingURL,
                      self._isRecordingOnAudioQueue else { return }

                var convertedBuffer: AVAudioPCMBuffer?

                if self.converter == nil && inputFormat != whisperFormat {
                    self.converter = AVAudioConverter(from: inputFormat, to: whisperFormat)
                }

                if let converter = self.converter {
                    let frameCount = AVAudioFrameCount(Float(buffer.frameLength) * Float(24000) / Float(inputFormat.sampleRate))
                    convertedBuffer = AVAudioPCMBuffer(pcmFormat: whisperFormat,
                                                     frameCapacity: frameCount)
                    convertedBuffer?.frameLength = frameCount

                    var error: NSError?
                    var consumed = false
                    let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                        if consumed {
                            outStatus.pointee = .noDataNow
                            return nil
                        }
                        consumed = true
                        outStatus.pointee = .haveData
                        return buffer
                    }

                    converter.convert(to: convertedBuffer!,
                                    error: &error,
                                    withInputFrom: inputBlock)

                    if error != nil {
                        logError("AudioManager: Conversion error: \(error!)")
                        return
                    }
                } else {
                    convertedBuffer = buffer
                }

                guard let finalBuffer = convertedBuffer else { return }

                if self.audioFile == nil {
                    do {
                        self.audioFile = try AVAudioFile(forWriting: recordingURL,
                                                        settings: whisperFormat.settings)
                        logInfo("AudioManager: Created new audio file at \(recordingURL)")
                    } catch {
                        logError("AudioManager: Failed to create audio file: \(error)")
                        return
                    }
                }

                do {
                    try self.audioFile?.write(from: finalBuffer)
                } catch {
                    logError("AudioManager: Failed to write buffer: \(error)")
                }

                // Stream PCM16 chunks to the Realtime API handler if active
                if let channelData = finalBuffer.floatChannelData?[0],
                   let handler = self.audioChunkHandler {
                    let count = Int(finalBuffer.frameLength)
                    let pcm16 = UnsafeMutableBufferPointer<Int16>.allocate(capacity: count)
                    for i in 0..<count {
                        let clamped = max(-1.0, min(1.0, channelData[i]))
                        pcm16[i] = Int16(clamped * 32767.0)
                    }
                    self.pcm16ChunkBuffer.append(UnsafeBufferPointer(pcm16))
                    pcm16.deallocate()

                    // Dispatch when we have ~100ms of audio
                    if self.pcm16ChunkBuffer.count >= self.chunkSampleThreshold * 2 {
                        let chunk = self.pcm16ChunkBuffer
                        self.pcm16ChunkBuffer = Data()
                        handler(chunk)
                    }
                }
            }
        }
    }
    
    private func cleanupAudioEngine() {
        logInfo("AudioManager: Cleaning up audio engine")
        audioEngine?.stop()
        volumeMeter?.removeTap(onBus: 0)
        audioEngine = nil
        inputNode = nil
        volumeMeter = nil
        converter = nil
        audioFile = nil
    }
    
    // MARK: - Recording Control
    
    func startRecording(completion: ((Bool) -> Void)? = nil) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.startRecording(completion: completion)
            }
            return
        }

        ensureMicrophonePermission { [weak self] granted in
            guard let self = self else {
                completion?(false)
                return
            }

            guard granted else {
                self.isRecording = false
                logInfo("AudioManager: Microphone permission not granted")
                completion?(false)
                return
            }

            self.startRecordingAuthorized(completion: completion)
        }
    }

    private func startRecordingAuthorized(completion: ((Bool) -> Void)? = nil) {
        logInfo("AudioManager: Starting recording")
        setupAudioEngine()

        audioQueue.async { [weak self] in
            guard let self = self else { return }

            guard let audioEngine = self.audioEngine else {
                logError("AudioManager: No audio engine available")
                self._isRecordingOnAudioQueue = false
                DispatchQueue.main.async {
                    completion?(false)
                }
                return
            }
            
            try? FileManager.default.removeItem(at: self.recordingURL!)
            self.audioFile = nil
            self.pcm16ChunkBuffer = Data()
            
            do {
                self._isRecordingOnAudioQueue = true
                try audioEngine.start()
                DispatchQueue.main.async {
                    self.isRecording = true
                    completion?(true)
                }
                logInfo("AudioManager: Recording started successfully")
            } catch {
                self._isRecordingOnAudioQueue = false
                logError("AudioManager: Failed to start recording: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion?(false)
                }
            }
        }
    }
    
    func stopRecording() -> URL? {
        logInfo("AudioManager: Stopping recording")
        guard let recordingURL = recordingURL else {
            logError("AudioManager: No recording URL available")
            return nil
        }

        // First mark as not recording to prevent new audio data from being processed
        isRecording = false

        // Synchronously stop audio processing and release file resources
        audioQueue.sync { [weak self] in
            self?._isRecordingOnAudioQueue = false
            // Flush remaining PCM16 chunk to handler
            if let self = self, let handler = self.audioChunkHandler, !self.pcm16ChunkBuffer.isEmpty {
                handler(self.pcm16ChunkBuffer)
                self.pcm16ChunkBuffer = Data()
            }
            logInfo("AudioManager: Stopping audio engine and cleaning up")
            self?.audioEngine?.stop()
            self?.volumeMeter?.removeTap(onBus: 0)
            self?.audioFile = nil
            // Clean up the engine for next recording
            self?.cleanupAudioEngine()
        }

        // Verify the file exists before returning
        if FileManager.default.fileExists(atPath: recordingURL.path) {
            logInfo("AudioManager: Recording saved successfully at \(recordingURL)")
            return recordingURL
        }
        logError("AudioManager: Recording file not found at \(recordingURL)")
        return nil
    }

}
