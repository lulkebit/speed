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

    public var automaticallyChecksForUpdates: Bool {
        didSet {
            guard automaticallyChecksForUpdates != oldValue else {
                return
            }

            settingsStore.automaticallyChecksForUpdates = automaticallyChecksForUpdates

            if automaticallyChecksForUpdates {
                scheduleAutomaticUpdateCheck()
            } else {
                automaticUpdateCheckTask?.cancel()
                automaticUpdateCheckTask = nil

                if availableUpdate == nil {
                    appUpdateStatus = .automaticChecksDisabled
                }
            }
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
    public private(set) var availableUpdate: AppUpdateRelease?
    public private(set) var lastUpdateCheckAt: Date?

    private var launchAtLoginFeedback: LaunchAtLoginFeedback?
    private var appUpdateStatus: AppUpdateStatus

    @ObservationIgnored
    private let settingsStore: SpeedSettingsStore

    @ObservationIgnored
    private let launchAtLoginManager: LaunchAtLoginManager

    @ObservationIgnored
    private let appUpdater: any AppUpdateManaging

    @ObservationIgnored
    private let applicationTerminator: @Sendable () -> Void

    @ObservationIgnored
    private var automaticTestingTask: Task<Void, Never>?

    @ObservationIgnored
    private var automaticUpdateCheckTask: Task<Void, Never>?

    public init(
        speedTestViewModel: SpeedTestViewModel? = nil,
        settingsStore: SpeedSettingsStore = SpeedSettingsStore(),
        launchAtLoginManager: LaunchAtLoginManager = LaunchAtLoginManager(),
        localization: SpeedLocalization? = nil,
        appUpdater: any AppUpdateManaging = GitHubReleaseUpdater(),
        applicationTerminator: @escaping @Sendable () -> Void = {
            exit(EXIT_SUCCESS)
        }
    ) {
        let localization = localization ?? SpeedLocalization(settingsStore: settingsStore)

        self.localization = localization
        self.speedTestViewModel = speedTestViewModel ?? SpeedTestViewModel(localization: localization)
        self.settingsStore = settingsStore
        self.launchAtLoginManager = launchAtLoginManager
        self.appUpdater = appUpdater
        self.applicationTerminator = applicationTerminator
        self.automaticTestInterval = settingsStore.automaticTestInterval
        self.automaticallyChecksForUpdates = settingsStore.automaticallyChecksForUpdates
        self.launchAtLoginState = launchAtLoginManager.currentState()
        self.appUpdateStatus = settingsStore.automaticallyChecksForUpdates ? .idle : .automaticChecksDisabled

        rescheduleAutomaticTests()
        scheduleAutomaticUpdateCheck()
    }

    deinit {
        automaticTestingTask?.cancel()
        automaticUpdateCheckTask?.cancel()
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

    public var installedVersionDescription: String {
        localization.strings.updateInstalledVersionDescription(version: appUpdater.installedVersion)
    }

    public var updateStatusTitle: String {
        let strings = localization.strings

        switch appUpdateStatus {
        case .idle:
            return strings.updateStatusIdleTitle
        case .automaticChecksDisabled:
            return strings.updateStatusDisabledTitle
        case .checking:
            return strings.updateStatusCheckingTitle
        case .upToDate:
            return strings.updateStatusUpToDateTitle
        case .available:
            return strings.updateStatusAvailableTitle
        case .downloading:
            return strings.updateStatusDownloadingTitle
        case .installing:
            return strings.updateStatusInstallingTitle
        case .failed:
            return strings.updateStatusFailedTitle
        }
    }

    public var updateStatusDescription: String {
        let strings = localization.strings

        switch appUpdateStatus {
        case .idle:
            return strings.updateIdleDescription(version: appUpdater.installedVersion)
        case .automaticChecksDisabled:
            return strings.updateAutomaticChecksDisabledDescription(version: appUpdater.installedVersion)
        case .checking:
            return strings.updateCheckingButtonTitle
        case .upToDate:
            return strings.updateUpToDateDescription(version: appUpdater.installedVersion)
        case let .available(release):
            return strings.updateAvailableDescription(version: release.version)
        case let .downloading(release):
            return strings.updateDownloadingDescription(version: release.version)
        case let .installing(release):
            return strings.updateInstallingDescription(version: release.version)
        case let .failed(feedback):
            switch feedback {
            case let .localized(error):
                return strings.appUpdateErrorDescription(error)
            case let .raw(message):
                return message
            }
        }
    }

    public var updateLastCheckedDescription: String {
        let strings = localization.strings

        guard let lastUpdateCheckAt else {
            return strings.updateNeverCheckedDescription
        }

        let relative = MetricFormatter.relativeTimestamp(
            lastUpdateCheckAt,
            locale: localization.locale
        ) ?? strings.justNowHint
        return strings.updateLastCheckedDescription(relative: relative)
    }

    public var updateStatusSymbolName: String {
        switch appUpdateStatus {
        case .idle:
            return "arrow.triangle.2.circlepath.circle"
        case .automaticChecksDisabled:
            return "pause.circle.fill"
        case .checking:
            return "arrow.clockwise.circle.fill"
        case .upToDate:
            return "checkmark.circle.fill"
        case .available:
            return "arrow.down.circle.fill"
        case .downloading:
            return "arrow.down.circle.fill"
        case .installing:
            return "shippingbox.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    public var updateStatusTone: UpdateStatusTone {
        switch appUpdateStatus {
        case .idle:
            return .neutral
        case .automaticChecksDisabled:
            return .muted
        case .checking:
            return .informative
        case .upToDate:
            return .success
        case .available, .downloading, .installing:
            return .accent
        case .failed:
            return .error
        }
    }

    public var updateStatusUsesErrorStyle: Bool {
        if case .failed = appUpdateStatus {
            return true
        }

        return false
    }

    public var canCheckForUpdates: Bool {
        switch appUpdateStatus {
        case .checking, .downloading, .installing:
            return false
        default:
            return true
        }
    }

    public var canInstallUpdate: Bool {
        availableUpdate != nil && canCheckForUpdates
    }

    public var shouldShowInstallUpdateButton: Bool {
        availableUpdate != nil
    }

    public var showsUpdateProgressIndicator: Bool {
        switch appUpdateStatus {
        case .checking, .downloading, .installing:
            return true
        default:
            return false
        }
    }

    public var updateCheckButtonTitle: String {
        let strings = localization.strings

        if case .checking = appUpdateStatus {
            return strings.updateCheckingButtonTitle
        }

        return strings.updateCheckButtonTitle
    }

    public var updateInstallButtonTitle: String {
        let strings = localization.strings

        switch appUpdateStatus {
        case .downloading:
            return strings.updateDownloadingButtonTitle
        case .installing:
            return strings.updateInstallingButtonTitle
        default:
            return strings.updateInstallButtonTitle(version: availableUpdate?.version ?? appUpdater.installedVersion)
        }
    }

    public var availableUpdateReleaseURL: URL? {
        availableUpdate?.releaseURL
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

    public func checkForUpdates() {
        guard canCheckForUpdates else {
            return
        }

        automaticUpdateCheckTask?.cancel()

        Task { [weak self] in
            guard let self else {
                return
            }

            await self.performUpdateCheck()
        }
    }

    public func installAvailableUpdate() {
        guard let availableUpdate, canInstallUpdate else {
            return
        }

        appUpdateStatus = .downloading(availableUpdate)

        Task { [weak self] in
            guard let self else {
                return
            }

            do {
                try await self.appUpdater.installUpdate(availableUpdate)
                self.appUpdateStatus = .installing(availableUpdate)
                self.applicationTerminator()
            } catch let error as AppUpdateError {
                self.appUpdateStatus = .failed(.localized(error))
            } catch {
                self.appUpdateStatus = .failed(.raw(error.localizedDescription))
            }
        }
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

    private func scheduleAutomaticUpdateCheck() {
        automaticUpdateCheckTask?.cancel()
        automaticUpdateCheckTask = nil

        guard automaticallyChecksForUpdates else {
            return
        }

        automaticUpdateCheckTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 3_000_000_000)
            } catch {
                return
            }

            guard let self else {
                return
            }

            await self.performUpdateCheck()
        }
    }

    private func performUpdateCheck() async {
        guard canCheckForUpdates else {
            return
        }

        appUpdateStatus = .checking

        do {
            switch try await appUpdater.checkForUpdates() {
            case .upToDate:
                availableUpdate = nil
                appUpdateStatus = .upToDate
            case let .updateAvailable(release):
                availableUpdate = release
                appUpdateStatus = .available(release)
            }
            lastUpdateCheckAt = Date()
        } catch let error as AppUpdateError {
            availableUpdate = nil
            appUpdateStatus = .failed(.localized(error))
            lastUpdateCheckAt = Date()
        } catch {
            availableUpdate = nil
            appUpdateStatus = .failed(.raw(error.localizedDescription))
            lastUpdateCheckAt = Date()
        }
    }
}

public enum UpdateStatusTone: Sendable {
    case neutral
    case muted
    case informative
    case success
    case accent
    case error
}

private enum LaunchAtLoginFeedback: Equatable {
    case localized(LaunchAtLoginError)
    case raw(String)
}

private enum AppUpdateStatus: Equatable {
    case idle
    case automaticChecksDisabled
    case checking
    case upToDate
    case available(AppUpdateRelease)
    case downloading(AppUpdateRelease)
    case installing(AppUpdateRelease)
    case failed(AppUpdateFeedback)
}

private enum AppUpdateFeedback: Equatable {
    case localized(AppUpdateError)
    case raw(String)
}
