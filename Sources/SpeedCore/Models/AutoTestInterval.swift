import Foundation

public enum AutoTestInterval: Int, CaseIterable, Identifiable, Sendable {
    case off = 0
    case fiveMinutes = 300
    case fifteenMinutes = 900
    case thirtyMinutes = 1_800
    case oneHour = 3_600
    case twoHours = 7_200

    public var id: Int {
        rawValue
    }

    public var seconds: TimeInterval? {
        guard self != .off else {
            return nil
        }

        return TimeInterval(rawValue)
    }

    public func title(using strings: SpeedStrings) -> String {
        strings.autoTestIntervalTitle(self)
    }

    public func shortTitle(using strings: SpeedStrings) -> String {
        strings.autoTestIntervalShortTitle(self)
    }

    public func detail(using strings: SpeedStrings) -> String {
        strings.autoTestIntervalDetail(self)
    }
}
