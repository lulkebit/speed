import AppKit
import Observation
import SpeedCore
import SwiftUI

struct SpeedMenuPanel: View {
    @Bindable var viewModel: SpeedTestViewModel

    var body: some View {
        ZStack {
            FrostedBackground()

            VStack(alignment: .leading, spacing: 16) {
                header
                summarySurface
                metricsSurface
                footer
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Speed")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(viewModel.statusLine)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            if let lastMeasuredClock = viewModel.lastMeasuredClock {
                Text(lastMeasuredClock)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .glassPill()
            }
        }
    }

    private var summarySurface: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.lastResult != nil ? "Download" : "Status")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)

                    if viewModel.lastResult != nil {
                        HStack(alignment: .lastTextBaseline, spacing: 6) {
                            Text(viewModel.downloadValue)
                                .font(.system(size: 44, weight: .semibold))
                                .foregroundStyle(.primary)

                            Text("Mbps")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text(viewModel.isRunning ? "Test läuft" : "Bereit")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }

                Spacer(minLength: 12)

                summaryBadge
            }

            if let progress = viewModel.estimatedProgress {
                ProgressView(value: progress)
                    .tint(.primary.opacity(0.7))
                    .controlSize(.small)
            }

            Text(viewModel.heroDescription)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            GlassDivider()

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Upload")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)

                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(viewModel.uploadValue)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.primary)

                        Text("Mbps")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Profil")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text(viewModel.qualityValue)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassSection()
    }

    private var summaryBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: viewModel.isRunning ? "waveform.path.ecg" : "gauge.with.needle")

            Text(viewModel.isRunning ? "Live" : viewModel.heroTitle)
                .lineLimit(1)

            if viewModel.isRunning {
                Text("\(viewModel.elapsedSeconds)s")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.secondary)
        .glassPill()
    }

    private var metricsSurface: some View {
        VStack(spacing: 0) {
            MetricRowView(
                title: "Ping",
                value: viewModel.idleLatencyValue,
                unit: "ms",
                icon: "timer",
                note: "Leerlauf"
            )

            GlassDivider()

            MetricRowView(
                title: "Reaktion",
                value: viewModel.responsivenessValue,
                unit: "ms",
                icon: "bolt.badge.clock",
                note: "Apps und Calls"
            )

            GlassDivider()

            MetricRowView(
                title: "Netzwerk",
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
            Button(action: viewModel.handlePrimaryAction) {
                HStack(spacing: 10) {
                    Image(systemName: viewModel.actionSymbol)
                        .font(.system(size: 14, weight: .semibold))

                    Text(viewModel.actionTitle)
                        .font(.system(size: 14, weight: .semibold))

                    Spacer()

                    Text(viewModel.footerCaption)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 15)
                .padding(.vertical, 14)
                .background(
                    Capsule(style: .continuous)
                        .fill(.thinMaterial)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.8)
                )
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Label(viewModel.interfaceLabel, systemImage: "wifi")
                    .lineLimit(1)

                Text("•")

                Text(viewModel.serverLabel)
                    .lineLimit(1)

                Spacer()

                Button("Beenden") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
        }
    }
}
