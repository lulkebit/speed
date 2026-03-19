import Foundation
import Network

@MainActor
public final class NetworkQualityService {
    private var currentProcess: Process?
    private let maximumRuntimeSeconds: Int
    private let pathMonitor: NWPathMonitor
    private let pathMonitorQueue: DispatchQueue
    private var latestPathSnapshot: NetworkPathSnapshot?

    public init(
        maximumRuntimeSeconds: Int = 35,
        pathMonitor: NWPathMonitor = NWPathMonitor(),
        pathMonitorQueue: DispatchQueue = DispatchQueue(
            label: "SpeedMenuBar.NetworkQualityService.PathMonitor"
        )
    ) {
        self.maximumRuntimeSeconds = maximumRuntimeSeconds
        self.pathMonitor = pathMonitor
        self.pathMonitorQueue = pathMonitorQueue
        startPathMonitor()
    }

    deinit {
        pathMonitor.cancel()
    }

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
        process.arguments = ["-s", "-c", "-M", "\(maximumRuntimeSeconds)"]
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        currentProcess = process

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let executionState = ProcessExecutionState()

                let finish: @Sendable (Result<SpeedTestResult, Error>) -> Void = { result in
                    guard executionState.beginFinishing() else {
                        return
                    }

                    executionState.cancelWatchdog()

                    Task { @MainActor in
                        self.cleanup()
                        continuation.resume(with: result)
                    }
                }

                process.terminationHandler = { [weak self] process in
                    let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    let didHitWatchdogTimeout = executionState.didHitWatchdogTimeout
                    let terminationStatus = process.terminationStatus
                    let terminationReason = process.terminationReason

                    Task { @MainActor [weak self] in
                        let rawMessage = Self.fallbackMessage(from: data)
                        let result: Result<SpeedTestResult, Error>

                        if didHitWatchdogTimeout {
                            let context = self?.makeFailureContext(
                                measuredAt: Date(),
                                message: rawMessage,
                                status: terminationStatus
                            ) ?? NetworkQualityFailureContext(
                                measuredAt: Date(),
                                message: rawMessage,
                                status: Self.normalizedProcessStatus(terminationStatus)
                            )
                            result = .failure(NetworkQualityError.timedOut(context))
                        } else if terminationReason == .uncaughtSignal {
                            result = .failure(NetworkQualityError.cancelled)
                        } else {
                            result = Result {
                                try self?.parseProcessOutput(
                                    data: data,
                                    rawMessage: rawMessage,
                                    status: terminationStatus
                                ) ?? {
                                    throw NetworkQualityError.commandUnavailable
                                }()
                            }
                        }

                        finish(result)
                    }
                }

