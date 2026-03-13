import Foundation
import Observation

@MainActor
@Observable
public final class SpeedLocalization {
    public var appLanguage: AppLanguage {
        didSet {
            guard appLanguage != oldValue else {
                return
            }

            settingsStore.appLanguage = appLanguage
            updateResolvedLanguage()
        }
    }

    public private(set) var resolvedLanguage: SupportedLanguage

    @ObservationIgnored
    private let settingsStore: SpeedSettingsStore

    @ObservationIgnored
    private let preferredLanguagesProvider: @Sendable () -> [String]

    public init(
        settingsStore: SpeedSettingsStore = SpeedSettingsStore(),
        preferredLanguagesProvider: @escaping @Sendable () -> [String] = { Locale.preferredLanguages }
    ) {
        let initialLanguage = settingsStore.appLanguage

        self.settingsStore = settingsStore
        self.preferredLanguagesProvider = preferredLanguagesProvider
        self.appLanguage = initialLanguage
        self.resolvedLanguage = initialLanguage.resolvedLanguage(
            preferredLanguages: preferredLanguagesProvider()
        )
    }

    public var locale: Locale {
        resolvedLanguage.locale
    }

    public var strings: SpeedStrings {
        SpeedStrings(language: resolvedLanguage)
    }

    public func refreshSystemLanguage() {
        guard appLanguage == .system else {
            return
        }

        updateResolvedLanguage()
    }

    private func updateResolvedLanguage() {
        let resolvedLanguage = appLanguage.resolvedLanguage(
            preferredLanguages: preferredLanguagesProvider()
        )

        guard self.resolvedLanguage != resolvedLanguage else {
            return
        }

        self.resolvedLanguage = resolvedLanguage
    }
}

public struct SpeedStrings: Sendable {
    private let catalog: any SpeedStringCatalog

    public init(language: SupportedLanguage) {
        switch language {
        case .english:
            catalog = EnglishSpeedStrings()
        case .german:
            catalog = GermanSpeedStrings()
        }
    }

    public var appName: String { catalog.appName }
    public var settingsTitle: String { catalog.settingsTitle }
    public var settingsSectionLaunchAtLogin: String { catalog.settingsSectionLaunchAtLogin }
    public var launchAtLoginToggleTitle: String { catalog.launchAtLoginToggleTitle }
    public var settingsSectionAutomaticTests: String { catalog.settingsSectionAutomaticTests }
    public var automaticTestIntervalLabel: String { catalog.automaticTestIntervalLabel }
    public var settingsSectionLanguage: String { catalog.settingsSectionLanguage }
    public var languagePickerLabel: String { catalog.languagePickerLabel }
    public var menuBarRunningHelp: String { catalog.menuBarRunningHelp }
    public var menuBarOpenHelp: String { catalog.menuBarOpenHelp }
    public var settingsHelp: String { catalog.settingsHelp }
    public var summaryDownloadLabel: String { catalog.summaryDownloadLabel }
    public var summaryStatusLabel: String { catalog.summaryStatusLabel }
    public var summaryRunningTitle: String { catalog.summaryRunningTitle }
    public var summaryReadyTitle: String { catalog.summaryReadyTitle }
    public var uploadLabel: String { catalog.uploadLabel }
    public var profileLabel: String { catalog.profileLabel }
    public var summaryBadgeLive: String { catalog.summaryBadgeLive }
    public var metricPingTitle: String { catalog.metricPingTitle }
    public var metricPingNote: String { catalog.metricPingNote }
    public var metricResponsivenessTitle: String { catalog.metricResponsivenessTitle }
    public var metricResponsivenessNote: String { catalog.metricResponsivenessNote }
    public var metricNetworkTitle: String { catalog.metricNetworkTitle }
    public var quitButtonTitle: String { catalog.quitButtonTitle }
    public var statusRunning: String { catalog.statusRunning }
    public var statusEmpty: String { catalog.statusEmpty }
    public var actionCancel: String { catalog.actionCancel }
    public var actionStart: String { catalog.actionStart }
    public var actionRetest: String { catalog.actionRetest }
    public var heroRunning: String { catalog.heroRunning }
    public var heroRetry: String { catalog.heroRetry }
    public var heroReady: String { catalog.heroReady }
    public var heroRunningDescription: String { catalog.heroRunningDescription }
    public var heroEmptyDescription: String { catalog.heroEmptyDescription }
    public var qualityReady: String { catalog.qualityReady }
    public var qualityNoMeasurement: String { catalog.qualityNoMeasurement }
    public var interfaceDefaultLabel: String { catalog.interfaceDefaultLabel }
    public var serverDefaultLabel: String { catalog.serverDefaultLabel }
    public var footerDefault: String { catalog.footerDefault }
    public var automaticTestsDisabledDescription: String {
        catalog.automaticTestsDisabledDescription
    }
    public var justNowHint: String { catalog.justNowHint }
    public var laterHint: String { catalog.laterHint }
    public var launchAtLoginEnabledDescription: String {
        catalog.launchAtLoginEnabledDescription
    }
    public var launchAtLoginDisabledDescription: String {
        catalog.launchAtLoginDisabledDescription
    }
    public var launchAtLoginRequiresApprovalDescription: String {
        catalog.launchAtLoginRequiresApprovalDescription
    }

