import XCTest
@testable import SpeedCore

final class NetworkQualityParserTests: XCTestCase {
    func testParseSummaryMapsComputerReadableOutput() throws {
        let json = """
        {
          "base_rtt": 24.6,
          "dl_throughput": 347890123,
          "ul_throughput": 45000123,
          "dl_responsiveness": 112.2,
          "ul_responsiveness": 94.8,
          "interface_name": "en0",
          "test_endpoint": "fra1-edge.aaplimg.com",
          "end_date": "2026-03-13 10:38:50.800"
        }
        """

        let result = try NetworkQualityParser.parseSummary(from: Data(json.utf8))

        XCTAssertEqual(result.downloadMbps, 347.890123, accuracy: 0.000001)
        XCTAssertEqual(result.uploadMbps, 45.000123, accuracy: 0.000001)
        XCTAssertEqual(result.idleLatencyMs, 24.6, accuracy: 0.000001)
        XCTAssertEqual(result.downloadResponsivenessMs, 112.2, accuracy: 0.000001)
        XCTAssertEqual(result.uploadResponsivenessMs, 94.8, accuracy: 0.000001)
        XCTAssertEqual(result.interfaceName, "en0")
        XCTAssertEqual(result.serverName, "fra1-edge.aaplimg.com")
        XCTAssertEqual(result.profile, .excellent)
    }

    func testParseSummaryRejectsEmptyOutput() {
        XCTAssertThrowsError(try NetworkQualityParser.parseSummary(from: Data())) { error in
            XCTAssertEqual(error as? NetworkQualityError, .noOutput)
        }
    }
}
