import Foundation

public enum MetricFormatter {
    public static func speed(_ megabitsPerSecond: Double?, locale: Locale) -> String {
        guard let megabitsPerSecond else {
            return "--"
        }

        let decimals = megabitsPerSecond >= 100 ? 0 : 1
        return megabitsPerSecond.formatted(
            .number.locale(locale).precision(.fractionLength(decimals))
        )
    }

    public static func milliseconds(_ milliseconds: Double?, locale: Locale) -> String {
        guard let milliseconds else {
            return "--"
        }

        return milliseconds.formatted(
            .number.locale(locale).precision(.fractionLength(0))
        )
    }

    public static func relativeTimestamp(_ date: Date?, locale: Locale) -> String? {
        guard let date else {
            return nil
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    public static func clockTimestamp(_ date: Date?, locale: Locale) -> String? {
        guard let date else {
            return nil
        }

        return date.formatted(
            Date.FormatStyle(date: .omitted, time: .shortened).locale(locale)
        )
    }
}
