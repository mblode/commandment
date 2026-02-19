import AppKit
import SwiftUI

enum OverlayState: Equatable {
    case recording
    case processing
    case success
    case copiedToClipboard
    case tooShort
}

@MainActor
class OverlayPanelController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<OverlayContentView>?
    private var dismissTimer: Timer?
    private var currentState: OverlayState = .recording

    static let shared = OverlayPanelController()

    private init() {}

    func show(state: OverlayState) {
        dismissTimer?.invalidate()

        guard state != currentState || panel == nil else {
            panel?.orderFrontRegardless()
            return
        }

        currentState = state

        if panel == nil {
            createPanel()
        }

        hostingView?.rootView = OverlayContentView(state: state)
        resizePanel()
        panel?.orderFrontRegardless()

        if state == .success || state == .tooShort || state == .copiedToClipboard {
            let delay: TimeInterval
            switch state {
            case .tooShort: delay = 2.0
            case .copiedToClipboard: delay = 2.5
            default: delay = 1.5
            }
            dismissTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                Task { @MainActor in self?.dismiss() }
            }
        }
    }

    func dismiss() {
        dismissTimer?.invalidate()
        panel?.orderOut(nil)
    }

    private func createPanel() {
        let contentView = OverlayContentView(state: currentState)
        let hosting = NSHostingView(rootView: contentView)

        let idealSize = hosting.fittingSize
        let panelWidth = max(idealSize.width, 120)
        let panelHeight = max(idealSize.height, 44)

        hosting.frame = NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false
        panel.ignoresMouseEvents = true
        panel.contentView = hosting

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - (panelWidth / 2)
            let y = screenFrame.minY + 80
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.panel = panel
        self.hostingView = hosting
    }

    private func resizePanel() {
        guard let hosting = hostingView, let panel = panel else { return }

        let idealSize = hosting.fittingSize
        let panelWidth = max(idealSize.width, 120)
        let panelHeight = max(idealSize.height, 44)

        hosting.frame = NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight)

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - (panelWidth / 2)
            let y = screenFrame.minY + 80
            panel.setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: true, animate: false)
        } else {
            panel.setContentSize(NSSize(width: panelWidth, height: panelHeight))
        }
    }
}

struct OverlayContentView: View {
    let state: OverlayState

    var body: some View {
        HStack(spacing: 8) {
            switch state {
            case .recording:
                Image(systemName: "waveform")
                    .foregroundStyle(.red)
                    .symbolEffect(.variableColor.iterative)
                Text("Recording...")
                    .foregroundStyle(.primary)

            case .processing:
                ProgressView()
                    .controlSize(.small)
                Text("Transcribing...")
                    .foregroundStyle(.primary)

            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Done")
                    .foregroundStyle(.primary)

            case .copiedToClipboard:
                Image(systemName: "doc.on.clipboard.fill")
                    .foregroundStyle(.blue)
                Text("Copied to clipboard")
                    .foregroundStyle(.primary)

            case .tooShort:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
                Text("Too short")
                    .foregroundStyle(.primary)
            }
        }
        .font(.system(size: 13, weight: .medium))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .fixedSize()
    }
}
