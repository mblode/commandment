import Foundation
import AppKit

class Logger {
    static let shared = Logger()

    private let logFileURL: URL
    private let dateFormatter: DateFormatter

    enum LogLevel: String {
        case info = "INFO"
        case error = "ERROR"
        case debug = "DEBUG"
    }
    
    private init() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.logFileURL = documentsDirectory.appendingPathComponent("Commandment.log")
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        log("Commandment application launched", level: .info)
    }

    func log(_ message: String, level: LogLevel = .info) {
        let timestamp = dateFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] [\(level.rawValue)] \(message)\n"
        
        print("📝 \(level.rawValue): \(message)")
        
        do {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                let fileHandle = try FileHandle(forWritingTo: logFileURL)
                fileHandle.seekToEndOfFile()
                if let data = logMessage.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            } else {
                try logMessage.write(to: logFileURL, atomically: true, encoding: .utf8)
            }
        } catch {
            print("Error writing to log file: \(error)")
        }
    }
    
    func info(_ message: String) {
        log(message, level: .info)
    }
    
    func error(_ message: String) {
        log(message, level: .error)
    }
    
    func debug(_ message: String) {
        log(message, level: .debug)
    }
    
    func openLogFile() {
        NSWorkspace.shared.open(logFileURL)
    }

    deinit {
        log("Commandment application terminated", level: .info)
    }
}

// Static functions for easier global access
func logInfo(_ message: String) {
    Logger.shared.info(message)
}

func logError(_ message: String) {
    Logger.shared.error(message)
}

func logDebug(_ message: String) {
    Logger.shared.debug(message)
} 
