import Foundation

public final class SpeedHistoryStore {
    private let directoryURL: URL
    private let fileURL: URL
    private let fileManager: FileManager
    private let maxEntries: Int
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        directoryURL: URL? = nil,
        fileManager: FileManager = .default,
        maxEntries: Int = 5_000
    ) {
        let resolvedDirectoryURL: URL
        if let directoryURL {
            resolvedDirectoryURL = directoryURL
        } else if let applicationSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first {
            resolvedDirectoryURL = applicationSupportURL.appendingPathComponent(
                "SpeedMenuBar",
                isDirectory: true
            )
        } else {
            resolvedDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("SpeedMenuBar", isDirectory: true)
        }

        self.directoryURL = resolvedDirectoryURL
        self.fileURL = resolvedDirectoryURL.appendingPathComponent("history.json")
        self.fileManager = fileManager
        self.maxEntries = maxEntries
    }

    public func loadHistory() -> [SpeedTestHistoryEntry] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            if let history = try? decoder.decode([SpeedTestHistoryEntry].self, from: data) {
                return history
            }

            if let legacyHistory = try? decoder.decode([SpeedTestResult].self, from: data) {
                return legacyHistory.map(SpeedTestHistoryEntry.init(result:))
            }

            return []
        } catch {
            return []
        }
    }

    @discardableResult
    public func append(_ result: SpeedTestResult) -> [SpeedTestHistoryEntry] {
        append(SpeedTestHistoryEntry(result: result))
    }

    @discardableResult
    public func append(_ issue: NetworkIssueRecord) -> [SpeedTestHistoryEntry] {
        append(SpeedTestHistoryEntry(issue: issue))
    }

    @discardableResult
    public func append(_ entry: SpeedTestHistoryEntry) -> [SpeedTestHistoryEntry] {
        var history = loadHistory()
        history.append(entry)

        if history.count > maxEntries {
            history.removeFirst(history.count - maxEntries)
        }

        save(history)
        return history
    }

    @discardableResult
    public func removeAll() -> [SpeedTestHistoryEntry] {
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            save([])
        }

        return []
    }

    private func save(_ history: [SpeedTestHistoryEntry]) {
        do {
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
            let data = try encoder.encode(history)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            return
        }
    }
}
