import Foundation

public struct SpeedTestResult: Equatable, Sendable {
    public let downloadMbps: Double
    public let uploadMbps: Double
    public let idleLatencyMs: Double
    public let downloadResponsivenessMs: Double
    public let uploadResponsivenessMs: Double
    public let interfaceName: String
    public let serverName: String
    public let measuredAt: Date

    public init(
        downloadMbps: Double,
        uploadMbps: Double,
        idleLatencyMs: Double,
        downloadResponsivenessMs: Double,
        uploadResponsivenessMs: Double,
        interfaceName: String,
        serverName: String,
        measuredAt: Date
    ) {
        self.downloadMbps = downloadMbps
        self.uploadMbps = uploadMbps
        self.idleLatencyMs = idleLatencyMs
        self.downloadResponsivenessMs = downloadResponsivenessMs
        self.uploadResponsivenessMs = uploadResponsivenessMs
        self.interfaceName = interfaceName
        self.serverName = serverName
        self.measuredAt = measuredAt
    }

    public var worstResponsivenessMs: Double {
        max(downloadResponsivenessMs, uploadResponsivenessMs)
    }

    public var profile: NetworkProfile {
        if worstResponsivenessMs < 120, idleLatencyMs < 25 {
            return .excellent
        }

        if worstResponsivenessMs < 250, idleLatencyMs < 50 {
            return .strong
        }

        if worstResponsivenessMs < 500, idleLatencyMs < 90 {
            return .stable
        }

        return .weak
    }
}

public enum NetworkProfile: String, Equatable, Sendable {
    case excellent
    case strong
    case stable
    case weak

    public var title: String {
        switch self {
        case .excellent:
            "Sehr flink"
        case .strong:
            "Stark"
        case .stable:
            "Solide"
        case .weak:
            "Träge"
        }
    }

    public var headline: String {
        switch self {
        case .excellent:
            "Reagiert fast ohne Verzögerung"
        case .strong:
            "Schnell genug für Streaming und Calls"
        case .stable:
            "Im Alltag stabil, aber nicht superspritzig"
        case .weak:
            "Bei interaktiven Aufgaben spürbar langsam"
        }
    }

    public var detail: String {
        switch self {
        case .excellent:
            "Sehr gut für Video-Calls, Cloud-Work und mehrere aktive Geräte."
        case .strong:
            "Fühlt sich flott an und sollte auch unter Last zuverlässig bleiben."
        case .stable:
            "Passt für Alltag, Surfen und Streaming. Unter Last kann es zäher werden."
        case .weak:
            "Downloads laufen oft noch okay, aber Reaktionszeit und Parallelbetrieb leiden."
        }
    }
}
