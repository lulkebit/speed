import Foundation

public enum HistoryTimeRange: String, CaseIterable, Identifiable, Sendable {
    case day
    case week
    case month

    public var id: String {
        rawValue
    }

    public var duration: TimeInterval {
        switch self {
        case .day:
            86_400
        case .week:
            604_800
        case .month:
            2_592_000
        }
    }

    public func title(using strings: SpeedStrings) -> String {
        strings.historyTimeRangeTitle(self)
    }

    public func chartDomain(relativeTo referenceDate: Date = Date()) -> ClosedRange<Date> {
        referenceDate.addingTimeInterval(-duration)...referenceDate
    }

    public func axisFormatStyle(locale: Locale) -> Date.FormatStyle {
        switch self {
        case .day:
            return Date.FormatStyle(date: .omitted, time: .shortened).locale(locale)
        case .week:
            return Date.FormatStyle()
                .month(.abbreviated)
                .day()
                .hour(.defaultDigits(amPM: .omitted))
                .locale(locale)
        case .month:
            return Date.FormatStyle()
                .month(.abbreviated)
                .day()
                .locale(locale)
        }
    }
}