    public func appLanguageOptionTitle(
        _ language: AppLanguage,
        resolvedSystemLanguage: SupportedLanguage
    ) -> String {
        catalog.appLanguageOptionTitle(language, resolvedSystemLanguage: resolvedSystemLanguage)
    }

    public func networkProfileTitle(_ profile: NetworkProfile) -> String {
        catalog.networkProfileTitle(profile)
    }

    public func networkProfileHeadline(_ profile: NetworkProfile) -> String {
        catalog.networkProfileHeadline(profile)
    }

    public func networkProfileDetail(_ profile: NetworkProfile) -> String {
        catalog.networkProfileDetail(profile)
    }

    public func autoTestIntervalTitle(_ interval: AutoTestInterval) -> String {
        catalog.autoTestIntervalTitle(interval)
    }

    public func autoTestIntervalShortTitle(_ interval: AutoTestInterval) -> String {
        catalog.autoTestIntervalShortTitle(interval)
    }

    public func autoTestIntervalDetail(_ interval: AutoTestInterval) -> String {
        catalog.autoTestIntervalDetail(interval)
    }

    public func statusLastMeasured(profileTitle: String, relative: String) -> String {
        catalog.statusLastMeasured(profileTitle: profileTitle, relative: relative)
    }

    public func nextAutomaticTestDescription(relative: String) -> String {
        catalog.nextAutomaticTestDescription(relative: relative)
    }

    public func footerDuration(seconds: Int) -> String {
        catalog.footerDuration(seconds: seconds)
    }

    public func footerLastMeasured(relative: String) -> String {
        catalog.footerLastMeasured(relative: relative)
    }

    public func networkQualityErrorDescription(_ error: NetworkQualityError) -> String {
        catalog.networkQualityErrorDescription(error)
    }

    public func launchAtLoginErrorDescription(_ error: LaunchAtLoginError) -> String {
        catalog.launchAtLoginErrorDescription(error)
    }
}

private protocol SpeedStringCatalog: Sendable {
    var appName: String { get }
    var settingsTitle: String { get }
    var settingsSectionLaunchAtLogin: String { get }
    var launchAtLoginToggleTitle: String { get }
    var settingsSectionAutomaticTests: String { get }
    var automaticTestIntervalLabel: String { get }
    var settingsSectionLanguage: String { get }
    var languagePickerLabel: String { get }
    var menuBarRunningHelp: String { get }
    var menuBarOpenHelp: String { get }
    var settingsHelp: String { get }
    var summaryDownloadLabel: String { get }
    var summaryStatusLabel: String { get }
    var summaryRunningTitle: String { get }
    var summaryReadyTitle: String { get }
    var uploadLabel: String { get }
    var profileLabel: String { get }
    var summaryBadgeLive: String { get }
    var metricPingTitle: String { get }
    var metricPingNote: String { get }
    var metricResponsivenessTitle: String { get }
    var metricResponsivenessNote: String { get }
    var metricNetworkTitle: String { get }
    var quitButtonTitle: String { get }
    var statusRunning: String { get }
    var statusEmpty: String { get }
    var actionCancel: String { get }
    var actionStart: String { get }
    var actionRetest: String { get }
    var heroRunning: String { get }
    var heroRetry: String { get }
    var heroReady: String { get }
    var heroRunningDescription: String { get }
    var heroEmptyDescription: String { get }
    var qualityReady: String { get }
    var qualityNoMeasurement: String { get }
    var interfaceDefaultLabel: String { get }
    var serverDefaultLabel: String { get }
    var footerDefault: String { get }
    var automaticTestsDisabledDescription: String { get }
    var justNowHint: String { get }
    var laterHint: String { get }
    var launchAtLoginEnabledDescription: String { get }
    var launchAtLoginDisabledDescription: String { get }
    var launchAtLoginRequiresApprovalDescription: String { get }

