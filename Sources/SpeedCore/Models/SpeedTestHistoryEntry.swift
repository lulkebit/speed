import Foundation

public struct SpeedTestHistoryEntry: Codable, Equatable, Identifiable, Sendable {
    public let measuredAt: Date
    public let event: SpeedTestHistoryEvent

    public init(measuredAt: Date, event: SpeedTestHistoryEvent) {
        self.measuredAt = measuredAt
        self.event = event
    }

    public init(result: SpeedTestResult) {
        self.init(measuredAt: result.measuredAt, event: .measurement(result))
    }

    public init(issue: NetworkIssueRecord) {
        self.init(measuredAt: issue.measuredAt, event: .issue(issue))
    }

    public var id: Date {
        measuredAt
    }

    public var result: SpeedTestResult? {
        guard case let .measurement(result) = event else {
            return nil
        }

        return result
    }

    public var issue: NetworkIssueRecord? {
        guard case let .issue(issue) = event else {
            return nil
        }

        return issue
    }
}

public enum SpeedTestHistoryEvent: Codable, Equatable, Sendable {
    case measurement(SpeedTestResult)
    case issue(NetworkIssueRecord)
}

public enum NetworkIssueKind: String, Codable, Equatable, Sendable {
    case timeout
    case internetUnavailable
    case failure

    public var symbolName: String {
        switch self {
        case .timeout:
            return "clock.fill"
        case .internetUnavailable:
            return "wifi.slash"
        case .failure:
            return "exclamationmark.triangle.fill"
        }
    }
}