                do {
                    try process.run()
                    executionState.watchdogTask = Task {
                        do {
                            try await Task.sleep(
                                for: .seconds(Double(maximumRuntimeSeconds) + 5)
                            )
                        } catch {
                            return
                        }

                        guard process.isRunning else {
                            return
                        }

                        executionState.didHitWatchdogTimeout = true
                        process.terminate()
                    }
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

    private func startPathMonitor() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            let snapshot = NetworkPathSnapshot.make(from: path)

            Task { @MainActor [weak self] in
                self?.latestPathSnapshot = snapshot
            }
        }
        pathMonitor.start(queue: pathMonitorQueue)
    }

    private func parseProcessOutput(
        data: Data,
        rawMessage: String?,
        status: Int32
    ) throws -> SpeedTestResult {
        do {
            switch try NetworkQualityParser.parseOutput(
                from: data,
                maximumRuntime: TimeInterval(maximumRuntimeSeconds)
            ) {
            case let .success(result):
                return result
            case let .failure(parsedFailure):
                let enrichedContext = parsedFailure.context.with(
                    status: Self.normalizedProcessStatus(status),
                    pathStatus: latestPathSnapshot?.status,
                    activeInterfaceNames: latestPathSnapshot?.activeInterfaceNames,
                    activeInterfaceKinds: latestPathSnapshot?.activeInterfaceKinds
                )
                throw error(for: parsedFailure.kind, context: enrichedContext)
            }
        } catch let error as NetworkQualityError {
            switch error {
            case .invalidOutput:
                if rawMessage != nil || status != 0 {
                    let context = makeFailureContext(
                        measuredAt: Date(),
                        message: rawMessage,
                        status: status
                    )
                    throw NetworkQualityError.executionFailed(context)
                }

                throw error
            default:
                throw error
            }
        }
    }

    private func error(
        for kind: NetworkIssueKind,
        context: NetworkQualityFailureContext
    ) -> NetworkQualityError {
        switch kind {
        case .timeout:
            return .timedOut(context)
        case .internetUnavailable:
            return .internetUnavailable(context)
        case .failure:
            return .executionFailed(context)
        }
    }

    private func makeFailureContext(
        measuredAt: Date,
        message: String?,
        status: Int32
    ) -> NetworkQualityFailureContext {
        NetworkQualityFailureContext(
            measuredAt: measuredAt,
            message: message,
            status: Self.normalizedProcessStatus(status),
            pathStatus: latestPathSnapshot?.status,
            activeInterfaceNames: latestPathSnapshot?.activeInterfaceNames ?? [],
            activeInterfaceKinds: latestPathSnapshot?.activeInterfaceKinds ?? []
        )
    }

    private nonisolated static func normalizedProcessStatus(_ status: Int32) -> Int32? {
        status == 0 ? nil : status
    }

    private nonisolated static func fallbackMessage(from data: Data) -> String? {
        guard let rawText = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !rawText.isEmpty,
              !rawText.hasPrefix("{") else {
            return nil
        }

        return rawText
    }

    private func cleanup() {
        currentProcess = nil
    }
}

private final class ProcessExecutionState: @unchecked Sendable {
    private let lock = NSLock()
    private var hasStartedFinishing = false
    private var _didHitWatchdogTimeout = false
    private var _watchdogTask: Task<Void, Never>?

    var didHitWatchdogTimeout: Bool {
        get {
            lock.withLock {
                _didHitWatchdogTimeout
            }
        }
        set {
            lock.withLock {
                _didHitWatchdogTimeout = newValue
            }
        }
    }

    var watchdogTask: Task<Void, Never>? {
        get {
            lock.withLock {
                _watchdogTask
            }
        }
        set {
            lock.withLock {
                _watchdogTask = newValue
            }
        }
    }

    func beginFinishing() -> Bool {
        lock.withLock {
            guard !hasStartedFinishing else {
                return false
            }

            hasStartedFinishing = true
            return true
        }
    }

    func cancelWatchdog() {
        let task = lock.withLock { () -> Task<Void, Never>? in
            let task = _watchdogTask
            _watchdogTask = nil
            return task
        }
        task?.cancel()
    }
}

private struct NetworkPathSnapshot: Sendable {
    let status: String
    let activeInterfaceNames: [String]
    let activeInterfaceKinds: [String]

    static func make(from path: NWPath) -> Self {
        let activeInterfaces = path.availableInterfaces.filter { path.usesInterfaceType($0.type) }

        return Self(
            status: path.status.debugName,
            activeInterfaceNames: activeInterfaces.map(\.name).sorted(),
            activeInterfaceKinds: activeInterfaces.map { $0.type.debugName }.sorted()
        )
    }
}

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}

private extension NWPath.Status {
    var debugName: String {
        switch self {
        case .satisfied:
            return "satisfied"
        case .requiresConnection:
            return "requiresConnection"
        case .unsatisfied:
            return "unsatisfied"
        @unknown default:
            return "unknown"
        }
    }
}

private extension NWInterface.InterfaceType {
    var debugName: String {
        switch self {
        case .cellular:
            return "cellular"
        case .loopback:
            return "loopback"
        case .other:
            return "other"
        case .wifi:
            return "wifi"
        case .wiredEthernet:
            return "ethernet"
        @unknown default:
            return "unknown"
        }
    }
}
