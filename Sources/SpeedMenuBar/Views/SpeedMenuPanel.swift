import AppKit
import Observation
import SpeedCore
import SwiftUI

struct SpeedMenuPanel: View {
    @Bindable var viewModel: SpeedTestViewModel
    let localization: SpeedLocalization
    let nextAutomaticTestAt: Date?
    let onOpenSettings: () -> Void

    var body: some View {
        ZStack {
            PanelBackground()

            VStack(alignment: .leading, spacing: 0) {
                header

                SubtleDivider()
                    .padding(.vertical, 16)

                hero

                if shouldShowCompactHistory {
                    SubtleDivider()
                        .padding(.vertical, 16)

                    CompactHistoryChartsView(
                        results: viewModel.history,
                        localization: localization
                    )
                }

                SubtleDivider()
                    .padding(.vertical, 16)

                metrics

                SubtleDivider()
                    .padding(.vertical, 16)

                footer
            }
            .padding(18)
        }
        .environment(\.locale, localization.locale)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 8) {
                SubtleBadge(
                    title: headerStateTitle,
                    symbol: headerStateSymbol,
                    tint: headerStateTint
                )

                if let headerDeltaText = viewModel.downloadDeltaText,
                   let headerDeltaTrend = viewModel.downloadDeltaTrend {
                    SubtleBadge(
                        title: headerDeltaText,
                        symbol: downloadDeltaSymbol(for: headerDeltaTrend),
                        tint: downloadDeltaTint(for: headerDeltaTrend)
                    )
                }

                if let headerDetail {
                    Text(headerDetail)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(SpeedChrome.textTertiary)
                        .monospacedDigit()
                }
            }

