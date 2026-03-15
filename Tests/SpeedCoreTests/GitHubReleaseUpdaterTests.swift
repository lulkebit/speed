import XCTest
@testable import SpeedCore

final class GitHubReleaseUpdaterTests: XCTestCase {
    func testCheckForUpdatesReturnsAvailableReleaseWhenGitHubHasNewerVersion() async throws {
        let updater = GitHubReleaseUpdater(
            installedVersion: "1.1.0",
            bundleURLProvider: { URL(filePath: "/Applications/SpeedMenuBar.app") },
            dataLoader: { _ in
                (
                    Self.latestReleaseResponse(
                        tagName: "v1.2.0",
                        assetNames: ["SpeedMenuBar-1.2.0-macOS.zip"]
                    ),
                    Self.successResponse()
                )
            },
            fileDownloader: { _ in
                throw XCTSkip("Not used in this test.")
            }
        )

        let result = try await updater.checkForUpdates()

        switch result {
        case let .updateAvailable(release):
            XCTAssertEqual(release.version, "1.2.0")
            XCTAssertEqual(release.asset.name, "SpeedMenuBar-1.2.0-macOS.zip")
            XCTAssertEqual(release.releaseURL.absoluteString, "https://github.com/lulkebit/speed/releases/tag/v1.2.0")
        case .upToDate:
            XCTFail("Expected a newer release to be reported.")
        }
    }

    func testCheckForUpdatesReturnsUpToDateWhenVersionsMatch() async throws {
        let updater = GitHubReleaseUpdater(
            installedVersion: "1.2.0",
            bundleURLProvider: { URL(filePath: "/Applications/SpeedMenuBar.app") },
            dataLoader: { _ in
                (
                    Self.latestReleaseResponse(
                        tagName: "v1.2.0",
                        assetNames: ["SpeedMenuBar-1.2.0-macOS.zip"]
                    ),
                    Self.successResponse()
                )
            },
            fileDownloader: { _ in
                throw XCTSkip("Not used in this test.")
            }
        )

        let result = try await updater.checkForUpdates()

        XCTAssertEqual(result, .upToDate)
    }

    func testCheckForUpdatesIgnoresBuildMetadataInReleaseTag() async throws {
        let updater = GitHubReleaseUpdater(
            installedVersion: "1.2.0",
            bundleURLProvider: { URL(filePath: "/Applications/SpeedMenuBar.app") },
            dataLoader: { _ in
                (
                    Self.latestReleaseResponse(
                        tagName: "v1.2.0+5",
                        assetNames: ["SpeedMenuBar-1.2.0-macOS.zip"]
                    ),
                    Self.successResponse()
                )
            },
            fileDownloader: { _ in
                throw XCTSkip("Not used in this test.")
            }
        )

        let result = try await updater.checkForUpdates()

        XCTAssertEqual(result, .upToDate)
    }

    func testCheckForUpdatesFailsWhenLatestReleaseHasNoZipAsset() async throws {
        let updater = GitHubReleaseUpdater(
            installedVersion: "1.1.0",
            bundleURLProvider: { URL(filePath: "/Applications/SpeedMenuBar.app") },
            dataLoader: { _ in
                (
                    Self.latestReleaseResponse(
                        tagName: "v1.2.0",
                        assetNames: ["SpeedMenuBar.dmg"]
                    ),
                    Self.successResponse()
                )
            },
            fileDownloader: { _ in
                throw XCTSkip("Not used in this test.")
            }
        )

        await XCTAssertThrowsErrorAsync(try await updater.checkForUpdates()) { error in
            XCTAssertEqual(error as? AppUpdateError, .latestReleaseMissingAsset)
        }
    }
}

private extension GitHubReleaseUpdaterTests {
    static func latestReleaseResponse(tagName: String, assetNames: [String]) -> Data {
        let assets = assetNames.map { name in
            """
            {
              "name": "\(name)",
              "browser_download_url": "https://github.com/lulkebit/speed/releases/download/\(tagName)/\(name)"
            }
            """
        }
        .joined(separator: ",")

        let json = """
        {
          "tag_name": "\(tagName)",
          "html_url": "https://github.com/lulkebit/speed/releases/tag/\(tagName)",
          "assets": [\(assets)]
        }
        """

        return Data(json.utf8)
    }

    static func successResponse() -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://api.github.com/repos/lulkebit/speed/releases/latest")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
    }
}

private func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    _ errorHandler: (Error) -> Void
) async {
    do {
        _ = try await expression()
        XCTFail("Expected expression to throw an error.")
    } catch {
        errorHandler(error)
    }
}
