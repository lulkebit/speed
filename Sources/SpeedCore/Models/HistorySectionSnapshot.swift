import Foundation

public struct HistorySectionSnapshot: Equatable, Sendable {
    public static let empty = HistorySectionSnapshot(history: [], range: .day, referenceDate: .now)

    public let range: HistoryTimeRange
    public let chartDomain: ClosedRange<Date>
    public let entries: [SpeedTestHistoryEntry]
    public let measurements: [SpeedTestResult]
    public let issues: [NetworkIssueRecord]
    public let recentEntries: [SpeedTestHistoryEntry]
    public let throughputChartMeasurements: [SpeedTestResult]
    public let latencyChartMeasurements: [SpeedTestResult]
    public let showsMeasurementPoints: Bool

    public init(
        history: [SpeedTestHistoryEntry],
        range: HistoryTimeRange,
        referenceDate: Date = .now,
        recentEntryLimit: Int = 4,
        maxChartPoints: Int = 96,
        pointMarkThreshold: Int = 20
    ) {
        let chartDomain = range.chartDomain(relativeTo: referenceDate)
        let entries = history.filter { chartDomain.contains($0.measuredAt) }
        let measurements = entries.compactMap(\.result)

        self.range = range
        self.chartDomain = chartDomain
        self.entries = entries
        self.measurements = measurements
        self.issues = entries.compactMap(\.issue)
        self.recentEntries = Array(entries.suffix(recentEntryLimit).reversed())
        self.throughputChartMeasurements = Self.sampleMeasurements(
            from: measurements,
            maxPoints: maxChartPoints,
            primaryValue: \.downloadMbps,
            secondaryValue: \.uploadMbps
        )
        self.latencyChartMeasurements = Self.sampleMeasurements(
            from: measurements,
            maxPoints: maxChartPoints,
            primaryValue: \.idleLatencyMs,
            secondaryValue: \.worstResponsivenessMs
        )
        self.showsMeasurementPoints = measurements.count <= pointMarkThreshold
    }

    public var isEmpty: Bool {
        entries.isEmpty
    }

    public func nearestEntry(to date: Date) -> SpeedTestHistoryEntry? {
        guard !entries.isEmpty else {
            return nil
        }

        var lowerBound = 0
        var upperBound = entries.count

        while lowerBound < upperBound {
            let midpoint = (lowerBound + upperBound) / 2

            if entries[midpoint].measuredAt < date {
                lowerBound = midpoint + 1
            } else {
                upperBound = midpoint
            }
        }

        if lowerBound == 0 {
            return entries.first
        }

        if lowerBound == entries.count {
            return entries.last
        }

        let previousEntry = entries[lowerBound - 1]
        let nextEntry = entries[lowerBound]

        if abs(previousEntry.measuredAt.timeIntervalSince(date))
            <= abs(nextEntry.measuredAt.timeIntervalSince(date)) {
            return previousEntry
        }

        return nextEntry
    }

    private static func sampleMeasurements(
        from measurements: [SpeedTestResult],
        maxPoints: Int,
        primaryValue: KeyPath<SpeedTestResult, Double>,
        secondaryValue: KeyPath<SpeedTestResult, Double>
    ) -> [SpeedTestResult] {
        guard maxPoints > 0, measurements.count > maxPoints else {
            return measurements
        }

        let bucketCount = max(1, maxPoints / 6)
        let bucketSize = Double(measurements.count) / Double(bucketCount)
        var selectedMeasurements = [SpeedTestResult]()
        var selectedDates = Set<Date>()

        func appendIfNeeded(_ measurement: SpeedTestResult) {
            guard selectedDates.insert(measurement.measuredAt).inserted else {
                return
            }

            selectedMeasurements.append(measurement)
        }

        for bucketIndex in 0..<bucketCount {
            let startIndex = Int(floor(Double(bucketIndex) * bucketSize))
            let endIndex = min(
                Int(floor(Double(bucketIndex + 1) * bucketSize)),
                measurements.count
            )

            guard startIndex < endIndex else {
                continue
            }

            let slice = measurements[startIndex..<endIndex]

            if let firstMeasurement = slice.first {
                appendIfNeeded(firstMeasurement)
            }

            if let lastMeasurement = slice.last {
                appendIfNeeded(lastMeasurement)
            }

            if let minimumPrimaryMeasurement = slice.min(by: {
                $0[keyPath: primaryValue] < $1[keyPath: primaryValue]
            }) {
                appendIfNeeded(minimumPrimaryMeasurement)
            }

            if let maximumPrimaryMeasurement = slice.max(by: {
                $0[keyPath: primaryValue] < $1[keyPath: primaryValue]
            }) {
                appendIfNeeded(maximumPrimaryMeasurement)
            }

            if let minimumSecondaryMeasurement = slice.min(by: {
                $0[keyPath: secondaryValue] < $1[keyPath: secondaryValue]
            }) {
                appendIfNeeded(minimumSecondaryMeasurement)
            }

            if let maximumSecondaryMeasurement = slice.max(by: {
                $0[keyPath: secondaryValue] < $1[keyPath: secondaryValue]
            }) {
                appendIfNeeded(maximumSecondaryMeasurement)
            }
        }

        let sortedMeasurements = selectedMeasurements.sorted { lhs, rhs in
            lhs.measuredAt < rhs.measuredAt
        }

        guard sortedMeasurements.count > maxPoints else {
            return sortedMeasurements
        }

        return evenlyTrim(sortedMeasurements, maxPoints: maxPoints)
    }

    private static func evenlyTrim(
        _ measurements: [SpeedTestResult],
        maxPoints: Int
    ) -> [SpeedTestResult] {
        guard maxPoints > 1, measurements.count > maxPoints else {
            return Array(measurements.prefix(maxPoints))
        }

        var trimmedMeasurements = [SpeedTestResult]()
        trimmedMeasurements.reserveCapacity(maxPoints)
        trimmedMeasurements.append(measurements[0])

        let interiorTargetCount = maxPoints - 2

        if interiorTargetCount > 0 {
            let lastIndex = measurements.count - 1
            let stride = Double(lastIndex) / Double(maxPoints - 1)

            for step in 1..<(maxPoints - 1) {
                let index = Int(round(Double(step) * stride))
                let clampedIndex = min(max(index, 1), lastIndex - 1)
                let measurement = measurements[clampedIndex]

                if trimmedMeasurements.last?.measuredAt != measurement.measuredAt {
                    trimmedMeasurements.append(measurement)
                }
            }
        }

        if trimmedMeasurements.last?.measuredAt != measurements[measurements.count - 1].measuredAt {
            trimmedMeasurements.append(measurements[measurements.count - 1])
        }

        return trimmedMeasurements
    }
}
