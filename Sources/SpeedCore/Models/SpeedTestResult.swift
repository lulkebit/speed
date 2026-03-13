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

    public func title(using strings: SpeedStrings) -> String {
        strings.networkProfileTitle(self)
    }

    public func headline(using strings: SpeedStrings) -> String {
        strings.networkProfileHeadline(self)
    }

    public func detail(using strings: SpeedStrings) -> String {
        strings.networkProfileDetail(self)
    }
}
