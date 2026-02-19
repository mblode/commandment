import AppKit
import SwiftUI

enum OverlayState: Equatable {
    case recording
    case processing
    case success
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
        panel?.orderFrontRegardless()

        if state == .success {
            dismissTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
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
        hosting.frame = NSRect(x: 0, y: 0, width: 200, height: 44)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 44),
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
            let x = screenFrame.midX - 100
            let y = screenFrame.minY + 80
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.panel = panel
        self.hostingView = hosting
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
            }
        }
        .font(.system(size: 13, weight: .medium))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
