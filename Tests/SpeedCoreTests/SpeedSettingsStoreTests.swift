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

    func testStoreDefaultsAutomaticUpdateChecksToEnabled() {
        let suiteName = "SpeedSettingsStoreTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Expected dedicated user defaults suite.")
        }

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let store = SpeedSettingsStore(userDefaults: userDefaults)

        XCTAssertTrue(store.automaticallyChecksForUpdates)
    }

    func testStorePersistsAutomaticUpdateChecks() {
        let suiteName = "SpeedSettingsStoreTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Expected dedicated user defaults suite.")
        }

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let store = SpeedSettingsStore(userDefaults: userDefaults)
        store.automaticallyChecksForUpdates = false

        let reloadedStore = SpeedSettingsStore(userDefaults: userDefaults)
        XCTAssertFalse(reloadedStore.automaticallyChecksForUpdates)
    }

    func testStoreDefaultsNetworkChangeTestsToEnabled() {
        let suiteName = "SpeedSettingsStoreTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Expected dedicated user defaults suite.")
        }

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let store = SpeedSettingsStore(userDefaults: userDefaults)

        XCTAssertTrue(store.automaticallyTestsOnNetworkChange)
    }

    func testStorePersistsNetworkChangeTestsPreference() {
        let suiteName = "SpeedSettingsStoreTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Expected dedicated user defaults suite.")
        }

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let store = SpeedSettingsStore(userDefaults: userDefaults)
        store.automaticallyTestsOnNetworkChange = false

        let reloadedStore = SpeedSettingsStore(userDefaults: userDefaults)
        XCTAssertFalse(reloadedStore.automaticallyTestsOnNetworkChange)
    }

    func testStorePersistsMenuBarDisplayMode() {
        let suiteName = "SpeedSettingsStoreTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Expected dedicated user defaults suite.")
        }

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let store = SpeedSettingsStore(userDefaults: userDefaults)
        XCTAssertEqual(store.menuBarDisplayMode, .icon)

        store.menuBarDisplayMode = .downloadAndUpload

        let reloadedStore = SpeedSettingsStore(userDefaults: userDefaults)
        XCTAssertEqual(reloadedStore.menuBarDisplayMode, .downloadAndUpload)
    }
}
