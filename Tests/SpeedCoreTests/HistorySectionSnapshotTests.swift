import XCTest
@testable import SpeedCore

final class HistorySectionSnapshotTests: XCTestCase {
    func testSnapshotFiltersEntriesAndBuildsRecentEntries() {
        let referenceDate = Date(timeIntervalSince1970: 1_710_000_000)
        let history = [
            SpeedTestHistoryEntry(result: makeResult(offset: -90_000, download: 80, upload: 20)),
            SpeedTestHistoryEntry(result: makeResult(offset: -18_000, download: 100, upload: 24)),
            SpeedTestHistoryEntry(result: makeResult(offset: -10_800, download: 120, upload: 26)),
            SpeedTestHistoryEntry(result: makeResult(offset: -7_200, download: 140, upload: 28)),
            SpeedTestHistoryEntry(result: makeResult(offset: -3_600, download: 160, upload: 30)),
            SpeedTestHistoryEntry(result: makeResult(offset: -600, download: 180, upload: 32))
        ]

        let snapshot = HistorySectionSnapshot(
            history: history,
            range: .day,
            referenceDate: referenceDate
        )

        XCTAssertEqual(snapshot.entries.count, 5)
        XCTAssertEqual(snapshot.measurements.count, 5)
        XCTAssertEqual(snapshot.recentEntries.count, 4)
        XCTAssertEqual(snapshot.recentEntries.first?.measuredAt, history[5].measuredAt)
        XCTAssertEqual(snapshot.recentEntries.last?.measuredAt, history[2].measuredAt)
        XCTAssertEqual(snapshot.chartDomain.lowerBound, referenceDate.addingTimeInterval(-86_400))
        XCTAssertEqual(snapshot.chartDomain.upperBound, referenceDate)
    }

    func testSnapshotNearestEntryReturnsClosestMeasurement() {
        let referenceDate = Date(timeIntervalSince1970: 1_710_000_000)
        let history = [
            SpeedTestHistoryEntry(result: makeResult(offset: -300, download: 100, upload: 24)),
            SpeedTestHistoryEntry(result: makeResult(offset: -120, download: 120, upload: 26)),
            SpeedTestHistoryEntry(result: makeResult(offset: 0, download: 140, upload: 28))
        ]

        let snapshot = HistorySectionSnapshot(
            history: history,
            range: .day,
            referenceDate: referenceDate
        )

        XCTAssertEqual(
            snapshot.nearestEntry(to: referenceDate.addingTimeInterval(-100))?.measuredAt,
            history[1].measuredAt
        )
        XCTAssertEqual(
            snapshot.nearestEntry(to: referenceDate.addingTimeInterval(-260))?.measuredAt,
            history[0].measuredAt
        )
        XCTAssertEqual(
            snapshot.nearestEntry(to: referenceDate.addingTimeInterval(30))?.measuredAt,
            history[2].measuredAt
        )
    }

    func testSnapshotSamplesChartMeasurementsAndPreservesSpikes() {
        let baseDate = Date(timeIntervalSince1970: 1_710_000_000)
        var results = [SpeedTestResult]()
        results.reserveCapacity(60)

        for index in 0..<60 {
            let measuredAt = baseDate.addingTimeInterval(Double(index) * 60)
            let download = 100.0 + Double(index)
            let upload = 20.0 + Double(index % 6)
            let latency = 12.0 + Double(index % 5)
            let responsiveness = 52.0 + Double(index % 7)

            results.append(
                SpeedTestResult(
                    downloadMbps: download,
                    uploadMbps: upload,
                    idleLatencyMs: latency,
                    downloadResponsivenessMs: responsiveness - 8,
                    uploadResponsivenessMs: responsiveness,
                    interfaceName: "en0",
                    serverName: "speed.test",
                    measuredAt: measuredAt
                )
            )
        }

        results[10] = makeResult(
            offsetFrom: baseDate,
            minuteOffset: 10,
            download: 980,
            upload: 24,
            latency: 14,
            responsiveness: 58
        )
        results[20] = makeResult(
            offsetFrom: baseDate,
            minuteOffset: 20,
            download: 122,
            upload: 420,
            latency: 15,
            responsiveness: 60
        )
        results[35] = makeResult(
            offsetFrom: baseDate,
            minuteOffset: 35,
            download: 135,
            upload: 25,
            latency: 380,
            responsiveness: 62
        )
        results[50] = makeResult(
            offsetFrom: baseDate,
            minuteOffset: 50,
            download: 150,
            upload: 26,
            latency: 16,
            responsiveness: 760
        )

        let snapshot = HistorySectionSnapshot(
            history: results.map(SpeedTestHistoryEntry.init(result:)),
            range: .day,
            referenceDate: baseDate.addingTimeInterval(61 * 60),
            maxChartPoints: 24,
            pointMarkThreshold: 24
        )

        XCTAssertEqual(snapshot.measurements.count, 60)
        XCTAssertLessThanOrEqual(snapshot.throughputChartMeasurements.count, 24)
        XCTAssertLessThanOrEqual(snapshot.latencyChartMeasurements.count, 24)
        XCTAssertFalse(snapshot.showsMeasurementPoints)
        XCTAssertEqual(snapshot.throughputChartMeasurements.first?.measuredAt, results.first?.measuredAt)
        XCTAssertEqual(snapshot.throughputChartMeasurements.last?.measuredAt, results.last?.measuredAt)
        XCTAssertTrue(snapshot.throughputChartMeasurements.contains(where: { $0.measuredAt == results[10].measuredAt }))
        XCTAssertTrue(snapshot.throughputChartMeasurements.contains(where: { $0.measuredAt == results[20].measuredAt }))
        XCTAssertTrue(snapshot.latencyChartMeasurements.contains(where: { $0.measuredAt == results[35].measuredAt }))
        XCTAssertTrue(snapshot.latencyChartMeasurements.contains(where: { $0.measuredAt == results[50].measuredAt }))
    }

    private func makeResult(offset: TimeInterval, download: Double, upload: Double) -> SpeedTestResult {
        makeResult(
            offsetFrom: Date(timeIntervalSince1970: 1_710_000_000),
            minuteOffset: Int(offset / 60),
            download: download,
            upload: upload,
            latency: 18,
            responsiveness: 74
        )
    }

    private func makeResult(
        offsetFrom baseDate: Date,
        minuteOffset: Int,
        download: Double,
        upload: Double,
        latency: Double,
        responsiveness: Double
    ) -> SpeedTestResult {
        SpeedTestResult(
            downloadMbps: download,
            uploadMbps: upload,
            idleLatencyMs: latency,
            downloadResponsivenessMs: responsiveness - 6,
            uploadResponsivenessMs: responsiveness,
            interfaceName: "en0",
            serverName: "speed.test",
            measuredAt: baseDate.addingTimeInterval(Double(minuteOffset) * 60)
        )
    }
}
