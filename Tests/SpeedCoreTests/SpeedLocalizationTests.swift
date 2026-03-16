import XCTest
@testable import SpeedCore

@MainActor
final class SpeedLocalizationTests: XCTestCase {
    func testSystemLanguagePrefersGermanWhenMacOSIsGerman() {
        let suiteName = "SpeedLocalizationTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Expected dedicated user defaults suite.")
        }

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let settingsStore = SpeedSettingsStore(userDefaults: userDefaults)
        let localization = SpeedLocalization(
            settingsStore: settingsStore,
            preferredLanguagesProvider: { ["de-DE"] }
        )

        XCTAssertEqual(localization.appLanguage, .system)
        XCTAssertEqual(localization.resolvedLanguage, .german)
        XCTAssertEqual(localization.strings.settingsTitle, "Einstellungen")
    }

    func testUnsupportedSystemLanguageFallsBackToEnglish() {
        let suiteName = "SpeedLocalizationTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Expected dedicated user defaults suite.")
        }

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let settingsStore = SpeedSettingsStore(userDefaults: userDefaults)
        let localization = SpeedLocalization(
            settingsStore: settingsStore,
            preferredLanguagesProvider: { ["fr-FR"] }
        )

        XCTAssertEqual(localization.resolvedLanguage, .english)
        XCTAssertEqual(localization.strings.settingsTitle, "Settings")
    }

    func testExplicitLanguageOverridesSystemPreference() {
        let suiteName = "SpeedLocalizationTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Expected dedicated user defaults suite.")
        }

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let settingsStore = SpeedSettingsStore(userDefaults: userDefaults)
        settingsStore.appLanguage = .english

        let localization = SpeedLocalization(
            settingsStore: settingsStore,
            preferredLanguagesProvider: { ["de-DE"] }
        )

        XCTAssertEqual(localization.appLanguage, .english)
        XCTAssertEqual(localization.resolvedLanguage, .english)
    }

    func testSystemLanguageRemainsIndependentFromExplicitAppLanguage() {
        let suiteName = "SpeedLocalizationTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Expected dedicated user defaults suite.")
        }

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let settingsStore = SpeedSettingsStore(userDefaults: userDefaults)
        settingsStore.appLanguage = .english

        let localization = SpeedLocalization(
            settingsStore: settingsStore,
            preferredLanguagesProvider: { ["de-DE"] }
        )

        XCTAssertEqual(localization.resolvedLanguage, .english)
        XCTAssertEqual(localization.systemLanguage, .german)
    }

    func testRefreshSystemLanguageUpdatesResolvedLanguage() {
        let suiteName = "SpeedLocalizationTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Expected dedicated user defaults suite.")
        }

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let settingsStore = SpeedSettingsStore(userDefaults: userDefaults)
        let preferredLanguagesBox = PreferredLanguagesBox(["de-DE"])
        let localization = SpeedLocalization(
            settingsStore: settingsStore,
            preferredLanguagesProvider: { preferredLanguagesBox.value }
        )

        XCTAssertEqual(localization.resolvedLanguage, .german)

        preferredLanguagesBox.value = ["en-US"]
        localization.refreshSystemLanguage()

        XCTAssertEqual(localization.resolvedLanguage, .english)
    }

    func testMetricHelpStringsAreLocalized() {
        let germanStrings = SpeedStrings(language: .german)
        let englishStrings = SpeedStrings(language: .english)

        XCTAssertEqual(
            germanStrings.metricPingHelp,
            "Leerlauf-Latenz: Wie lange eine kleine Anfrage ohne Last bis zur Antwort braucht. Niedriger ist besser."
        )
        XCTAssertEqual(
            germanStrings.metricResponsivenessHelp,
            "Reaktionszeit unter Last: Wie schnell Apps, Calls und Webseiten antworten, wenn die Leitung gerade beschäftigt ist. Niedriger ist besser."
        )
        XCTAssertEqual(
            germanStrings.metricNetworkHelp,
            "Rechts steht die aktive macOS-Schnittstelle wie en0. Darunter siehst du den Server, den der Test verwendet."
        )
        XCTAssertEqual(
            englishStrings.metricPingHelp,
            "Idle latency: how long a small request takes when the connection is not busy. Lower is better."
        )
        XCTAssertEqual(
            englishStrings.metricResponsivenessHelp,
            "Latency under load: how quickly apps, calls, and pages respond while the connection is busy. Lower is better."
        )
        XCTAssertEqual(
            englishStrings.metricNetworkHelp,
            "Shows the active macOS network interface on the right, such as en0. The line below shows the server used for the test."
        )
    }
}

private final class PreferredLanguagesBox: @unchecked Sendable {
    var value: [String]

    init(_ value: [String]) {
        self.value = value
    }
}
