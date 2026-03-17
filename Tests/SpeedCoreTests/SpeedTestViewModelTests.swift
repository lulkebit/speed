import XCTest
@testable import SpeedCore

@MainActor
final class SpeedTestViewModelTests: XCTestCase {
    func testDownloadDeltaUsesPreviousMeasurement() {
        let suiteName = "SpeedTestViewModelTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Expected dedicated user defaults suite.")
        }

        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SpeedTestViewModelTests-\(UUID().uuidString)", isDirectory: true)

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: directoryURL)
        }

        let settingsStore = SpeedSettingsStore(userDefaults: userDefaults)
        let localization = SpeedLocalization(
            settingsStore: settingsStore,
            preferredLanguagesProvider: { ["en-US"] }
        )
        let historyStore = SpeedHistoryStore(directoryURL: directoryURL)

        _ = historyStore.append(makeResult(offset: -300, download: 120.0))
        _ = historyStore.append(makeResult(offset: 0, download: 145.4))

        let viewModel = SpeedTestViewModel(
            historyStore: historyStore,
            localization: localization
        )

        XCTAssertEqual(viewModel.downloadDeltaTrend, .up)
        XCTAssertEqual(viewModel.downloadDeltaText, "+25.4 Mbps")
    }

    func testDownloadDeltaTreatsTinyChangesAsUnchanged() {
        let suiteName = "SpeedTestViewModelTests-\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Expected dedicated user defaults suite.")
        }

        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SpeedTestViewModelTests-\(UUID().uuidString)", isDirectory: true)

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: directoryURL)
        }

        let settingsStore = SpeedSettingsStore(userDefaults: userDefaults)
        let localization = SpeedLocalization(
            settingsStore: settingsStore,
            preferredLanguagesProvider: { ["en-US"] }
        )
        let historyStore = SpeedHistoryStore(directoryURL: directoryURL)

        _ = historyStore.append(makeResult(offset: -300, download: 120.0))
        _ = historyStore.append(makeResult(offset: 0, download: 120.02))

        let viewModel = SpeedTestViewModel(
            historyStore: historyStore,
            localization: localization
        )

        XCTAssertEqual(viewModel.downloadDeltaTrend, .unchanged)
        XCTAssertEqual(viewModel.downloadDeltaText, "0.0 Mbps")
    }

    private func makeResult(offset: TimeInterval, download: Double) -> SpeedTestResult {
        SpeedTestResult(
            downloadMbps: download,
            uploadMbps: 32,
            idleLatencyMs: 18,
            downloadResponsivenessMs: 60,
            uploadResponsivenessMs: 74,
            interfaceName: "en0",
            serverName: "speed.test",
            measuredAt: Date(timeIntervalSince1970: 1_710_000_000).addingTimeInterval(offset)
        )
    }
}
