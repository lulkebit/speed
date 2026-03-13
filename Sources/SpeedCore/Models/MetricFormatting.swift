import Foundation

public enum MetricFormatter {
    public static func speed(_ megabitsPerSecond: Double?) -> String {
        guard let megabitsPerSecond else {
            return "--"
        }

        let decimals = megabitsPerSecond >= 100 ? 0 : 1
        return megabitsPerSecond.formatted(
            .number.precision(.fractionLength(decimals))
        )
    }

    public static func milliseconds(_ milliseconds: Double?) -> String {
        guard let milliseconds else {
            return "--"
        }

        return milliseconds.formatted(
            .number.precision(.fractionLength(0))
        )
    }

    public static func relativeTimestamp(_ date: Date?) -> String? {
        guard let date else {
            return nil
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    public static func clockTimestamp(_ date: Date?) -> String? {
        guard let date else {
            return nil
        }

        return date.formatted(date: .omitted, time: .shortened)
    }
}
