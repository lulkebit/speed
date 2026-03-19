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

    public var systemLanguage: SupportedLanguage {
        AppLanguage.system.resolvedLanguage(preferredLanguages: preferredLanguagesProvider())
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
    public var automaticTestOnNetworkChangeTitle: String {
        catalog.automaticTestOnNetworkChangeTitle
    }
    public var automaticTestOnNetworkChangeDescription: String {
        catalog.automaticTestOnNetworkChangeDescription
    }
    public var settingsSectionMenuBar: String { catalog.settingsSectionMenuBar }
    public var menuBarDisplayModeLabel: String { catalog.menuBarDisplayModeLabel }
    public var menuBarPreviewLabel: String { catalog.menuBarPreviewLabel }
    public var settingsSectionHistory: String { catalog.settingsSectionHistory }
    public var historyRangeLabel: String { catalog.historyRangeLabel }
    public var historyEmptyTitle: String { catalog.historyEmptyTitle }
    public var historyEmptyDescription: String { catalog.historyEmptyDescription }
    public var historyChartThroughputTitle: String { catalog.historyChartThroughputTitle }
    public var historyChartLatencyTitle: String { catalog.historyChartLatencyTitle }
    public var historyRecentMeasurementsTitle: String { catalog.historyRecentMeasurementsTitle }
    public var historyLegendDownload: String { catalog.historyLegendDownload }
    public var historyLegendUpload: String { catalog.historyLegendUpload }
    public var historyLegendLatency: String { catalog.historyLegendLatency }
    public var historyLegendResponsiveness: String { catalog.historyLegendResponsiveness }
    public var historyLegendIncidents: String { catalog.historyLegendIncidents }
    public var historyIssueDurationLabel: String { catalog.historyIssueDurationLabel }
    public var historyIssueNetworkStatusLabel: String { catalog.historyIssueNetworkStatusLabel }
    public var historyIssueInterfacesLabel: String { catalog.historyIssueInterfacesLabel }
    public var historyIssueDetailsLabel: String { catalog.historyIssueDetailsLabel }
    public var historyIssueCodeLabel: String { catalog.historyIssueCodeLabel }
    public var historyTooltipInterfaceLabel: String { catalog.historyTooltipInterfaceLabel }
    public var historyTooltipServerLabel: String { catalog.historyTooltipServerLabel }
    public var settingsSectionUpdates: String { catalog.settingsSectionUpdates }
    public var updateAutomaticChecksToggleTitle: String { catalog.updateAutomaticChecksToggleTitle }
    public var updateCheckButtonTitle: String { catalog.updateCheckButtonTitle }
    public var updateCheckingButtonTitle: String { catalog.updateCheckingButtonTitle }
    public var updateDownloadingButtonTitle: String { catalog.updateDownloadingButtonTitle }
    public var updateInstallingButtonTitle: String { catalog.updateInstallingButtonTitle }
    public var updateReleaseNotesTitle: String { catalog.updateReleaseNotesTitle }
    public var updateStatusIdleTitle: String { catalog.updateStatusIdleTitle }
    public var updateStatusDisabledTitle: String { catalog.updateStatusDisabledTitle }
    public var updateStatusCheckingTitle: String { catalog.updateStatusCheckingTitle }
    public var updateStatusUpToDateTitle: String { catalog.updateStatusUpToDateTitle }
    public var updateStatusAvailableTitle: String { catalog.updateStatusAvailableTitle }
    public var updateStatusDownloadingTitle: String { catalog.updateStatusDownloadingTitle }
    public var updateStatusInstallingTitle: String { catalog.updateStatusInstallingTitle }
    public var updateStatusFailedTitle: String { catalog.updateStatusFailedTitle }
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
    public var metricPingHelp: String { catalog.metricPingHelp }
    public var metricResponsivenessTitle: String { catalog.metricResponsivenessTitle }
    public var metricResponsivenessNote: String { catalog.metricResponsivenessNote }
    public var metricResponsivenessHelp: String { catalog.metricResponsivenessHelp }
    public var metricNetworkTitle: String { catalog.metricNetworkTitle }
    public var metricNetworkHelp: String { catalog.metricNetworkHelp }
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

    public func networkIssueTitle(_ kind: NetworkIssueKind) -> String {
        catalog.networkIssueTitle(kind)
    }

    public func networkPathStatusTitle(_ pathStatus: String) -> String {
        catalog.networkPathStatusTitle(pathStatus)
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

    public func menuBarDisplayModeTitle(_ displayMode: MenuBarDisplayMode) -> String {
        catalog.menuBarDisplayModeTitle(displayMode)
    }

    public func historyTimeRangeTitle(_ range: HistoryTimeRange) -> String {
        catalog.historyTimeRangeTitle(range)
    }

    public func historyMeasurementsDescription(count: Int) -> String {
        catalog.historyMeasurementsDescription(count: count)
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

    public func updateIdleDescription(version: String) -> String {
        catalog.updateIdleDescription(version: version)
    }

    public func updateInstalledVersionDescription(version: String) -> String {
        catalog.updateInstalledVersionDescription(version: version)
    }

    public func updateLastCheckedDescription(relative: String) -> String {
        catalog.updateLastCheckedDescription(relative: relative)
    }

    public var updateNeverCheckedDescription: String {
        catalog.updateNeverCheckedDescription
    }

    public func updateAutomaticChecksDisabledDescription(version: String) -> String {
        catalog.updateAutomaticChecksDisabledDescription(version: version)
    }

    public func updateUpToDateDescription(version: String) -> String {
        catalog.updateUpToDateDescription(version: version)
    }

    public func updateAvailableDescription(version: String) -> String {
        catalog.updateAvailableDescription(version: version)
    }

    public func updateDownloadingDescription(version: String) -> String {
        catalog.updateDownloadingDescription(version: version)
    }

    public func updateInstallingDescription(version: String) -> String {
        catalog.updateInstallingDescription(version: version)
    }

    public func updateInstallButtonTitle(version: String) -> String {
        catalog.updateInstallButtonTitle(version: version)
    }

    public func appUpdateErrorDescription(_ error: AppUpdateError) -> String {
        catalog.appUpdateErrorDescription(error)
    }
}

private protocol SpeedStringCatalog: Sendable {
    var appName: String { get }
    var settingsTitle: String { get }
    var settingsSectionLaunchAtLogin: String { get }
    var launchAtLoginToggleTitle: String { get }
    var settingsSectionAutomaticTests: String { get }
    var automaticTestIntervalLabel: String { get }
    var automaticTestOnNetworkChangeTitle: String { get }
    var automaticTestOnNetworkChangeDescription: String { get }
    var settingsSectionMenuBar: String { get }
    var menuBarDisplayModeLabel: String { get }
    var menuBarPreviewLabel: String { get }
    var settingsSectionHistory: String { get }
    var historyRangeLabel: String { get }
    var historyEmptyTitle: String { get }
    var historyEmptyDescription: String { get }
    var historyChartThroughputTitle: String { get }
    var historyChartLatencyTitle: String { get }
    var historyRecentMeasurementsTitle: String { get }
    var historyLegendDownload: String { get }
    var historyLegendUpload: String { get }
    var historyLegendLatency: String { get }
    var historyLegendResponsiveness: String { get }
    var historyLegendIncidents: String { get }
    var historyIssueDurationLabel: String { get }
    var historyIssueNetworkStatusLabel: String { get }
    var historyIssueInterfacesLabel: String { get }
    var historyIssueDetailsLabel: String { get }
    var historyIssueCodeLabel: String { get }
    var historyTooltipInterfaceLabel: String { get }
    var historyTooltipServerLabel: String { get }
    var settingsSectionUpdates: String { get }
    var updateAutomaticChecksToggleTitle: String { get }
    var updateCheckButtonTitle: String { get }
    var updateCheckingButtonTitle: String { get }
    var updateDownloadingButtonTitle: String { get }
    var updateInstallingButtonTitle: String { get }
    var updateReleaseNotesTitle: String { get }
    var updateStatusIdleTitle: String { get }
    var updateStatusDisabledTitle: String { get }
    var updateStatusCheckingTitle: String { get }
    var updateStatusUpToDateTitle: String { get }
    var updateStatusAvailableTitle: String { get }
    var updateStatusDownloadingTitle: String { get }
    var updateStatusInstallingTitle: String { get }
    var updateStatusFailedTitle: String { get }
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
    var metricPingHelp: String { get }
    var metricResponsivenessTitle: String { get }
    var metricResponsivenessNote: String { get }
    var metricResponsivenessHelp: String { get }
    var metricNetworkTitle: String { get }
    var metricNetworkHelp: String { get }
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
    func networkIssueTitle(_ kind: NetworkIssueKind) -> String
    func networkPathStatusTitle(_ pathStatus: String) -> String
    func autoTestIntervalTitle(_ interval: AutoTestInterval) -> String
    func autoTestIntervalShortTitle(_ interval: AutoTestInterval) -> String
    func autoTestIntervalDetail(_ interval: AutoTestInterval) -> String
    func menuBarDisplayModeTitle(_ displayMode: MenuBarDisplayMode) -> String
    func historyTimeRangeTitle(_ range: HistoryTimeRange) -> String
    func historyMeasurementsDescription(count: Int) -> String
    func statusLastMeasured(profileTitle: String, relative: String) -> String
    func nextAutomaticTestDescription(relative: String) -> String
    func footerDuration(seconds: Int) -> String
    func footerLastMeasured(relative: String) -> String
    func networkQualityErrorDescription(_ error: NetworkQualityError) -> String
    func launchAtLoginErrorDescription(_ error: LaunchAtLoginError) -> String
    func updateIdleDescription(version: String) -> String
    func updateInstalledVersionDescription(version: String) -> String
    func updateLastCheckedDescription(relative: String) -> String
    var updateNeverCheckedDescription: String { get }
    func updateAutomaticChecksDisabledDescription(version: String) -> String
    func updateUpToDateDescription(version: String) -> String
    func updateAvailableDescription(version: String) -> String
    func updateDownloadingDescription(version: String) -> String
    func updateInstallingDescription(version: String) -> String
    func updateInstallButtonTitle(version: String) -> String
    func appUpdateErrorDescription(_ error: AppUpdateError) -> String
}

private struct GermanSpeedStrings: SpeedStringCatalog {
    let appName = "Speed"
    let settingsTitle = "Einstellungen"
    let settingsSectionLaunchAtLogin = "Autostart"
    let launchAtLoginToggleTitle = "Speed bei der Anmeldung starten"
    let settingsSectionAutomaticTests = "Automatische Messungen"
    let automaticTestIntervalLabel = "Intervall"
    let automaticTestOnNetworkChangeTitle = "Bei Netzwerkwechsel automatisch neu messen"
    let automaticTestOnNetworkChangeDescription = "Startet nach einem erkannten Wechsel des aktiven Netzwerks automatisch einen neuen Speedtest."
    let settingsSectionMenuBar = "Menüleiste"
    let menuBarDisplayModeLabel = "Anzeige in der Menüleiste"
    let menuBarPreviewLabel = "Vorschau"
    let settingsSectionHistory = "Verlauf"
    let historyRangeLabel = "Zeitraum"
    let historyEmptyTitle = "Noch kein Verlauf vorhanden"
    let historyEmptyDescription = "Sobald Messungen oder Verbindungsprobleme vorliegen, erscheinen hier Diagramme und Marker für Download, Upload, Latenz sowie Timeouts oder Ausfälle."
    let historyChartThroughputTitle = "Durchsatz"
    let historyChartLatencyTitle = "Latenz"
    let historyRecentMeasurementsTitle = "Letzte Ereignisse"
    let historyLegendDownload = "Download"
    let historyLegendUpload = "Upload"
    let historyLegendLatency = "Ping"
    let historyLegendResponsiveness = "Reaktion"
    let historyLegendIncidents = "Vorfälle"
    let historyIssueDurationLabel = "Dauer"
    let historyIssueNetworkStatusLabel = "Netzstatus"
    let historyIssueInterfacesLabel = "Schnittstellen"
    let historyIssueDetailsLabel = "Hinweis"
    let historyIssueCodeLabel = "Code"
    let historyTooltipInterfaceLabel = "Schnittstelle"
    let historyTooltipServerLabel = "Server"
    let settingsSectionUpdates = "Updates"
    let updateAutomaticChecksToggleTitle = "Automatisch nach Updates suchen"
    let updateCheckButtonTitle = "Jetzt nach Updates suchen"
    let updateCheckingButtonTitle = "Suche nach Updates..."
    let updateDownloadingButtonTitle = "Update wird geladen..."
    let updateInstallingButtonTitle = "Update wird installiert..."
    let updateReleaseNotesTitle = "Release in GitHub ansehen"
    let updateStatusIdleTitle = "Bereit"
    let updateStatusDisabledTitle = "Update-Suche pausiert"
    let updateStatusCheckingTitle = "Suche läuft"
    let updateStatusUpToDateTitle = "Alles aktuell"
    let updateStatusAvailableTitle = "Update verfügbar"
    let updateStatusDownloadingTitle = "Download läuft"
    let updateStatusInstallingTitle = "Installation läuft"
    let updateStatusFailedTitle = "Update fehlgeschlagen"
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
    let metricPingHelp = "Leerlauf-Latenz: Wie lange eine kleine Anfrage ohne Last bis zur Antwort braucht. Niedriger ist besser."
    let metricResponsivenessTitle = "Reaktion"
    let metricResponsivenessNote = "Apps und Calls"
    let metricResponsivenessHelp = "Reaktionszeit unter Last: Wie schnell Apps, Calls und Webseiten antworten, wenn die Leitung gerade beschäftigt ist. Niedriger ist besser."
    let metricNetworkTitle = "Netzwerk"
    let metricNetworkHelp = "Rechts steht die aktive macOS-Schnittstelle wie en0. Darunter siehst du den Server, den der Test verwendet."
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

    func networkIssueTitle(_ kind: NetworkIssueKind) -> String {
        switch kind {
        case .timeout:
            return "Timeout"
        case .internetUnavailable:
            return "Internetausfall"
        case .failure:
            return "Fehlgeschlagener Test"
        }
    }

    func networkPathStatusTitle(_ pathStatus: String) -> String {
        switch pathStatus {
        case "satisfied":
            return "Verbunden"
        case "requiresConnection":
            return "Verbindung erforderlich"
        case "unsatisfied":
            return "Offline"
        default:
            return "Unbekannt"
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

    func menuBarDisplayModeTitle(_ displayMode: MenuBarDisplayMode) -> String {
        switch displayMode {
        case .icon:
            "Nur Symbol"
        case .download:
            "Downloadwert"
        case .latency:
            "Ping"
        case .downloadAndUpload:
            "Download und Upload"
        }
    }

    func historyTimeRangeTitle(_ range: HistoryTimeRange) -> String {
        switch range {
        case .hour:
            "1 Std."
        case .day:
            "24 Std."
        case .week:
            "7 Tage"
        case .month:
            "30 Tage"
        }
    }

    func historyMeasurementsDescription(count: Int) -> String {
        "Zeigt \(count) Einträge im ausgewählten Zeitraum."
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
        case .timedOut:
            return "Der Speedtest hat das Zeitlimit erreicht und wurde als Timeout protokolliert."
        case .internetUnavailable:
            return "Während des Tests war keine Internetverbindung verfügbar."
        case let .executionFailed(context):
            if let message = context.message, !message.isEmpty {
                return message
            }

            if let diagnostic = executionFailureDiagnostic(for: context) {
                return "Der Speedtest konnte nicht abgeschlossen werden (\(diagnostic))."
            }

            return "Der Speedtest konnte nicht abgeschlossen werden."
        }
    }

    private func executionFailureDiagnostic(for context: NetworkQualityFailureContext) -> String? {
        if let errorDomain = context.errorDomain, let errorCode = context.errorCode {
            return "\(errorDomain) \(errorCode)"
        }

        if let status = context.status {
            return "Status \(status)"
        }

        return nil
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

    func updateIdleDescription(version _: String) -> String {
        "Automatische Update-Prüfungen sind aktiviert."
    }

    func updateInstalledVersionDescription(version: String) -> String {
        "Installierte Version: \(version)"
    }

    func updateLastCheckedDescription(relative: String) -> String {
        "Zuletzt geprüft \(relative)"
    }

    var updateNeverCheckedDescription: String {
        "Noch keine Update-Prüfung durchgeführt."
    }

    func updateAutomaticChecksDisabledDescription(version _: String) -> String {
        "Automatische Update-Prüfungen sind ausgeschaltet."
    }

    func updateUpToDateDescription(version _: String) -> String {
        "Es ist kein neues Update verfügbar."
    }

    func updateAvailableDescription(version: String) -> String {
        "Version \(version) ist verfügbar und kann direkt installiert werden."
    }

    func updateDownloadingDescription(version: String) -> String {
        "Version \(version) wird heruntergeladen."
    }

    func updateInstallingDescription(version: String) -> String {
        "Version \(version) wird installiert. Speed startet danach automatisch neu."
    }

    func updateInstallButtonTitle(version: String) -> String {
        "Version \(version) installieren"
    }

    func appUpdateErrorDescription(_ error: AppUpdateError) -> String {
        switch error {
        case .invalidServerResponse:
            return "Die Antwort von GitHub konnte nicht verarbeitet werden."
        case let .unexpectedStatusCode(statusCode):
            return "GitHub hat die Update-Anfrage mit Status \(statusCode) beantwortet."
        case .releaseVersionMissing:
            return "Im neuesten GitHub-Release wurde keine gültige Versionsnummer gefunden."
        case .latestReleaseMissingAsset:
            return "Im neuesten GitHub-Release wurde kein installierbares macOS-ZIP gefunden."
        case .requiresBundledApp:
            return "Updates können nur aus der gebauten .app installiert werden."
        case .extractionFailed:
            return "Das heruntergeladene Update konnte nicht entpackt werden."
        case .extractedAppNotFound:
            return "Das heruntergeladene Update enthält keine macOS-App."
        case let .installerLaunchFailed(message):
            if let message, !message.isEmpty {
                return message
            }

            return "Der Update-Installer konnte nicht gestartet werden."
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
    let automaticTestOnNetworkChangeTitle = "Run a fresh test after network changes"
    let automaticTestOnNetworkChangeDescription = "Automatically starts a new speed test after macOS reports that the active network changed."
    let settingsSectionMenuBar = "Menu bar"
    let menuBarDisplayModeLabel = "Menu bar detail"
    let menuBarPreviewLabel = "Preview"
    let settingsSectionHistory = "History"
    let historyRangeLabel = "Range"
    let historyEmptyTitle = "No history yet"
    let historyEmptyDescription = "Charts will appear here as soon as measurements or connection issues are available, including markers for timeouts and outages."
    let historyChartThroughputTitle = "Throughput"
    let historyChartLatencyTitle = "Latency"
    let historyRecentMeasurementsTitle = "Recent activity"
    let historyLegendDownload = "Download"
    let historyLegendUpload = "Upload"
    let historyLegendLatency = "Ping"
    let historyLegendResponsiveness = "Responsiveness"
    let historyLegendIncidents = "Incidents"
    let historyIssueDurationLabel = "Duration"
    let historyIssueNetworkStatusLabel = "Path status"
    let historyIssueInterfacesLabel = "Interfaces"
    let historyIssueDetailsLabel = "Details"
    let historyIssueCodeLabel = "Code"
    let historyTooltipInterfaceLabel = "Interface"
    let historyTooltipServerLabel = "Server"
    let settingsSectionUpdates = "Updates"
    let updateAutomaticChecksToggleTitle = "Automatically check for updates"
    let updateCheckButtonTitle = "Check for updates now"
    let updateCheckingButtonTitle = "Checking for updates..."
    let updateDownloadingButtonTitle = "Downloading update..."
    let updateInstallingButtonTitle = "Installing update..."
    let updateReleaseNotesTitle = "View release on GitHub"
    let updateStatusIdleTitle = "Ready"
    let updateStatusDisabledTitle = "Update checks paused"
    let updateStatusCheckingTitle = "Checking now"
    let updateStatusUpToDateTitle = "Up to date"
    let updateStatusAvailableTitle = "Update available"
    let updateStatusDownloadingTitle = "Downloading"
    let updateStatusInstallingTitle = "Installing"
    let updateStatusFailedTitle = "Update failed"
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
    let metricPingHelp = "Idle latency: how long a small request takes when the connection is not busy. Lower is better."
    let metricResponsivenessTitle = "Responsiveness"
    let metricResponsivenessNote = "Apps and calls"
    let metricResponsivenessHelp = "Latency under load: how quickly apps, calls, and pages respond while the connection is busy. Lower is better."
    let metricNetworkTitle = "Network"
    let metricNetworkHelp = "Shows the active macOS network interface on the right, such as en0. The line below shows the server used for the test."
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

    func networkIssueTitle(_ kind: NetworkIssueKind) -> String {
        switch kind {
        case .timeout:
            return "Timeout"
        case .internetUnavailable:
            return "Internet outage"
        case .failure:
            return "Failed test"
        }
    }

    func networkPathStatusTitle(_ pathStatus: String) -> String {
        switch pathStatus {
        case "satisfied":
            return "Connected"
        case "requiresConnection":
            return "Connection required"
        case "unsatisfied":
            return "Offline"
        default:
            return "Unknown"
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

    func menuBarDisplayModeTitle(_ displayMode: MenuBarDisplayMode) -> String {
        switch displayMode {
        case .icon:
            "Icon only"
        case .download:
            "Download speed"
        case .latency:
            "Ping"
        case .downloadAndUpload:
            "Download and upload"
        }
    }

    func historyTimeRangeTitle(_ range: HistoryTimeRange) -> String {
        switch range {
        case .hour:
            "1h"
        case .day:
            "24h"
        case .week:
            "7 days"
        case .month:
            "30 days"
        }
    }

    func historyMeasurementsDescription(count: Int) -> String {
        "Showing \(count) entries for the selected range."
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
        case .timedOut:
            return "The speed test hit the time limit and was logged as a timeout."
        case .internetUnavailable:
            return "The internet connection was unavailable during the speed test."
        case let .executionFailed(context):
            if let message = context.message, !message.isEmpty {
                return message
            }

            if let diagnostic = executionFailureDiagnostic(for: context) {
                return "The speed test could not be completed (\(diagnostic))."
            }

            return "The speed test could not be completed."
        }
    }

    private func executionFailureDiagnostic(for context: NetworkQualityFailureContext) -> String? {
        if let errorDomain = context.errorDomain, let errorCode = context.errorCode {
            return "\(errorDomain) \(errorCode)"
        }

        if let status = context.status {
            return "status \(status)"
        }

        return nil
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

    func updateIdleDescription(version _: String) -> String {
        "Automatic update checks are enabled."
    }

    func updateInstalledVersionDescription(version: String) -> String {
        "Installed version: \(version)"
    }

    func updateLastCheckedDescription(relative: String) -> String {
        "Last checked \(relative)"
    }

    var updateNeverCheckedDescription: String {
        "No update check has been run yet."
    }

    func updateAutomaticChecksDisabledDescription(version _: String) -> String {
        "Automatic update checks are turned off."
    }

    func updateUpToDateDescription(version _: String) -> String {
        "No newer update is available."
    }

    func updateAvailableDescription(version: String) -> String {
        "Version \(version) is available and ready to install."
    }

    func updateDownloadingDescription(version: String) -> String {
        "Downloading version \(version)."
    }

    func updateInstallingDescription(version: String) -> String {
        "Installing version \(version). Speed will relaunch automatically."
    }

    func updateInstallButtonTitle(version: String) -> String {
        "Install version \(version)"
    }

    func appUpdateErrorDescription(_ error: AppUpdateError) -> String {
        switch error {
        case .invalidServerResponse:
            return "GitHub returned an unreadable update response."
        case let .unexpectedStatusCode(statusCode):
            return "GitHub responded to the update request with status \(statusCode)."
        case .releaseVersionMissing:
            return "The latest GitHub release does not contain a valid version."
        case .latestReleaseMissingAsset:
            return "The latest GitHub release does not contain an installable macOS zip."
        case .requiresBundledApp:
            return "Updates can only be installed from the bundled .app."
        case .extractionFailed:
            return "The downloaded update archive could not be extracted."
        case .extractedAppNotFound:
            return "The downloaded update does not contain a macOS app."
        case let .installerLaunchFailed(message):
            if let message, !message.isEmpty {
                return message
            }

            return "The update installer could not be started."
        }
    }
}