            Spacer(minLength: 12)

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SpeedChrome.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(SpeedChrome.softFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(SpeedChrome.stroke, lineWidth: 0.8)
                    )
            }
            .buttonStyle(.plain)
            .subtleHover(cornerRadius: 10)
            .help(localization.strings.settingsHelp)
        }
    }

    @ViewBuilder
    private var hero: some View {
        if viewModel.isRunning {
            runningHero
        } else if viewModel.errorMessage != nil {
            messageHero(title: viewModel.heroTitle, detail: viewModel.statusLine)
        } else if viewModel.lastResult != nil {
            measuredHero
        } else {
            messageHero(title: viewModel.heroTitle, detail: viewModel.statusLine)
        }
    }

    private var measuredHero: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.strings.summaryDownloadLabel.uppercased(with: localization.locale))
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(SpeedChrome.textTertiary)
                    .tracking(0.8)

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(viewModel.downloadValue)
                        .font(.system(size: 44, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(SpeedChrome.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("Mbps")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(SpeedChrome.textSecondary)
                }
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 14) {
                heroStat(
                    title: localization.strings.uploadLabel,
                    value: viewModel.uploadValue,
                    unit: "Mbps"
                )

                heroStat(
                    title: localization.strings.metricPingTitle,
                    value: viewModel.idleLatencyValue,
                    unit: "ms"
                )
            }
        }
    }

    private var runningHero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(viewModel.elapsedSeconds)")
                    .font(.system(size: 40, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(SpeedChrome.textPrimary)

                Text("s")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SpeedChrome.textSecondary)
            }

            if let progress = viewModel.estimatedProgress {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(SpeedChrome.brand)
                    .controlSize(.small)
            }

            Text(viewModel.statusLine)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(SpeedChrome.textSecondary)
                .lineLimit(2)
        }
    }

    private func messageHero(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(SpeedChrome.textPrimary)
                .lineLimit(2)

            Text(detail)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(SpeedChrome.textSecondary)
                .lineLimit(2)
        }
    }

    private var metrics: some View {
        VStack(spacing: 0) {
            MetricRowView(
                title: localization.strings.metricPingTitle,
                value: viewModel.idleLatencyValue,
                unit: "ms",
                icon: "timer",
                helpText: localization.strings.metricPingHelp
            )

            SubtleDivider()

            MetricRowView(
                title: localization.strings.metricResponsivenessTitle,
                value: viewModel.responsivenessValue,
                unit: "ms",
                icon: "bolt.badge.clock",
                helpText: localization.strings.metricResponsivenessHelp
            )

            SubtleDivider()

            MetricRowView(
                title: localization.strings.metricNetworkTitle,
                value: viewModel.interfaceLabel,
                unit: "",
                icon: "wifi",
                note: viewModel.serverLabel,
                helpText: localization.strings.metricNetworkHelp
            )
        }
        .zIndex(20)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 12) {
            primaryActionButton

            HStack(alignment: .center, spacing: 12) {
                if let nextAutomaticTestAt {
                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                        Text(nextAutomaticTestCaption(for: nextAutomaticTestAt))
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(SpeedChrome.textTertiary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 12)

                Button(localization.strings.quitButtonTitle) {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(SpeedChrome.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .subtleHover(cornerRadius: 10)
            }
        }
    }

    private var primaryActionButton: some View {
        let tint = primaryActionColor

        return Button(action: viewModel.handlePrimaryAction) {
            HStack(spacing: 10) {
                Image(systemName: viewModel.actionSymbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint)

                Text(viewModel.actionTitle)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(SpeedChrome.textPrimary)

                Spacer()

                Image(systemName: viewModel.isRunning ? "stop.fill" : "arrow.right")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(SpeedChrome.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tint.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(tint.opacity(0.18), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
        .subtleHover(
            cornerRadius: 14,
            fill: tint.opacity(0.14),
            stroke: tint.opacity(0.22)
        )
    }

    private func heroStat(title: String, value: String, unit: String) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(title)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(SpeedChrome.textTertiary)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 18, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(SpeedChrome.textPrimary)

                Text(unit)
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(SpeedChrome.textSecondary)
            }
        }
        .multilineTextAlignment(.trailing)
    }

    private func downloadDeltaSymbol(for trend: MeasurementDeltaTrend) -> String {
        switch trend {
        case .up:
            return "arrow.up.right"
        case .down:
            return "arrow.down.right"
        case .unchanged:
            return "arrow.left.and.right"
        }
    }

    private func downloadDeltaTint(for trend: MeasurementDeltaTrend) -> Color {
        switch trend {
        case .up:
            return .green
        case .down:
            return .orange
        case .unchanged:
            return SpeedChrome.textSecondary
        }
    }

    private var shouldShowCompactHistory: Bool {
        viewModel.history.count >= 2
    }

    private var headerStateTitle: String {
        if viewModel.isRunning {
            return localization.strings.summaryBadgeLive
        }

        if viewModel.errorMessage != nil {
            return localization.strings.heroRetry
        }

        if viewModel.lastResult != nil {
            return viewModel.qualityValue
        }

        return localization.strings.summaryReadyTitle
    }

    private var headerStateSymbol: String {
        if viewModel.isRunning {
            return "waveform.path.ecg"
        }

        if viewModel.errorMessage != nil {
            return "exclamationmark.triangle.fill"
        }

        if viewModel.lastResult != nil {
            return "gauge.with.needle"
        }

        return "checkmark.circle.fill"
    }

    private var headerStateTint: Color {
        if viewModel.isRunning {
            return SpeedChrome.brand
        }

        if viewModel.errorMessage != nil {
            return .orange
        }

        return SpeedChrome.textSecondary
    }

    private var headerDetail: String? {
        if viewModel.isRunning {
            return "\(viewModel.elapsedSeconds)s"
        }

        return viewModel.lastMeasuredClock
    }

    private var primaryActionColor: Color {
        viewModel.isRunning ? .red : SpeedChrome.brand
    }

    private func nextAutomaticTestCaption(for date: Date) -> String {
        let strings = localization.strings
        let relative = MetricFormatter.relativeTimestamp(date, locale: localization.locale)
            ?? strings.laterHint
        return strings.nextAutomaticTestDescription(relative: relative)
    }
}
