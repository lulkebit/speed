import AppKit
import Observation
import SpeedCore
import SwiftUI

struct SpeedMenuPanel: View {
    @Bindable var viewModel: SpeedTestViewModel
    let localization: SpeedLocalization
    let onOpenSettings: () -> Void

    var body: some View {
        ZStack {
            FrostedBackground()

            VStack(alignment: .leading, spacing: 14) {
                header
                summarySurface
                metricsSurface
                footer
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: SpeedChrome.panelCornerRadius, style: .continuous))
        .environment(\.locale, localization.locale)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(localization.strings.appName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(viewModel.statusLine)
                    .font(.system(size: 12.5, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 8) {
                if let lastMeasuredClock = viewModel.lastMeasuredClock, viewModel.lastResult != nil {
                    Text(lastMeasuredClock)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .glassPill()
                }

                Button {
                    onOpenSettings()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(.thinMaterial)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.8)
                        )
                }
                .buttonStyle(.plain)
                .help(localization.strings.settingsHelp)
            }
        }
    }

    private var summarySurface: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(summaryEyebrow)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .tracking(0.8)

                    summaryHeadline
                }

                Spacer(minLength: 12)

                summaryBadge
            }

            if let progress = viewModel.estimatedProgress {
                ProgressView(value: progress)
                    .tint(SpeedChrome.brand.opacity(0.85))
                    .controlSize(.small)
            }

            Text(viewModel.heroDescription)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            GlassDivider()

            HStack(spacing: 16) {
                summaryMetric(
                    title: localization.strings.uploadLabel,
                    value: viewModel.uploadValue,
                    unit: "Mbps",
                    alignment: .leading
                )

                summaryMetric(
                    title: localization.strings.profileLabel,
                    value: viewModel.qualityValue,
                    alignment: .trailing
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassSection(prominence: .prominent)
    }

    private var summaryBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: summaryBadgeSymbol)

            Text(summaryBadgeTitle)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            if let summaryBadgeDetail {
                Text(summaryBadgeDetail)
                    .foregroundStyle(summaryBadgeDetailColor)
            }
        }
        .font(.system(size: 11.5, weight: .semibold))
        .foregroundStyle(summaryBadgeColor)
        .glassPill()
    }

    private var metricsSurface: some View {
        VStack(spacing: 0) {
            MetricRowView(
                title: localization.strings.metricPingTitle,
                value: viewModel.idleLatencyValue,
                unit: "ms",
                icon: "timer",
                note: localization.strings.metricPingNote
            )

            GlassDivider()

            MetricRowView(
                title: localization.strings.metricResponsivenessTitle,
                value: viewModel.responsivenessValue,
                unit: "ms",
                icon: "bolt.badge.clock",
                note: localization.strings.metricResponsivenessNote
            )

            GlassDivider()

            MetricRowView(
                title: localization.strings.metricNetworkTitle,
                value: viewModel.interfaceLabel,
                unit: "",
                icon: "wifi",
                note: viewModel.serverLabel
            )
        }
        .glassSection()
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 12) {
            primaryActionButton

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Label(viewModel.interfaceLabel, systemImage: "wifi")
                        .lineLimit(1)

                    Text(viewModel.serverLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                Spacer()

                Button(localization.strings.quitButtonTitle) {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var summaryHeadline: some View {
        if viewModel.lastResult != nil {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(viewModel.downloadValue)
                    .font(.system(size: 46, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text("Mbps")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        } else {
            Text(viewModel.heroTitle)
                .font(.system(size: 29, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var summaryEyebrow: String {
        viewModel.lastResult != nil
            ? localization.strings.summaryDownloadLabel.uppercased(with: localization.locale)
            : localization.strings.summaryStatusLabel.uppercased(with: localization.locale)
    }

    private var summaryBadgeTitle: String {
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

    private var summaryBadgeDetail: String? {
        if viewModel.isRunning {
            return "\(viewModel.elapsedSeconds)s"
        }

        return viewModel.lastMeasuredClock
    }

    private var summaryBadgeSymbol: String {
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

    private var summaryBadgeColor: Color {
        if viewModel.isRunning {
            return SpeedChrome.brand
        }

        if viewModel.errorMessage != nil {
            return .orange
        }

        return .secondary
    }

    private var summaryBadgeDetailColor: Color {
        summaryBadgeColor.opacity(0.78)
    }

    private var primaryActionButton: some View {
        Button(action: viewModel.handlePrimaryAction) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.16))

                    Image(systemName: viewModel.actionSymbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.actionTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(viewModel.footerCaption)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.82))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer()

                Image(systemName: viewModel.isRunning ? "xmark" : "arrow.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.86))
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                primaryActionColor.opacity(0.88),
                                primaryActionColor
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8)
            )
            .shadow(color: primaryActionColor.opacity(0.22), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var primaryActionColor: Color {
        viewModel.isRunning ? .red : SpeedChrome.brand
    }

    private func summaryMetric(
        title: String,
        value: String,
        unit: String? = nil,
        alignment: HorizontalAlignment
    ) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: unit == nil ? 18 : 22, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                if let unit {
                    Text(unit)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: alignment == .leading ? .leading : .trailing
            )
        }
        .frame(
            maxWidth: .infinity,
            alignment: alignment == .leading ? .leading : .trailing
        )
        .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
    }
}
