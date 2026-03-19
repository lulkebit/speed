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
        self.kind = kind
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
}
