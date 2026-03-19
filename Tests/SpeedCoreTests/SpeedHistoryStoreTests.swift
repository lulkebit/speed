import XCTest
@testable import SpeedCore

final class SpeedHistoryStoreTests: XCTestCase {
    func testHistoryStorePersistsAppendedResults() {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SpeedHistoryStoreTests-\(UUID().uuidString)", isDirectory: true)
        let historyStore = SpeedHistoryStore(directoryURL: directoryURL)

        defer {
            try? FileManager.default.removeItem(at: directoryURL)
        }

        let firstResult = makeResult(offset: -300, download: 120, upload: 30)
        let secondResult = makeResult(offset: 0, download: 260, upload: 42)

        _ = historyStore.append(firstResult)
        let storedHistory = historyStore.append(secondResult)

        XCTAssertEqual(
            storedHistory,
            [
                SpeedTestHistoryEntry(result: firstResult),
                SpeedTestHistoryEntry(result: secondResult)
            ]
        )
        XCTAssertEqual(
            historyStore.loadHistory(),
            [
                SpeedTestHistoryEntry(result: firstResult),
                SpeedTestHistoryEntry(result: secondResult)
            ]
        )
    }

    func testHistoryStoreTrimsOldResultsWhenLimitIsExceeded() {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SpeedHistoryStoreTests-\(UUID().uuidString)", isDirectory: true)
        let historyStore = SpeedHistoryStore(directoryURL: directoryURL, maxEntries: 2)

        defer {
            try? FileManager.default.removeItem(at: directoryURL)
        }

        let firstResult = makeResult(offset: -600, download: 80, upload: 20)
        let secondResult = makeResult(offset: -300, download: 120, upload: 24)
        let thirdResult = makeResult(offset: 0, download: 180, upload: 28)

        _ = historyStore.append(firstResult)
        _ = historyStore.append(secondResult)
        let trimmedHistory = historyStore.append(thirdResult)

        XCTAssertEqual(
            trimmedHistory,
            [
                SpeedTestHistoryEntry(result: secondResult),
                SpeedTestHistoryEntry(result: thirdResult)
            ]
        )
        XCTAssertEqual(
            historyStore.loadHistory(),
            [
                SpeedTestHistoryEntry(result: secondResult),
                SpeedTestHistoryEntry(result: thirdResult)
            ]
        )
    }

    func testHistoryStoreMigratesLegacyResultArrays() throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SpeedHistoryStoreTests-\(UUID().uuidString)", isDirectory: true)
        let historyStore = SpeedHistoryStore(directoryURL: directoryURL)

        defer {
            try? FileManager.default.removeItem(at: directoryURL)
        }

        let legacyResult = makeResult(offset: 0, download: 160, upload: 36)
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let fileURL = directoryURL.appendingPathComponent("history.json")
        let legacyData = try JSONEncoder().encode([legacyResult])
        try legacyData.write(to: fileURL)

        XCTAssertEqual(
            historyStore.loadHistory(),
            [SpeedTestHistoryEntry(result: legacyResult)]
        )
    }

    private func makeResult(offset: TimeInterval, download: Double, upload: Double) -> SpeedTestResult {
        SpeedTestResult(
            downloadMbps: download,
            uploadMbps: upload,
            idleLatencyMs: 18,
            downloadResponsivenessMs: 60,
            uploadResponsivenessMs: 74,
            interfaceName: "en0",
            serverName: "speed.test",
            measuredAt: Date(timeIntervalSince1970: 1_710_000_000).addingTimeInterval(offset)
        )
    }
}