public struct NetworkIssueRecord: Codable, Equatable, Sendable {
    public let kind: NetworkIssueKind
    public let measuredAt: Date
    public let startedAt: Date
    public let lastObservedAt: Date
    public let occurrenceCount: Int
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
        kind: NetworkIssueKind,
        measuredAt: Date,
        startedAt: Date? = nil,
        lastObservedAt: Date? = nil,
        occurrenceCount: Int = 1,
        message: String?,
        status: Int32?,
        errorDomain: String?,
        errorCode: Int?,
        durationSeconds: Int?,
        interfaceName: String?,
        serverName: String?,
        pathStatus: String?,
        activeInterfaceNames: [String],
        activeInterfaceKinds: [String]
    ) {
        let normalizedStartedAt = startedAt ?? measuredAt
        let normalizedLastObservedAt = lastObservedAt ?? measuredAt

        self.kind = kind
        self.measuredAt = normalizedLastObservedAt
        self.startedAt = normalizedStartedAt
        self.lastObservedAt = normalizedLastObservedAt
        self.occurrenceCount = max(occurrenceCount, 1)
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

    public init(error: NetworkQualityError, measuredAt fallbackMeasuredAt: Date = Date()) {
        let issueKind: NetworkIssueKind
        let context: NetworkQualityFailureContext?

        switch error {
        case let .timedOut(failureContext):
            issueKind = .timeout
            context = failureContext
        case let .internetUnavailable(failureContext):
            issueKind = .internetUnavailable
            context = failureContext
        case let .executionFailed(failureContext):
            issueKind = .failure
            context = failureContext
        case .alreadyRunning, .commandUnavailable, .noOutput, .invalidOutput:
            issueKind = .failure
            context = nil
        case .cancelled:
            issueKind = .failure
            context = nil
        }

        self.init(
            kind: issueKind,
            measuredAt: context?.measuredAt ?? fallbackMeasuredAt,
            message: context?.message,
            status: context?.status,
            errorDomain: context?.errorDomain,
            errorCode: context?.errorCode,
            durationSeconds: context?.durationSeconds,
            interfaceName: context?.interfaceName,
            serverName: context?.serverName,
            pathStatus: context?.pathStatus,
            activeInterfaceNames: context?.activeInterfaceNames ?? [],
            activeInterfaceKinds: context?.activeInterfaceKinds ?? []
        )
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let measuredAt = try container.decode(Date.self, forKey: .measuredAt)

        try self.init(
            kind: container.decode(NetworkIssueKind.self, forKey: .kind),
            measuredAt: measuredAt,
            startedAt: try container.decodeIfPresent(Date.self, forKey: .startedAt) ?? measuredAt,
            lastObservedAt: try container.decodeIfPresent(Date.self, forKey: .lastObservedAt) ?? measuredAt,
            occurrenceCount: try container.decodeIfPresent(Int.self, forKey: .occurrenceCount) ?? 1,
            message: try container.decodeIfPresent(String.self, forKey: .message),
            status: try container.decodeIfPresent(Int32.self, forKey: .status),
            errorDomain: try container.decodeIfPresent(String.self, forKey: .errorDomain),
            errorCode: try container.decodeIfPresent(Int.self, forKey: .errorCode),
            durationSeconds: try container.decodeIfPresent(Int.self, forKey: .durationSeconds),
            interfaceName: try container.decodeIfPresent(String.self, forKey: .interfaceName),
            serverName: try container.decodeIfPresent(String.self, forKey: .serverName),
            pathStatus: try container.decodeIfPresent(String.self, forKey: .pathStatus),
            activeInterfaceNames: try container.decodeIfPresent([String].self, forKey: .activeInterfaceNames) ?? [],
            activeInterfaceKinds: try container.decodeIfPresent([String].self, forKey: .activeInterfaceKinds) ?? []
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(kind, forKey: .kind)
        try container.encode(measuredAt, forKey: .measuredAt)
        try container.encode(startedAt, forKey: .startedAt)
        try container.encode(lastObservedAt, forKey: .lastObservedAt)
        try container.encode(occurrenceCount, forKey: .occurrenceCount)
        try container.encodeIfPresent(message, forKey: .message)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(errorDomain, forKey: .errorDomain)
        try container.encodeIfPresent(errorCode, forKey: .errorCode)
        try container.encodeIfPresent(durationSeconds, forKey: .durationSeconds)
        try container.encodeIfPresent(interfaceName, forKey: .interfaceName)
        try container.encodeIfPresent(serverName, forKey: .serverName)
        try container.encodeIfPresent(pathStatus, forKey: .pathStatus)
        try container.encode(activeInterfaceNames, forKey: .activeInterfaceNames)
        try container.encode(activeInterfaceKinds, forKey: .activeInterfaceKinds)
    }

    public func title(using strings: SpeedStrings) -> String {
        strings.networkIssueTitle(kind)
    }

    public func pathStatusTitle(using strings: SpeedStrings) -> String? {
        guard let pathStatus, !pathStatus.isEmpty else {
            return nil
        }

        return strings.networkPathStatusTitle(pathStatus)
    }

    public var normalizedServerName: String? {
        guard let serverName, !serverName.isEmpty else {
            return nil
        }

        return serverName.replacingOccurrences(of: ".aaplimg.com", with: "")
    }

    public var diagnosticCode: String? {
        switch (errorDomain, errorCode) {
        case let (errorDomain?, errorCode?):
            return "\(errorDomain) (\(errorCode))"
        case let (errorDomain?, nil):
            return errorDomain
        case let (nil, errorCode?):
            return String(errorCode)
        case (nil, nil):
            return nil
        }
    }

    public var interfaceSummary: String? {
        let names = activeInterfaceNames.isEmpty
            ? (interfaceName.map { [$0] } ?? [])
            : activeInterfaceNames
        let kinds = activeInterfaceKinds

        guard !names.isEmpty else {
            return nil
        }

        if names.count == kinds.count, !kinds.isEmpty {
            return zip(names, kinds)
                .map { name, kind in
                    "\(name) (\(kind))"
                }
                .joined(separator: ", ")
        }

        return names.joined(separator: ", ")
    }

    public var coversMultipleEvents: Bool {
        occurrenceCount > 1 || startedAt != lastObservedAt
    }

    public var disturbanceDurationSeconds: Int? {
        let spanSeconds = max(Int(lastObservedAt.timeIntervalSince(startedAt).rounded()), 0)
        let testDurationSeconds = durationSeconds ?? 0
        let totalSeconds = max(spanSeconds + testDurationSeconds, testDurationSeconds)
        return totalSeconds > 0 ? totalSeconds : nil
    }

    public func merged(with next: NetworkIssueRecord) -> NetworkIssueRecord {
        NetworkIssueRecord(
            kind: Self.preferredKind(between: kind, and: next.kind),
            measuredAt: next.lastObservedAt,
            startedAt: min(startedAt, next.startedAt),
            lastObservedAt: max(lastObservedAt, next.lastObservedAt),
            occurrenceCount: occurrenceCount + next.occurrenceCount,
            message: next.message ?? message,
            status: next.status ?? status,
            errorDomain: next.errorDomain ?? errorDomain,
            errorCode: next.errorCode ?? errorCode,
            durationSeconds: next.durationSeconds ?? durationSeconds,
            interfaceName: next.interfaceName ?? interfaceName,
            serverName: next.serverName ?? serverName,
            pathStatus: next.pathStatus ?? pathStatus,
            activeInterfaceNames: next.activeInterfaceNames.isEmpty
                ? activeInterfaceNames
                : next.activeInterfaceNames,
            activeInterfaceKinds: next.activeInterfaceKinds.isEmpty
                ? activeInterfaceKinds
                : next.activeInterfaceKinds
        )
    }

    public func shouldMerge(
        with next: NetworkIssueRecord,
        maximumGap: TimeInterval = 10_800
    ) -> Bool {
        next.startedAt.timeIntervalSince(lastObservedAt) <= maximumGap
    }

    private static func preferredKind(
        between first: NetworkIssueKind,
        and second: NetworkIssueKind
    ) -> NetworkIssueKind {
        let rankedKinds: [NetworkIssueKind] = [.internetUnavailable, .timeout, .failure]
        return rankedKinds.first(where: { $0 == first || $0 == second }) ?? second
    }

    private enum CodingKeys: String, CodingKey {
        case kind
        case measuredAt
        case startedAt
        case lastObservedAt
        case occurrenceCount
        case message
        case status
        case errorDomain
        case errorCode
        case durationSeconds
        case interfaceName
        case serverName
        case pathStatus
        case activeInterfaceNames
        case activeInterfaceKinds
    }
}
