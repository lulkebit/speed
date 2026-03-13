import Foundation

public enum NetworkQualityError: Error, Equatable, Sendable {
    case alreadyRunning
    case commandUnavailable
    case noOutput
    case invalidOutput
    case cancelled
    case executionFailed(message: String?, status: Int32?)
}

private struct NetworkQualityCLIOutput: Decodable {
    let baseRTT: Double
    let dlThroughput: Double
    let ulThroughput: Double
    let dlResponsiveness: Double
    let ulResponsiveness: Double
    let interfaceName: String
    let testEndpoint: String
    let endDate: String

    enum CodingKeys: String, CodingKey {
        case baseRTT = "base_rtt"
        case dlThroughput = "dl_throughput"
        case ulThroughput = "ul_throughput"
        case dlResponsiveness = "dl_responsiveness"
        case ulResponsiveness = "ul_responsiveness"
        case interfaceName = "interface_name"
        case testEndpoint = "test_endpoint"
        case endDate = "end_date"
    }
}

public enum NetworkQualityParser {
    public static func parseSummary(from data: Data) throws -> SpeedTestResult {
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

        let measuredAt = timestampFormatter.date(from: payload.endDate) ?? Date()

        return SpeedTestResult(
            downloadMbps: payload.dlThroughput / 1_000_000,
            uploadMbps: payload.ulThroughput / 1_000_000,
            idleLatencyMs: payload.baseRTT,
            downloadResponsivenessMs: payload.dlResponsiveness,
            uploadResponsivenessMs: payload.ulResponsiveness,
            interfaceName: payload.interfaceName,
            serverName: payload.testEndpoint,
            measuredAt: measuredAt
        )
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