    func appLanguageOptionTitle(
        _ language: AppLanguage,
        resolvedSystemLanguage: SupportedLanguage
    ) -> String
    func networkProfileTitle(_ profile: NetworkProfile) -> String
    func networkProfileHeadline(_ profile: NetworkProfile) -> String
    func networkProfileDetail(_ profile: NetworkProfile) -> String
    func autoTestIntervalTitle(_ interval: AutoTestInterval) -> String
    func autoTestIntervalShortTitle(_ interval: AutoTestInterval) -> String
    func autoTestIntervalDetail(_ interval: AutoTestInterval) -> String
    func statusLastMeasured(profileTitle: String, relative: String) -> String
    func nextAutomaticTestDescription(relative: String) -> String
    func footerDuration(seconds: Int) -> String
    func footerLastMeasured(relative: String) -> String
    func networkQualityErrorDescription(_ error: NetworkQualityError) -> String
    func launchAtLoginErrorDescription(_ error: LaunchAtLoginError) -> String
}

private struct GermanSpeedStrings: SpeedStringCatalog {
    let appName = "Speed"
    let settingsTitle = "Einstellungen"
    let settingsSectionLaunchAtLogin = "Autostart"
    let launchAtLoginToggleTitle = "Speed bei der Anmeldung starten"
    let settingsSectionAutomaticTests = "Automatische Messungen"
    let automaticTestIntervalLabel = "Intervall"
    let settingsSectionLanguage = "Sprache"
    let languagePickerLabel = "App-Sprache"
    let menuBarRunningHelp = "Speedtest läuft"
    let menuBarOpenHelp = "Speed öffnen"
    let settingsHelp = "Einstellungen"
    let summaryDownloadLabel = "Download"
    let summaryStatusLabel = "Status"
    let summaryRunningTitle = "Test läuft"
    let summaryReadyTitle = "Bereit"
    let uploadLabel = "Upload"
    let profileLabel = "Profil"
    let summaryBadgeLive = "Live"
    let metricPingTitle = "Ping"
    let metricPingNote = "Leerlauf"
    let metricResponsivenessTitle = "Reaktion"
    let metricResponsivenessNote = "Apps und Calls"
    let metricNetworkTitle = "Netzwerk"
    let quitButtonTitle = "Beenden"
    let statusRunning = "Download, Upload und Reaktionszeit werden gerade gemessen."
    let statusEmpty = "Ein Klick startet den nativen macOS-Speedtest direkt aus der Menüleiste."
    let actionCancel = "Abbrechen"
    let actionStart = "Speedtest starten"
    let actionRetest = "Erneut messen"
    let heroRunning = "Messung läuft"
    let heroRetry = "Noch ein Versuch?"
    let heroReady = "Bereit für einen schnellen Check"
    let heroRunningDescription = "Das dauert meist 20 bis 30 Sekunden. Du kannst das Menü dabei geöffnet lassen."
    let heroEmptyDescription = "Die App nutzt macOS `networkQuality`, um Download, Upload und Reaktionszeit kompakt anzuzeigen."
    let qualityReady = "Bereit"
    let qualityNoMeasurement = "Noch keine Messung vorhanden."
    let interfaceDefaultLabel = "Aktives Netzwerk"
    let serverDefaultLabel = "Apple networkQuality"
    let footerDefault = "Misst mit dem nativen Apple-Netzwerktest"
    let automaticTestsDisabledDescription = "Automatische Messungen sind aktuell ausgeschaltet."
    let justNowHint = "gerade eben"
    let laterHint = "später"
    let launchAtLoginEnabledDescription = "Speed startet automatisch nach der Anmeldung und bleibt in der Menüleiste verfügbar."
    let launchAtLoginDisabledDescription = "Die App startet derzeit nur manuell."
    let launchAtLoginRequiresApprovalDescription = "macOS wartet noch auf deine Bestätigung in den Systemeinstellungen unter Allgemein > Anmeldeobjekte."

