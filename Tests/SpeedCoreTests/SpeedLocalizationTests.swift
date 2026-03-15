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
}

private final class PreferredLanguagesBox: @unchecked Sendable {
    var value: [String]

    init(_ value: [String]) {
        self.value = value
    }
}
