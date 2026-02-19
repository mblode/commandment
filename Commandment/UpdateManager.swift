import Combine
import Foundation
import Sparkle

@MainActor
final class UpdateManager: ObservableObject {
    @Published private(set) var canCheckForUpdates: Bool
    @Published private(set) var automaticallyChecksForUpdates: Bool
    @Published private(set) var automaticallyDownloadsUpdates: Bool

    private let updaterController: SPUStandardUpdaterController
    private var cancellables: Set<AnyCancellable> = []

    init() {
        let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        updaterController = SPUStandardUpdaterController(
            startingUpdater: !isRunningTests,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        let updater = updaterController.updater
        canCheckForUpdates = updater.canCheckForUpdates
        automaticallyChecksForUpdates = updater.automaticallyChecksForUpdates
        automaticallyDownloadsUpdates = updater.automaticallyDownloadsUpdates

        observeUpdaterState()
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    func setAutomaticallyChecksForUpdates(_ enabled: Bool) {
        guard updaterController.updater.automaticallyChecksForUpdates != enabled else { return }
        updaterController.updater.automaticallyChecksForUpdates = enabled
    }

    func setAutomaticallyDownloadsUpdates(_ enabled: Bool) {
        guard updaterController.updater.automaticallyDownloadsUpdates != enabled else { return }
        updaterController.updater.automaticallyDownloadsUpdates = enabled
    }

    private func observeUpdaterState() {
        let updater = updaterController.updater

        updater.publisher(for: \.canCheckForUpdates)
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.canCheckForUpdates = $0 }
            .store(in: &cancellables)

        updater.publisher(for: \.automaticallyChecksForUpdates)
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.automaticallyChecksForUpdates = $0 }
            .store(in: &cancellables)

        updater.publisher(for: \.automaticallyDownloadsUpdates)
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.automaticallyDownloadsUpdates = $0 }
            .store(in: &cancellables)
    }
}