    func appLanguageOptionTitle(
        _ language: AppLanguage,
        resolvedSystemLanguage: SupportedLanguage
    ) -> String {
        switch language {
        case .system:
            "System (\(resolvedSystemLanguage.nativeDisplayName))"
        case .english:
            SupportedLanguage.english.nativeDisplayName
        case .german:
            SupportedLanguage.german.nativeDisplayName
        }
    }

    func networkProfileTitle(_ profile: NetworkProfile) -> String {
        switch profile {
        case .excellent:
            "Sehr flink"
        case .strong:
            "Stark"
        case .stable:
            "Solide"
        case .weak:
            "Träge"
        }
    }

    func networkProfileHeadline(_ profile: NetworkProfile) -> String {
        switch profile {
        case .excellent:
            "Reagiert fast ohne Verzögerung"
        case .strong:
            "Schnell genug für Streaming und Calls"
        case .stable:
            "Im Alltag stabil, aber nicht superspritzig"
        case .weak:
            "Bei interaktiven Aufgaben spürbar langsam"
        }
    }

    func networkProfileDetail(_ profile: NetworkProfile) -> String {
        switch profile {
        case .excellent:
            "Sehr gut für Video-Calls, Cloud-Work und mehrere aktive Geräte."
        case .strong:
            "Fühlt sich flott an und sollte auch unter Last zuverlässig bleiben."
        case .stable:
            "Passt für Alltag, Surfen und Streaming. Unter Last kann es zäher werden."
        case .weak:
            "Downloads laufen oft noch okay, aber Reaktionszeit und Parallelbetrieb leiden."
        }
    }

    func autoTestIntervalTitle(_ interval: AutoTestInterval) -> String {
        switch interval {
        case .off:
            "Aus"
        case .fiveMinutes:
            "Alle 5 Minuten"
        case .fifteenMinutes:
            "Alle 15 Minuten"
        case .thirtyMinutes:
            "Alle 30 Minuten"
        case .oneHour:
            "Stündlich"
        case .twoHours:
            "Alle 2 Stunden"
        }
    }

    func autoTestIntervalShortTitle(_ interval: AutoTestInterval) -> String {
        switch interval {
        case .off:
            "Aus"
        case .fiveMinutes:
            "5 Min"
        case .fifteenMinutes:
            "15 Min"
        case .thirtyMinutes:
            "30 Min"
        case .oneHour:
            "1 Std"
        case .twoHours:
            "2 Std"
        }
    }

    func autoTestIntervalDetail(_ interval: AutoTestInterval) -> String {
        switch interval {
        case .off:
            "Es werden nur manuell gestartete Tests ausgeführt."
        case .fiveMinutes:
            "Ideal für kurze Checks während aktiver Netzwerkprobleme."
        case .fifteenMinutes:
            "Ein guter Mittelweg für regelmäßige Messungen."
        case .thirtyMinutes:
            "Sinnvoll für gelegentliche Hintergrundmessungen."
        case .oneHour:
            "Zurückhaltend und angenehm für langfristiges Monitoring."
        case .twoHours:
            "Sehr sparsam, wenn nur grobe Veränderungen wichtig sind."
        }
    }

    func statusLastMeasured(profileTitle: String, relative: String) -> String {
        "\(profileTitle) • zuletzt \(relative)"
    }

    func nextAutomaticTestDescription(relative: String) -> String {
        "Nächste automatische Messung \(relative)."
    }

