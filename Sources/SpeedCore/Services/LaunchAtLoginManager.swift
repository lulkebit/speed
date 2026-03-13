import Foundation
import ServiceManagement

public enum LaunchAtLoginState: Equatable, Sendable {
    case enabled
    case disabled
    case requiresApproval
    case unsupported

    public var isEnabledForToggle: Bool {
        switch self {
        case .enabled, .requiresApproval:
            true
        case .disabled, .unsupported:
            false
        }
    }
}

public enum LaunchAtLoginError: Error, Equatable, Sendable {
    case requiresBundledApp
    case registrationFailed(String?)
}

@MainActor
public final class LaunchAtLoginManager {
    public init() {}

    public func currentState() -> LaunchAtLoginState {
        guard isBundledApp else {
            return .unsupported
        }

        switch SMAppService.mainApp.status {
        case .enabled:
            return .enabled
        case .requiresApproval:
            return .requiresApproval
        case .notFound, .notRegistered:
            return .disabled
        @unknown default:
            return .disabled
        }
    }

    public func setEnabled(_ enabled: Bool) throws {
        guard isBundledApp else {
            throw LaunchAtLoginError.requiresBundledApp
        }

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            throw LaunchAtLoginError.registrationFailed(error.localizedDescription)
        }
    }

    private var isBundledApp: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }
}
