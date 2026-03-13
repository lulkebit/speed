import XCTest
@testable import SpeedCore

final class SpeedSettingsStoreTests: XCTestCase {
    func testStorePersistsAutomaticInterval() {
        let suiteName = "SpeedSettingsStoreTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Expected dedicated user defaults suite.")
        }

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let store = SpeedSettingsStore(userDefaults: userDefaults)
        XCTAssertEqual(store.automaticTestInterval, .off)

        store.automaticTestInterval = .thirtyMinutes

        let reloadedStore = SpeedSettingsStore(userDefaults: userDefaults)
        XCTAssertEqual(reloadedStore.automaticTestInterval, .thirtyMinutes)
    }

    func testStorePersistsAppLanguage() {
        let suiteName = "SpeedSettingsStoreTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Expected dedicated user defaults suite.")
        }

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let store = SpeedSettingsStore(userDefaults: userDefaults)
        XCTAssertEqual(store.appLanguage, .system)

        store.appLanguage = .english

        let reloadedStore = SpeedSettingsStore(userDefaults: userDefaults)
        XCTAssertEqual(reloadedStore.appLanguage, .english)
    }
}