    func footerDuration(seconds: Int) -> String {
        "Messdauer bisher: \(seconds)s"
    }

    func footerLastMeasured(relative: String) -> String {
        "Zuletzt gemessen \(relative)"
    }

    func networkQualityErrorDescription(_ error: NetworkQualityError) -> String {
        switch error {
        case .alreadyRunning:
            return "Es läuft bereits ein Speedtest."
        case .commandUnavailable:
            return "Der integrierte macOS-Speedtest ist auf diesem System nicht verfügbar."
        case .noOutput:
            return "Der Speedtest hat keine auswertbaren Daten geliefert."
        case .invalidOutput:
            return "Die Ausgabe des Speedtests konnte nicht gelesen werden."
        case .cancelled:
            return "Der Speedtest wurde abgebrochen."
        case let .executionFailed(message, status):
            if let message, !message.isEmpty {
                return message
            }

            if let status {
                return "Der Speedtest wurde mit Status \(status) beendet."
            }

            return "Der Speedtest konnte nicht abgeschlossen werden."
        }
    }

    func launchAtLoginErrorDescription(_ error: LaunchAtLoginError) -> String {
        switch error {
        case .requiresBundledApp:
            return "Autostart funktioniert in dieser Entwicklungsansicht noch nicht. Bitte nutze die gebaute .app."
        case let .registrationFailed(message):
            if let message, !message.isEmpty {
                return message
            }

            return "Autostart konnte nicht aktualisiert werden."
        }
    }
}

private struct EnglishSpeedStrings: SpeedStringCatalog {
    let appName = "Speed"
    let settingsTitle = "Settings"
    let settingsSectionLaunchAtLogin = "Launch at login"
    let launchAtLoginToggleTitle = "Launch Speed when logging in"
    let settingsSectionAutomaticTests = "Automatic tests"
    let automaticTestIntervalLabel = "Interval"
    let settingsSectionLanguage = "Language"
    let languagePickerLabel = "App language"
    let menuBarRunningHelp = "Speed test in progress"
    let menuBarOpenHelp = "Open Speed"
    let settingsHelp = "Settings"
    let summaryDownloadLabel = "Download"
    let summaryStatusLabel = "Status"
    let summaryRunningTitle = "Testing"
    let summaryReadyTitle = "Ready"
    let uploadLabel = "Upload"
    let profileLabel = "Profile"
    let summaryBadgeLive = "Live"
    let metricPingTitle = "Ping"
    let metricPingNote = "Idle"
    let metricResponsivenessTitle = "Responsiveness"
    let metricResponsivenessNote = "Apps and calls"
    let metricNetworkTitle = "Network"
    let quitButtonTitle = "Quit"
    let statusRunning = "Download, upload, and responsiveness are being measured right now."
    let statusEmpty = "One click starts the native macOS speed test right from the menu bar."
    let actionCancel = "Cancel"
    let actionStart = "Start speed test"
    let actionRetest = "Run again"
    let heroRunning = "Test in progress"
    let heroRetry = "Try again?"
    let heroReady = "Ready for a quick check"
    let heroRunningDescription = "This usually takes 20 to 30 seconds. You can keep the menu open while it runs."
    let heroEmptyDescription = "The app uses macOS `networkQuality` to show download, upload, and responsiveness at a glance."
    let qualityReady = "Ready"
    let qualityNoMeasurement = "No measurement yet."
    let interfaceDefaultLabel = "Active network"
    let serverDefaultLabel = "Apple networkQuality"
    let footerDefault = "Measured with Apple's native network test"
    let automaticTestsDisabledDescription = "Automatic tests are currently turned off."
    let justNowHint = "just now"
    let laterHint = "later"
    let launchAtLoginEnabledDescription = "Speed launches automatically after login and stays available in the menu bar."
    let launchAtLoginDisabledDescription = "The app currently starts only when you open it manually."
    let launchAtLoginRequiresApprovalDescription = "macOS is still waiting for your confirmation in System Settings under General > Login Items."

