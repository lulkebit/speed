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

    func testParseOutputRecognizesInternetOutagePayload() throws {
        let json = """
        {
          "end_date": "2026-03-19 23:29:10.323",
          "error_code": -1009,
          "error_domain": "NSURLErrorDomain",
          "os_version": "Version 26.3.1 (Build 25D2128)",
          "start_date": "2026-03-19 23:29:10.305",
          "test_endpoint": "defra3-edge-bx-009.aaplimg.com"
        }
        """

        let output = try NetworkQualityParser.parseOutput(from: Data(json.utf8))

        switch output {
        case .success:
            XCTFail("Expected failure output for offline payload.")
        case let .failure(parsedFailure):
            XCTAssertEqual(parsedFailure.kind, .internetUnavailable)
            XCTAssertEqual(parsedFailure.context.errorDomain, NSURLErrorDomain)
            XCTAssertEqual(parsedFailure.context.errorCode, -1009)
            XCTAssertEqual(parsedFailure.context.serverName, "defra3-edge-bx-009.aaplimg.com")
        }
    }

    func testParseOutputRecognizesTimeoutFromPartialPayloadNearMaximumRuntime() throws {
        let json = """
        {
          "base_rtt": 30.906618118286133,
          "dl_throughput": 46617660,
          "end_date": "2026-03-19 23:28:55.888",
          "interface_name": "en0",
          "start_date": "2026-03-19 23:28:54.763",
          "test_endpoint": "defra3-edge-bx-009.aaplimg.com",
          "ul_responsiveness": 2748.091552734375,
          "ul_throughput": 58143588
        }
        """

        let output = try NetworkQualityParser.parseOutput(
            from: Data(json.utf8),
            maximumRuntime: 1
        )

        switch output {
        case .success:
            XCTFail("Expected timeout failure for truncated payload.")
        case let .failure(parsedFailure):
            XCTAssertEqual(parsedFailure.kind, .timeout)
            XCTAssertEqual(parsedFailure.context.durationSeconds, 1)
            XCTAssertEqual(parsedFailure.context.interfaceName, "en0")
        }
    }
}
