import Foundation

public struct AppUpdateAsset: Equatable, Sendable {
    public let name: String
    public let downloadURL: URL

    public init(name: String, downloadURL: URL) {
        self.name = name
        self.downloadURL = downloadURL
    }
}

public struct AppUpdateRelease: Equatable, Sendable {
    public let version: String
    public let releaseURL: URL
    public let asset: AppUpdateAsset

    public init(version: String, releaseURL: URL, asset: AppUpdateAsset) {
        self.version = version
        self.releaseURL = releaseURL
        self.asset = asset
    }
}

public enum AppUpdateCheckResult: Equatable, Sendable {
    case upToDate
    case updateAvailable(AppUpdateRelease)
}

public enum AppUpdateError: Error, Equatable, Sendable {
    case invalidServerResponse
    case unexpectedStatusCode(Int)
    case releaseVersionMissing
    case latestReleaseMissingAsset
    case requiresBundledApp
    case extractionFailed(status: Int32)
    case extractedAppNotFound
    case installerLaunchFailed(String?)
}

public protocol AppUpdateManaging: Sendable {
    var installedVersion: String { get }

    func checkForUpdates() async throws -> AppUpdateCheckResult
    func installUpdate(_ release: AppUpdateRelease) async throws
}

public actor GitHubReleaseUpdater: AppUpdateManaging {
    public nonisolated let installedVersion: String

    private let bundleURLProvider: @Sendable () -> URL
    private let dataLoader: @Sendable (URLRequest) async throws -> (Data, URLResponse)
    private let fileDownloader: @Sendable (URL) async throws -> (URL, URLResponse)
    private let archiveExtractor: @Sendable (URL, URL) async throws -> Void
    private let installerLauncher: @Sendable (InstallerLaunchContext) throws -> Void
    private let fileManager: FileManager
    private let latestReleaseURL: URL

    public init() {
        self.init(
            repositoryOwner: "lulkebit",
            repositoryName: "speed",
            installedVersion: Self.defaultInstalledVersion,
            bundleURLProvider: { Bundle.main.bundleURL },
            dataLoader: { try await URLSession.shared.data(for: $0) },
            fileDownloader: { try await URLSession.shared.download(from: $0) },
            archiveExtractor: Self.extractArchive,
            installerLauncher: Self.launchInstaller,
            fileManager: .default
        )
    }

    public init(
        repositoryOwner: String = "lulkebit",
        repositoryName: String = "speed",
        installedVersion: String,
        bundleURLProvider: @escaping @Sendable () -> URL = { Bundle.main.bundleURL },
        dataLoader: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse) = {
            try await URLSession.shared.data(for: $0)
        },
        fileDownloader: @escaping @Sendable (URL) async throws -> (URL, URLResponse) = {
            try await URLSession.shared.download(from: $0)
        },
        fileManager: FileManager = .default
    ) {
        self.init(
            repositoryOwner: repositoryOwner,
            repositoryName: repositoryName,
            installedVersion: installedVersion,
            bundleURLProvider: bundleURLProvider,
            dataLoader: dataLoader,
            fileDownloader: fileDownloader,
            archiveExtractor: Self.extractArchive,
            installerLauncher: Self.launchInstaller,
            fileManager: fileManager
        )
    }

    private init(
        repositoryOwner: String,
        repositoryName: String,
        installedVersion: String,
        bundleURLProvider: @escaping @Sendable () -> URL,
        dataLoader: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse),
        fileDownloader: @escaping @Sendable (URL) async throws -> (URL, URLResponse),
        archiveExtractor: @escaping @Sendable (URL, URL) async throws -> Void,
        installerLauncher: @escaping @Sendable (InstallerLaunchContext) throws -> Void,
        fileManager: FileManager
    ) {
        self.installedVersion = Self.normalizeVersion(installedVersion) ?? installedVersion
        self.bundleURLProvider = bundleURLProvider
        self.dataLoader = dataLoader
        self.fileDownloader = fileDownloader
        self.archiveExtractor = archiveExtractor
        self.installerLauncher = installerLauncher
        self.fileManager = fileManager
        self.latestReleaseURL = URL(
            string: "https://api.github.com/repos/\(repositoryOwner)/\(repositoryName)/releases/latest"
        )!
    }

    public func checkForUpdates() async throws -> AppUpdateCheckResult {
        var request = URLRequest(url: latestReleaseURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("SpeedMenuBar/\(installedVersion)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await dataLoader(request)
        try Self.validate(response: response)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let release = try decoder.decode(GitHubReleaseResponse.self, from: data)
        guard let latestVersion = Self.normalizeVersion(release.tagName) else {
            throw AppUpdateError.releaseVersionMissing
        }

        guard Self.compareVersions(latestVersion, installedVersion) == .orderedDescending else {
            return .upToDate
        }

        let preferredAppName = bundleURLProvider().deletingPathExtension().lastPathComponent
        guard let asset = Self.selectAsset(from: release.assets, preferredAppName: preferredAppName) else {
            throw AppUpdateError.latestReleaseMissingAsset
        }

        return .updateAvailable(
            AppUpdateRelease(
                version: latestVersion,
                releaseURL: release.htmlURL,
                asset: AppUpdateAsset(name: asset.name, downloadURL: asset.browserDownloadURL)
            )
        )
    }

    public func installUpdate(_ release: AppUpdateRelease) async throws {
        let currentAppURL = bundleURLProvider()

        guard currentAppURL.pathExtension == "app" else {
            throw AppUpdateError.requiresBundledApp
        }

        let stageRootURL = fileManager.temporaryDirectory.appending(
            path: "SpeedUpdate-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
        try fileManager.createDirectory(
            at: stageRootURL,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let archiveURL = stageRootURL.appendingPathComponent(release.asset.name)
        let extractURL = stageRootURL.appending(path: "Extracted", directoryHint: .isDirectory)

        let (downloadedFileURL, response) = try await fileDownloader(release.asset.downloadURL)
        try Self.validate(response: response)

        try fileManager.copyItem(at: downloadedFileURL, to: archiveURL)
        try fileManager.createDirectory(
            at: extractURL,
            withIntermediateDirectories: true,
            attributes: nil
        )

        try await archiveExtractor(archiveURL, extractURL)

        guard let downloadedAppURL = Self.findAppBundle(
            in: extractURL,
            preferredName: currentAppURL.lastPathComponent
        ) else {
            throw AppUpdateError.extractedAppNotFound
        }

        try installerLauncher(
            InstallerLaunchContext(
                currentAppURL: currentAppURL,
                downloadedAppURL: downloadedAppURL,
                stageRootURL: stageRootURL,
                processIdentifier: ProcessInfo.processInfo.processIdentifier
            )
        )
    }
}

private extension GitHubReleaseUpdater {
    static var defaultInstalledVersion: String {
        let rawVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return normalizeVersion(rawVersion) ?? "0.0.0"
    }

    static func normalizeVersion(_ rawVersion: String?) -> String? {
        guard let rawVersion else {
            return nil
        }

        var trimmedVersion = rawVersion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedVersion.isEmpty else {
            return nil
        }

        if trimmedVersion.first == "v" || trimmedVersion.first == "V" {
            trimmedVersion = String(trimmedVersion.dropFirst())
        }

        if let buildMetadataStart = trimmedVersion.firstIndex(of: "+") {
            trimmedVersion = String(trimmedVersion[..<buildMetadataStart])
        }

        return trimmedVersion.isEmpty ? nil : trimmedVersion
    }

    static func compareVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
        lhs.compare(rhs, options: [.numeric, .caseInsensitive])
    }

    static func validate(response: URLResponse) throws {
        guard let response = response as? HTTPURLResponse else {
            throw AppUpdateError.invalidServerResponse
        }

        guard (200...299).contains(response.statusCode) else {
            throw AppUpdateError.unexpectedStatusCode(response.statusCode)
        }
    }

    static func selectAsset(
        from assets: [GitHubReleaseAsset],
        preferredAppName: String
    ) -> GitHubReleaseAsset? {
        let zipAssets = assets.filter { $0.name.lowercased().hasSuffix(".zip") }
        guard !zipAssets.isEmpty else {
            return nil
        }

        let normalizedAppName = normalizedAssetToken(preferredAppName)

        return zipAssets.max { lhs, rhs in
            assetScore(for: lhs, preferredAppName: normalizedAppName) <
                assetScore(for: rhs, preferredAppName: normalizedAppName)
        }
    }

    static func assetScore(for asset: GitHubReleaseAsset, preferredAppName: String) -> Int {
        let normalizedName = normalizedAssetToken(asset.name)
        var score = 0

        if normalizedName.contains(preferredAppName) {
            score += 4
        }

        if normalizedName.contains("macos") {
            score += 3
        }

        if normalizedName.contains("darwin") {
            score += 2
        }

        if normalizedName.contains("universal") {
            score += 1
        }

        return score
    }

    static func normalizedAssetToken(_ value: String) -> String {
        value
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
    }

    static func extractArchive(at archiveURL: URL, to destinationURL: URL) async throws {
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/ditto")
        process.arguments = ["-x", "-k", archiveURL.path, destinationURL.path]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw AppUpdateError.extractionFailed(status: process.terminationStatus)
        }
    }

    static func findAppBundle(in rootURL: URL, preferredName: String) -> URL? {
        let preferredAppURL = rootURL.appendingPathComponent(preferredName)
        if FileManager.default.fileExists(atPath: preferredAppURL.path) {
            return preferredAppURL
        }

        guard let enumerator = FileManager.default.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        for case let url as URL in enumerator {
            if url.pathExtension == "app" {
                return url
            }
        }

        return nil
    }

    static func launchInstaller(with context: InstallerLaunchContext) throws {
        let scriptURL = context.stageRootURL.appendingPathComponent("install-update.sh")
        let script = """
        #!/bin/zsh
        set -euo pipefail

        current_app="$1"
        new_app="$2"
        process_id="$3"
        stage_root="$4"

        wait_for_exit() {
            while kill -0 "$process_id" 2>/dev/null; do
                sleep 1
            done
        }

        install_update() {
            /bin/rm -rf "$current_app"
            /usr/bin/ditto "$new_app" "$current_app"
            /usr/bin/xattr -dr com.apple.quarantine "$current_app" >/dev/null 2>&1 || true
        }

        wait_for_exit

        destination_dir="$(dirname "$current_app")"

        if [ -w "$destination_dir" ] && { [ ! -e "$current_app" ] || [ -w "$current_app" ]; }; then
            install_update
        else
            export CURRENT_APP="$current_app"
            export NEW_APP="$new_app"
            /usr/bin/osascript <<'APPLESCRIPT'
        on run
            set currentApp to system attribute "CURRENT_APP"
            set newApp to system attribute "NEW_APP"
            do shell script "/bin/rm -rf " & quoted form of currentApp & " && /usr/bin/ditto " & quoted form of newApp & " " & quoted form of currentApp & " && /usr/bin/xattr -dr com.apple.quarantine " & quoted form of currentApp with administrator privileges
        end run
        APPLESCRIPT
        fi

        /usr/bin/open "$current_app"
        /bin/rm -rf "$stage_root"
        """

        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: scriptURL.path
        )

        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/nohup")
        process.arguments = [
            "/bin/zsh",
            scriptURL.path,
            context.currentAppURL.path,
            context.downloadedAppURL.path,
            "\(context.processIdentifier)",
            context.stageRootURL.path
        ]

        let nullHandle = try FileHandle(forWritingTo: URL(filePath: "/dev/null"))
        process.standardOutput = nullHandle
        process.standardError = nullHandle

        do {
            try process.run()
        } catch {
            throw AppUpdateError.installerLaunchFailed(error.localizedDescription)
        }
    }
}

private struct InstallerLaunchContext: Sendable {
    let currentAppURL: URL
    let downloadedAppURL: URL
    let stageRootURL: URL
    let processIdentifier: Int32
}

private struct GitHubReleaseResponse: Decodable {
    let tagName: String
    let htmlURL: URL
    let assets: [GitHubReleaseAsset]

    private enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case assets
    }
}

private struct GitHubReleaseAsset: Decodable {
    let name: String
    let browserDownloadURL: URL

    private enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
    }
}