    func appLanguageOptionTitle(
        _ language: AppLanguage,
        resolvedSystemLanguage: SupportedLanguage
    ) -> String {
        switch language {
        case .system:
            "System (\(resolvedSystemLanguage.nativeDisplayName))"
        case .english:
            SupportedLanguage.english.nativeDisplayName
        case .german:
            SupportedLanguage.german.nativeDisplayName
        }
    }

    func networkProfileTitle(_ profile: NetworkProfile) -> String {
        switch profile {
        case .excellent:
            "Very fast"
        case .strong:
            "Strong"
        case .stable:
            "Stable"
        case .weak:
            "Sluggish"
        }
    }

    func networkProfileHeadline(_ profile: NetworkProfile) -> String {
        switch profile {
        case .excellent:
            "Almost instant response"
        case .strong:
            "Fast enough for streaming and calls"
        case .stable:
            "Steady day to day, but not ultra snappy"
        case .weak:
            "Noticeably slow for interactive tasks"
        }
    }

    func networkProfileDetail(_ profile: NetworkProfile) -> String {
        switch profile {
        case .excellent:
            "Great for video calls, cloud work, and several active devices."
        case .strong:
            "Feels snappy and should stay reliable even under load."
        case .stable:
            "Good for everyday browsing and streaming. It can feel slower under heavy load."
        case .weak:
            "Downloads may still be okay, but latency and multitasking tend to suffer."
        }
    }

    func autoTestIntervalTitle(_ interval: AutoTestInterval) -> String {
        switch interval {
        case .off:
            "Off"
        case .fiveMinutes:
            "Every 5 minutes"
        case .fifteenMinutes:
            "Every 15 minutes"
        case .thirtyMinutes:
            "Every 30 minutes"
        case .oneHour:
            "Hourly"
        case .twoHours:
            "Every 2 hours"
        }
    }

    func autoTestIntervalShortTitle(_ interval: AutoTestInterval) -> String {
        switch interval {
        case .off:
            "Off"
        case .fiveMinutes:
            "5 min"
        case .fifteenMinutes:
            "15 min"
        case .thirtyMinutes:
            "30 min"
        case .oneHour:
            "1 hr"
        case .twoHours:
            "2 hr"
        }
    }

    func autoTestIntervalDetail(_ interval: AutoTestInterval) -> String {
        switch interval {
        case .off:
            "Only manually started tests will run."
        case .fiveMinutes:
            "Ideal for short checks while actively troubleshooting network issues."
        case .fifteenMinutes:
            "A good middle ground for regular measurements."
        case .thirtyMinutes:
            "Useful for occasional background measurements."
        case .oneHour:
            "A restrained option that works well for long-term monitoring."
        case .twoHours:
            "Very lightweight when only broad changes matter."
        }
    }

    func statusLastMeasured(profileTitle: String, relative: String) -> String {
        "\(profileTitle) • last checked \(relative)"
    }

    func nextAutomaticTestDescription(relative: String) -> String {
        "Next automatic test \(relative)."
    }

    func footerDuration(seconds: Int) -> String {
        "Elapsed: \(seconds)s"
    }

    func footerLastMeasured(relative: String) -> String {
        "Last checked \(relative)"
    }

    func networkQualityErrorDescription(_ error: NetworkQualityError) -> String {
        switch error {
        case .alreadyRunning:
            return "A speed test is already running."
        case .commandUnavailable:
            return "The built-in macOS speed test is not available on this system."
        case .noOutput:
            return "The speed test did not return any usable data."
        case .invalidOutput:
            return "The speed test output could not be read."
        case .cancelled:
            return "The speed test was cancelled."
        case let .executionFailed(message, status):
            if let message, !message.isEmpty {
                return message
            }

            if let status {
                return "The speed test exited with status \(status)."
            }

            return "The speed test could not be completed."
        }
    }

    func launchAtLoginErrorDescription(_ error: LaunchAtLoginError) -> String {
        switch error {
        case .requiresBundledApp:
            return "Launch at login is not available in this development build yet. Please use the bundled .app."
        case let .registrationFailed(message):
            if let message, !message.isEmpty {
                return message
            }

            return "Launch at login could not be updated."
        }
    }
}
