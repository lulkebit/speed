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

    public var title: String {
        switch self {
        case .off:
            "Aus"
        case .fiveMinutes:
            "Alle 5 Minuten"
        case .fifteenMinutes:
            "Alle 15 Minuten"
        case .thirtyMinutes:
            "Alle 30 Minuten"
        case .oneHour:
            "Stündlich"
        case .twoHours:
            "Alle 2 Stunden"
        }
    }

    public var shortTitle: String {
        switch self {
        case .off:
            "Aus"
        case .fiveMinutes:
            "5 Min"
        case .fifteenMinutes:
            "15 Min"
        case .thirtyMinutes:
            "30 Min"
        case .oneHour:
            "1 Std"
        case .twoHours:
            "2 Std"
        }
    }

    public var detail: String {
        switch self {
        case .off:
            "Es werden nur manuell gestartete Tests ausgeführt."
        case .fiveMinutes:
            "Ideal für kurze Checks während aktiver Netzwerkprobleme."
        case .fifteenMinutes:
            "Ein guter Mittelweg für regelmäßige Messungen."
        case .thirtyMinutes:
            "Sinnvoll für gelegentliche Hintergrundmessungen."
        case .oneHour:
            "Zurückhaltend und angenehm für langfristiges Monitoring."
        case .twoHours:
            "Sehr sparsam, wenn nur grobe Veränderungen wichtig sind."
        }
    }
}
