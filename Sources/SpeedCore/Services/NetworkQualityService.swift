import Foundation

@MainActor
public final class NetworkQualityService {
    private var currentProcess: Process?

    public init() {}

    public func runSequentialTest() async throws -> SpeedTestResult {
        guard currentProcess == nil else {
            throw NetworkQualityError.alreadyRunning
        }

        let executableURL = URL(fileURLWithPath: "/usr/bin/networkQuality")
        guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
            throw NetworkQualityError.commandUnavailable
        }

        let process = Process()
        let outputPipe = Pipe()

        process.executableURL = executableURL
        process.arguments = ["-s", "-c"]
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        currentProcess = process

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                process.terminationHandler = { [weak self] process in
                    let data = outputPipe.fileHandleForReading.readDataToEndOfFile()

                    let result: Result<SpeedTestResult, Error>
                    if process.terminationStatus == 0 {
                        result = Result {
                            try NetworkQualityParser.parseSummary(from: data)
                        }
                    } else if process.terminationReason == .uncaughtSignal {
                        result = .failure(NetworkQualityError.cancelled)
                    } else {
                        let message = String(data: data, encoding: .utf8)?
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        result = .failure(
                            NetworkQualityError.executionFailed(
                                message?.isEmpty == false
                                    ? message!
                                    : "Der Speedtest wurde mit Status \(process.terminationStatus) beendet."
                            )
                        )
                    }

                    Task { @MainActor in
                        self?.cleanup()
                        continuation.resume(with: result)
                    }
                }

                do {
                    try process.run()
                } catch {
                    cleanup()
                    continuation.resume(throwing: NetworkQualityError.commandUnavailable)
                }
            }
        } onCancel: { [weak self] in
            Task { @MainActor in
                self?.cancelCurrentTest()
            }
        }
    }

    public func cancelCurrentTest() {
        currentProcess?.terminate()
    }

    private func cleanup() {
        currentProcess = nil
    }
}
