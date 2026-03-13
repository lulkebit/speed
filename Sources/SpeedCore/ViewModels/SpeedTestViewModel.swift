import Foundation
import Observation

@MainActor
@Observable
public final class SpeedTestViewModel {
    public let localization: SpeedLocalization
    public private(set) var lastResult: SpeedTestResult?
    public private(set) var isRunning = false
    public private(set) var elapsedSeconds = 0

    private var userFacingError: UserFacingError?

    @ObservationIgnored
    private let service: NetworkQualityService

    @ObservationIgnored
    private var testTask: Task<Void, Never>?

    @ObservationIgnored
    private var timerTask: Task<Void, Never>?

    @ObservationIgnored
    private var startedAt: Date?

    public init(
        service: NetworkQualityService = NetworkQualityService(),
        localization: SpeedLocalization = SpeedLocalization()
    ) {
        self.service = service
        self.localization = localization
    }

    public var errorMessage: String? {
        guard let userFacingError else {
            return nil
        }

        let strings = localization.strings

        switch userFacingError {
        case let .networkQuality(error):
            return strings.networkQualityErrorDescription(error)
        case let .raw(message):
            return message
        }
    }

    public var menuBarSymbol: String {
        if isRunning {
            return "arrow.triangle.2.circlepath.circle.fill"
        }

        if errorMessage != nil {
            return "wifi.exclamationmark.circle.fill"
        }

        switch lastResult?.profile {
        case .excellent:
            return "gauge.with.needle.fill"
        case .strong:
            return "gauge.with.needle"
        case .stable:
            return "wifi.circle.fill"
        case .weak:
            return "wifi.exclamationmark"
        case nil:
            return "bolt.horizontal.circle"
        }
    }

    public var statusLine: String {
        let strings = localization.strings

        if isRunning {
            return strings.statusRunning
        }

        if let errorMessage {
            return errorMessage
        }

        if let lastResult {
            return strings.statusLastMeasured(
                profileTitle: lastResult.profile.title(using: strings),
                relative: lastMeasuredRelative ?? strings.justNowHint
            )
        }

        return strings.statusEmpty
    }

    public var actionTitle: String {
        let strings = localization.strings
        return isRunning ? strings.actionCancel : (lastResult == nil ? strings.actionStart : strings.actionRetest)
    }

    public var actionSymbol: String {
        isRunning ? "xmark.circle.fill" : "play.circle.fill"
    }

    public var heroTitle: String {
        let strings = localization.strings

        if isRunning {
            return strings.heroRunning
        }

        if let lastResult {
            return lastResult.profile.headline(using: strings)
        }

        if errorMessage != nil {
            return strings.heroRetry
        }

        return strings.heroReady
    }

    public var heroDescription: String {
        let strings = localization.strings

        if isRunning {
            return strings.heroRunningDescription
        }

        if let lastResult {
            return lastResult.profile.detail(using: strings)
        }

        if let errorMessage {
            return errorMessage
        }

        return strings.heroEmptyDescription
    }

    public var estimatedProgress: Double? {
        guard isRunning else {
            return nil
        }

        return min(Double(elapsedSeconds) / 28, 0.92)
    }

    public var downloadValue: String {
        MetricFormatter.speed(lastResult?.downloadMbps, locale: localization.locale)
    }

    public var uploadValue: String {
        MetricFormatter.speed(lastResult?.uploadMbps, locale: localization.locale)
    }

    public var idleLatencyValue: String {
        MetricFormatter.milliseconds(lastResult?.idleLatencyMs, locale: localization.locale)
    }

    public var responsivenessValue: String {
        MetricFormatter.milliseconds(lastResult?.worstResponsivenessMs, locale: localization.locale)
    }

    public var qualityValue: String {
        let strings = localization.strings
        return lastResult?.profile.title(using: strings) ?? strings.qualityReady
    }

    public var qualityNote: String {
        let strings = localization.strings
        return lastResult?.profile.detail(using: strings) ?? strings.qualityNoMeasurement
    }

    public var interfaceLabel: String {
        guard let interfaceName = lastResult?.interfaceName else {
            return localization.strings.interfaceDefaultLabel
        }

        return interfaceName.uppercased(with: localization.locale)
    }

    public var serverLabel: String {
        guard let serverName = lastResult?.serverName else {
            return localization.strings.serverDefaultLabel
        }

        return serverName.replacingOccurrences(of: ".aaplimg.com", with: "")
    }

    public var footerCaption: String {
        let strings = localization.strings

        if isRunning {
            return strings.footerDuration(seconds: elapsedSeconds)
        }

        if let lastMeasuredRelative {
            return strings.footerLastMeasured(relative: lastMeasuredRelative)
        }

        return strings.footerDefault
    }

    public var lastMeasuredClock: String? {
        MetricFormatter.clockTimestamp(lastResult?.measuredAt, locale: localization.locale)
    }

    public func handlePrimaryAction() {
        isRunning ? cancel() : start()
    }

    public func cancel() {
        guard isRunning else {
            return
        }

        testTask?.cancel()
        service.cancelCurrentTest()
        finishRun()
    }

    public func start() {
        guard !isRunning else {
            return
        }

        userFacingError = nil
        isRunning = true
        elapsedSeconds = 0
        startedAt = Date()

        beginTimer()

        testTask = Task { [weak self] in
            guard let self else {
                return
            }

            do {
                let result = try await self.service.runSequentialTest()
                guard !Task.isCancelled else {
                    return
                }

                self.lastResult = result
                self.userFacingError = nil
            } catch let error as NetworkQualityError {
                if error != .cancelled {
                    self.userFacingError = .networkQuality(error)
                }
            } catch {
                if !Task.isCancelled {
                    self.userFacingError = .raw(error.localizedDescription)
                }
            }

            self.finishRun()
        }
    }

    private var lastMeasuredRelative: String? {
        MetricFormatter.relativeTimestamp(lastResult?.measuredAt, locale: localization.locale)
    }

    private func beginTimer() {
        timerTask?.cancel()

        timerTask = Task { [weak self] in
            guard let self else {
                return
            }

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))

                guard !Task.isCancelled else {
                    return
                }

                if let startedAt = self.startedAt {
                    self.elapsedSeconds = max(Int(Date().timeIntervalSince(startedAt)), 1)
                }
            }
        }
    }

    private func finishRun() {
        isRunning = false
        startedAt = nil
        testTask = nil
        timerTask?.cancel()
        timerTask = nil
    }
}

private enum UserFacingError: Equatable {
    case networkQuality(NetworkQualityError)
    case raw(String)
}
