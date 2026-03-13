import Foundation
import Observation

@MainActor
@Observable
public final class SpeedAppController {
    public let speedTestViewModel: SpeedTestViewModel

    public var automaticTestInterval: AutoTestInterval {
        didSet {
            guard automaticTestInterval != oldValue else {
                return
            }

            settingsStore.automaticTestInterval = automaticTestInterval
            rescheduleAutomaticTests()
        }
    }

    public private(set) var nextAutomaticTestAt: Date?
    public private(set) var launchAtLoginState: LaunchAtLoginState
    public private(set) var launchAtLoginMessage: String?

    @ObservationIgnored
    private let settingsStore: SpeedSettingsStore

    @ObservationIgnored
    private let launchAtLoginManager: LaunchAtLoginManager

    @ObservationIgnored
    private var automaticTestingTask: Task<Void, Never>?

    public init(
        speedTestViewModel: SpeedTestViewModel = SpeedTestViewModel(),
        settingsStore: SpeedSettingsStore = SpeedSettingsStore(),
        launchAtLoginManager: LaunchAtLoginManager = LaunchAtLoginManager()
    ) {
        self.speedTestViewModel = speedTestViewModel
        self.settingsStore = settingsStore
        self.launchAtLoginManager = launchAtLoginManager
        self.automaticTestInterval = settingsStore.automaticTestInterval
        self.launchAtLoginState = launchAtLoginManager.currentState()
        self.launchAtLoginMessage = nil

        rescheduleAutomaticTests()
    }

    deinit {
        automaticTestingTask?.cancel()
    }

    public var nextAutomaticTestDescription: String {
        guard let nextAutomaticTestAt else {
            return "Automatische Messungen sind aktuell ausgeschaltet."
        }

        let relative = MetricFormatter.relativeTimestamp(nextAutomaticTestAt) ?? "später"
        return "Nächste automatische Messung \(relative)."
    }

    public var automaticTestingFootnote: String {
        automaticTestInterval.detail
    }

    public var canConfigureLaunchAtLogin: Bool {
        launchAtLoginState != .unsupported
    }

    public var launchAtLoginDescription: String? {
        switch launchAtLoginState {
        case .enabled:
            return "Speed startet automatisch nach der Anmeldung und bleibt in der Menüleiste verfügbar."
        case .disabled:
            return "Die App startet derzeit nur manuell."
        case .requiresApproval:
            return "macOS wartet noch auf deine Bestätigung in den Systemeinstellungen unter Allgemein > Anmeldeobjekte."
        case .unsupported:
            return nil
        }
    }

    public func setLaunchAtLoginEnabled(_ enabled: Bool) {
        launchAtLoginMessage = nil

        do {
            try launchAtLoginManager.setEnabled(enabled)
            refreshLaunchAtLoginState()
        } catch let error as LaunchAtLoginError {
            refreshLaunchAtLoginState()
            launchAtLoginMessage = error.errorDescription
        } catch {
            refreshLaunchAtLoginState()
            launchAtLoginMessage = error.localizedDescription
        }
    }

    public func refreshLaunchAtLoginState() {
        launchAtLoginState = launchAtLoginManager.currentState()
    }

    private func rescheduleAutomaticTests() {
        automaticTestingTask?.cancel()
        automaticTestingTask = nil
        nextAutomaticTestAt = nil

        guard let interval = automaticTestInterval.seconds else {
            return
        }

        automaticTestingTask = Task { [weak self] in
            guard let self else {
                return
            }

            while !Task.isCancelled {
                let nextFireDate = Date().addingTimeInterval(interval)
                self.nextAutomaticTestAt = nextFireDate

                do {
                    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                } catch {
                    return
                }

                guard !Task.isCancelled else {
                    return
                }

                self.speedTestViewModel.start()
            }
        }
    }
}
