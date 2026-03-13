import Foundation
import Observation

@MainActor
@Observable
public final class SpeedAppController {
    public let speedTestViewModel: SpeedTestViewModel
    public let localization: SpeedLocalization

    public var automaticTestInterval: AutoTestInterval {
        didSet {
            guard automaticTestInterval != oldValue else {
                return
            }

            settingsStore.automaticTestInterval = automaticTestInterval
            rescheduleAutomaticTests()
        }
    }

    public var appLanguage: AppLanguage {
        get {
            localization.appLanguage
        }
        set {
            localization.appLanguage = newValue
        }
    }

    public private(set) var nextAutomaticTestAt: Date?
    public private(set) var launchAtLoginState: LaunchAtLoginState

    private var launchAtLoginFeedback: LaunchAtLoginFeedback?

    @ObservationIgnored
    private let settingsStore: SpeedSettingsStore

    @ObservationIgnored
    private let launchAtLoginManager: LaunchAtLoginManager

    @ObservationIgnored
    private var automaticTestingTask: Task<Void, Never>?

    public init(
        speedTestViewModel: SpeedTestViewModel? = nil,
        settingsStore: SpeedSettingsStore = SpeedSettingsStore(),
        launchAtLoginManager: LaunchAtLoginManager = LaunchAtLoginManager(),
        localization: SpeedLocalization? = nil
    ) {
        let localization = localization ?? SpeedLocalization(settingsStore: settingsStore)

        self.localization = localization
        self.speedTestViewModel = speedTestViewModel ?? SpeedTestViewModel(localization: localization)
        self.settingsStore = settingsStore
        self.launchAtLoginManager = launchAtLoginManager
        self.automaticTestInterval = settingsStore.automaticTestInterval
        self.launchAtLoginState = launchAtLoginManager.currentState()

        rescheduleAutomaticTests()
    }

    deinit {
        automaticTestingTask?.cancel()
    }

    public var nextAutomaticTestDescription: String {
        let strings = localization.strings

        guard let nextAutomaticTestAt else {
            return strings.automaticTestsDisabledDescription
        }

        let relative = MetricFormatter.relativeTimestamp(
            nextAutomaticTestAt,
            locale: localization.locale
        ) ?? strings.laterHint
        return strings.nextAutomaticTestDescription(relative: relative)
    }

    public var automaticTestingFootnote: String {
        automaticTestInterval.detail(using: localization.strings)
    }

    public var canConfigureLaunchAtLogin: Bool {
        launchAtLoginState != .unsupported
    }

    public var launchAtLoginDescription: String? {
        let strings = localization.strings

        switch launchAtLoginState {
        case .enabled:
            return strings.launchAtLoginEnabledDescription
        case .disabled:
            return strings.launchAtLoginDisabledDescription
        case .requiresApproval:
            return strings.launchAtLoginRequiresApprovalDescription
        case .unsupported:
            return nil
        }
    }

    public var launchAtLoginMessage: String? {
        guard let launchAtLoginFeedback else {
            return nil
        }

        let strings = localization.strings

        switch launchAtLoginFeedback {
        case let .localized(error):
            return strings.launchAtLoginErrorDescription(error)
        case let .raw(message):
            return message
        }
    }

    public func setLaunchAtLoginEnabled(_ enabled: Bool) {
        launchAtLoginFeedback = nil

        do {
            try launchAtLoginManager.setEnabled(enabled)
            refreshLaunchAtLoginState()
        } catch let error as LaunchAtLoginError {
            refreshLaunchAtLoginState()
            launchAtLoginFeedback = .localized(error)
        } catch {
            refreshLaunchAtLoginState()
            launchAtLoginFeedback = .raw(error.localizedDescription)
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

private enum LaunchAtLoginFeedback: Equatable {
    case localized(LaunchAtLoginError)
    case raw(String)
}
