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

    func testHistoryStoreLoadsLegacyIssueEntriesWithoutAggregationFields() throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SpeedHistoryStoreTests-\(UUID().uuidString)", isDirectory: true)
        let historyStore = SpeedHistoryStore(directoryURL: directoryURL)

        defer {
            try? FileManager.default.removeItem(at: directoryURL)
        }

        let legacyIssue = makeIssue(offset: 0, kind: .timeout)
        let encodedData = try JSONEncoder().encode([SpeedTestHistoryEntry(issue: legacyIssue)])
        let strippedData = try stripIssueAggregationFields(from: encodedData)

        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let fileURL = directoryURL.appendingPathComponent("history.json")
        try strippedData.write(to: fileURL)

        let loadedHistory = historyStore.loadHistory()
        XCTAssertEqual(loadedHistory.count, 1)

        guard let loadedIssue = loadedHistory.first?.issue else {
            return XCTFail("Expected to load a legacy issue entry.")
        }

        XCTAssertEqual(loadedIssue.occurrenceCount, 1)
        XCTAssertEqual(loadedIssue.startedAt, legacyIssue.measuredAt)
        XCTAssertEqual(loadedIssue.lastObservedAt, legacyIssue.measuredAt)
    }

    func testHistoryStoreMergesConsecutiveIssuesIntoSingleDisturbance() {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SpeedHistoryStoreTests-\(UUID().uuidString)", isDirectory: true)
        let historyStore = SpeedHistoryStore(directoryURL: directoryURL)

        defer {
            try? FileManager.default.removeItem(at: directoryURL)
        }

        _ = historyStore.append(makeIssue(offset: -300, kind: .timeout))
        let storedHistory = historyStore.append(makeIssue(offset: 0, kind: .internetUnavailable))

        XCTAssertEqual(storedHistory.count, 1)

        guard let mergedIssue = storedHistory.first?.issue else {
            return XCTFail("Expected a merged issue entry.")
        }

        XCTAssertEqual(mergedIssue.kind, .internetUnavailable)
        XCTAssertEqual(mergedIssue.occurrenceCount, 2)
        XCTAssertEqual(
            mergedIssue.startedAt,
            Date(timeIntervalSince1970: 1_710_000_000).addingTimeInterval(-300)
        )
        XCTAssertEqual(
            mergedIssue.lastObservedAt,
            Date(timeIntervalSince1970: 1_710_000_000)
        )
    }

    func testHistoryStoreDoesNotMergeIssuesAcrossSuccessfulMeasurement() {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SpeedHistoryStoreTests-\(UUID().uuidString)", isDirectory: true)
        let historyStore = SpeedHistoryStore(directoryURL: directoryURL)

        defer {
            try? FileManager.default.removeItem(at: directoryURL)
        }

        _ = historyStore.append(makeIssue(offset: -600, kind: .timeout))
        _ = historyStore.append(makeResult(offset: -300, download: 120, upload: 24))
        let storedHistory = historyStore.append(makeIssue(offset: 0, kind: .timeout))

        XCTAssertEqual(storedHistory.count, 3)
        XCTAssertEqual(storedHistory.compactMap(\.issue).count, 2)
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

    private func makeIssue(offset: TimeInterval, kind: NetworkIssueKind) -> NetworkIssueRecord {
        NetworkIssueRecord(
            kind: kind,
            measuredAt: Date(timeIntervalSince1970: 1_710_000_000).addingTimeInterval(offset),
            message: nil,
            status: nil,
            errorDomain: NSURLErrorDomain,
            errorCode: kind == .internetUnavailable ? URLError.notConnectedToInternet.rawValue : URLError.timedOut.rawValue,
            durationSeconds: 35,
            interfaceName: "en0",
            serverName: "speed.test",
            pathStatus: kind == .internetUnavailable ? "unsatisfied" : "satisfied",
            activeInterfaceNames: ["en0"],
            activeInterfaceKinds: ["wifi"]
        )
    }

    private func stripIssueAggregationFields(from data: Data) throws -> Data {
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        let strippedObject = removeAggregationFields(from: jsonObject)
        return try JSONSerialization.data(withJSONObject: strippedObject)
    }

    private func removeAggregationFields(from object: Any) -> Any {
        if let dictionary = object as? [String: Any] {
            var cleanedDictionary = dictionary
            cleanedDictionary.removeValue(forKey: "startedAt")
            cleanedDictionary.removeValue(forKey: "lastObservedAt")
            cleanedDictionary.removeValue(forKey: "occurrenceCount")

            return cleanedDictionary.mapValues(removeAggregationFields)
        }

        if let array = object as? [Any] {
            return array.map(removeAggregationFields)
        }

        return object
    }
}
