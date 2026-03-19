import Foundation

public struct NetworkQualityFailureContext: Equatable, Sendable {
    public let measuredAt: Date
    public let message: String?
    public let status: Int32?
    public let errorDomain: String?
    public let errorCode: Int?
    public let durationSeconds: Int?
    public let interfaceName: String?
    public let serverName: String?
    public let pathStatus: String?
    public let activeInterfaceNames: [String]
    public let activeInterfaceKinds: [String]

    public init(
        measuredAt: Date,
        message: String? = nil,
        status: Int32? = nil,
        errorDomain: String? = nil,
        errorCode: Int? = nil,
        durationSeconds: Int? = nil,
        interfaceName: String? = nil,
        serverName: String? = nil,
        pathStatus: String? = nil,
        activeInterfaceNames: [String] = [],
        activeInterfaceKinds: [String] = []
    ) {
        self.measuredAt = measuredAt
        self.message = message
        self.status = status
        self.errorDomain = errorDomain
        self.errorCode = errorCode
        self.durationSeconds = durationSeconds
        self.interfaceName = interfaceName
        self.serverName = serverName
        self.pathStatus = pathStatus
        self.activeInterfaceNames = activeInterfaceNames
        self.activeInterfaceKinds = activeInterfaceKinds
    }

    func with(
        message: String? = nil,
        status: Int32? = nil,
        pathStatus: String? = nil,
        activeInterfaceNames: [String]? = nil,
        activeInterfaceKinds: [String]? = nil
    ) -> Self {
        Self(
            measuredAt: measuredAt,
            message: message ?? self.message,
            status: status ?? self.status,
            errorDomain: errorDomain,
            errorCode: errorCode,
            durationSeconds: durationSeconds,
            interfaceName: interfaceName,
            serverName: serverName,
            pathStatus: pathStatus ?? self.pathStatus,
            activeInterfaceNames: activeInterfaceNames ?? self.activeInterfaceNames,
            activeInterfaceKinds: activeInterfaceKinds ?? self.activeInterfaceKinds
        )
    }
}

public enum NetworkQualityError: Error, Equatable, Sendable {
    case alreadyRunning
    case commandUnavailable
    case noOutput
    case invalidOutput
    case cancelled
    case timedOut(NetworkQualityFailureContext)
    case internetUnavailable(NetworkQualityFailureContext)
    case executionFailed(NetworkQualityFailureContext)
}

private struct NetworkQualityCLIOutput: Decodable {
    let baseRTT: Double?
    let dlThroughput: Double?
    let ulThroughput: Double?
    let dlResponsiveness: Double?
    let ulResponsiveness: Double?
    let interfaceName: String?
    let testEndpoint: String?
    let startDate: String?
    let endDate: String?
    let errorCode: Int?
    let errorDomain: String?

    enum CodingKeys: String, CodingKey {
        case baseRTT = "base_rtt"
        case dlThroughput = "dl_throughput"
        case ulThroughput = "ul_throughput"
        case dlResponsiveness = "dl_responsiveness"
        case ulResponsiveness = "ul_responsiveness"
        case interfaceName = "interface_name"
        case testEndpoint = "test_endpoint"
        case startDate = "start_date"
        case endDate = "end_date"
        case errorCode = "error_code"
        case errorDomain = "error_domain"
    }
}

enum NetworkQualityParsedOutput: Equatable, Sendable {
    case success(SpeedTestResult)
    case failure(NetworkQualityParsedFailure)
}

struct NetworkQualityParsedFailure: Equatable, Sendable {
    let kind: NetworkIssueKind
    let context: NetworkQualityFailureContext
}

public enum NetworkQualityParser {
    public static func parseSummary(from data: Data) throws -> SpeedTestResult {
        switch try parseOutput(from: data) {
        case let .success(result):
            return result
        case .failure:
            throw NetworkQualityError.invalidOutput
        }
    }

