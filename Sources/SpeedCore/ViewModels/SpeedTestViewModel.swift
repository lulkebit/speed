import Foundation
import Observation

@MainActor
@Observable
public final class SpeedTestViewModel {
    public private(set) var lastResult: SpeedTestResult?
    public private(set) var isRunning = false
    public private(set) var elapsedSeconds = 0
    public private(set) var errorMessage: String?

    @ObservationIgnored
    private let service: NetworkQualityService

    @ObservationIgnored
    private var testTask: Task<Void, Never>?

    @ObservationIgnored
    private var timerTask: Task<Void, Never>?

    @ObservationIgnored
    private var startedAt: Date?

    public init(service: NetworkQualityService = NetworkQualityService()) {
        self.service = service
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
        if isRunning {
            return "Download, Upload und Reaktionszeit werden gerade gemessen."
        }

        if let errorMessage {
            return errorMessage
        }

        if let lastResult {
            return "\(lastResult.profile.title) • zuletzt \(lastMeasuredRelative ?? "gerade eben")"
        }

        return "Ein Klick startet den nativen macOS-Speedtest direkt aus der Menüleiste."
    }

    public var actionTitle: String {
        isRunning ? "Abbrechen" : (lastResult == nil ? "Speedtest starten" : "Erneut messen")
    }

    public var actionSymbol: String {
        isRunning ? "xmark.circle.fill" : "play.circle.fill"
    }

    public var heroTitle: String {
        if isRunning {
            return "Messung läuft"
        }

        if let lastResult {
            return lastResult.profile.headline
        }

        if errorMessage != nil {
            return "Noch ein Versuch?"
        }

        return "Bereit für einen schnellen Check"
    }

    public var heroDescription: String {
        if isRunning {
            return "Das dauert meist 20 bis 30 Sekunden. Du kannst das Menü dabei geöffnet lassen."
        }

        if let lastResult {
            return lastResult.profile.detail
        }

        if let errorMessage {
            return errorMessage
        }

        return "Die App nutzt macOS `networkQuality`, um Download, Upload und Reaktionszeit kompakt anzuzeigen."
    }

    public var estimatedProgress: Double? {
        guard isRunning else {
            return nil
        }

        return min(Double(elapsedSeconds) / 28, 0.92)
    }

    public var downloadValue: String {
        MetricFormatter.speed(lastResult?.downloadMbps)
    }

    public var uploadValue: String {
        MetricFormatter.speed(lastResult?.uploadMbps)
    }

    public var idleLatencyValue: String {
        MetricFormatter.milliseconds(lastResult?.idleLatencyMs)
    }

    public var responsivenessValue: String {
        MetricFormatter.milliseconds(lastResult?.worstResponsivenessMs)
    }

    public var qualityValue: String {
        lastResult?.profile.title ?? "Bereit"
    }

    public var qualityNote: String {
        lastResult?.profile.detail ?? "Noch keine Messung vorhanden."
    }

    public var interfaceLabel: String {
        guard let interfaceName = lastResult?.interfaceName else {
            return "Aktives Netzwerk"
        }

        return interfaceName.uppercased()
    }

    public var serverLabel: String {
        guard let serverName = lastResult?.serverName else {
            return "Apple networkQuality"
        }

        return serverName.replacingOccurrences(of: ".aaplimg.com", with: "")
    }

    public var footerCaption: String {
        if isRunning {
            return "Messdauer bisher: \(elapsedSeconds)s"
        }

        if let lastMeasuredRelative {
            return "Zuletzt gemessen \(lastMeasuredRelative)"
        }

        return "Misst mit dem nativen Apple-Netzwerktest"
    }

    public var lastMeasuredClock: String? {
        MetricFormatter.clockTimestamp(lastResult?.measuredAt)
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

        errorMessage = nil
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
                self.errorMessage = nil
            } catch let error as NetworkQualityError {
                if error != .cancelled {
                    self.errorMessage = error.errorDescription
                }
            } catch {
                if !Task.isCancelled {
                    self.errorMessage = error.localizedDescription
                }
            }

            self.finishRun()
        }
    }

    private var lastMeasuredRelative: String? {
        MetricFormatter.relativeTimestamp(lastResult?.measuredAt)
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