    static func parseOutput(
        from data: Data,
        maximumRuntime: TimeInterval? = nil
    ) throws -> NetworkQualityParsedOutput {
        guard !data.isEmpty else {
            throw NetworkQualityError.noOutput
        }

        let decoder = JSONDecoder()

        let payload: NetworkQualityCLIOutput
        do {
            payload = try decoder.decode(NetworkQualityCLIOutput.self, from: data)
        } catch {
            throw NetworkQualityError.invalidOutput
        }

        let measuredAt = timestampFormatter.date(from: payload.endDate ?? "") ?? Date()
        let durationSeconds = duration(from: payload)

        if let failureKind = failureKind(for: payload, maximumRuntime: maximumRuntime) {
            return .failure(
                NetworkQualityParsedFailure(
                    kind: failureKind,
                    context: NetworkQualityFailureContext(
                        measuredAt: measuredAt,
                        errorDomain: payload.errorDomain,
                        errorCode: payload.errorCode,
                        durationSeconds: durationSeconds,
                        interfaceName: payload.interfaceName,
                        serverName: payload.testEndpoint
                    )
                )
            )
        }

        guard let baseRTT = payload.baseRTT,
              let dlThroughput = payload.dlThroughput,
              let ulThroughput = payload.ulThroughput,
              let dlResponsiveness = payload.dlResponsiveness,
              let ulResponsiveness = payload.ulResponsiveness,
              let interfaceName = payload.interfaceName,
              let testEndpoint = payload.testEndpoint else {
            throw NetworkQualityError.invalidOutput
        }

        return .success(
            SpeedTestResult(
                downloadMbps: dlThroughput / 1_000_000,
                uploadMbps: ulThroughput / 1_000_000,
                idleLatencyMs: baseRTT,
                downloadResponsivenessMs: dlResponsiveness,
                uploadResponsivenessMs: ulResponsiveness,
                interfaceName: interfaceName,
                serverName: testEndpoint,
                measuredAt: measuredAt
            )
        )
    }

    private static func failureKind(
        for payload: NetworkQualityCLIOutput,
        maximumRuntime: TimeInterval?
    ) -> NetworkIssueKind? {
        if let errorDomain = payload.errorDomain, let errorCode = payload.errorCode {
            return classifyFailure(errorDomain: errorDomain, errorCode: errorCode)
        }

        guard !hasRequiredMetrics(payload) else {
            return nil
        }

        if isLikelyTimeout(payload, maximumRuntime: maximumRuntime) {
            return .timeout
        }

        return .failure
    }

    private static func classifyFailure(errorDomain: String, errorCode: Int) -> NetworkIssueKind {
        if errorDomain == NSURLErrorDomain {
            switch URLError.Code(rawValue: errorCode) {
            case .timedOut:
                return .timeout
            case .notConnectedToInternet,
                 .networkConnectionLost,
                 .cannotConnectToHost,
                 .cannotFindHost,
                 .dnsLookupFailed,
                 .internationalRoamingOff:
                return .internetUnavailable
            default:
                return .failure
            }
        }

        return .failure
    }

    private static func hasRequiredMetrics(_ payload: NetworkQualityCLIOutput) -> Bool {
        payload.baseRTT != nil &&
            payload.dlThroughput != nil &&
            payload.ulThroughput != nil &&
            payload.dlResponsiveness != nil &&
            payload.ulResponsiveness != nil &&
            payload.interfaceName != nil &&
            payload.testEndpoint != nil
    }

    private static func isLikelyTimeout(
        _ payload: NetworkQualityCLIOutput,
        maximumRuntime: TimeInterval?
    ) -> Bool {
        guard let maximumRuntime,
              let duration = durationTimeInterval(from: payload) else {
            return false
        }

        let tolerance = max(0.5, min(4.0, maximumRuntime * 0.15))
        return duration >= maximumRuntime - tolerance
    }

    private static func duration(from payload: NetworkQualityCLIOutput) -> Int? {
        guard let duration = durationTimeInterval(from: payload) else {
            return nil
        }

        return max(Int(duration.rounded()), 1)
    }

    private static func durationTimeInterval(from payload: NetworkQualityCLIOutput) -> TimeInterval? {
        guard let startDate = timestampFormatter.date(from: payload.startDate ?? ""),
              let endDate = timestampFormatter.date(from: payload.endDate ?? "") else {
            return nil
        }

        return max(endDate.timeIntervalSince(startDate), 0)
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}
