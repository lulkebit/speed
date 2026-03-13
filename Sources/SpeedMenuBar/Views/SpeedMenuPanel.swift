import AppKit
import Observation
import SpeedCore
import SwiftUI

struct SpeedMenuPanel: View {
    @Bindable var viewModel: SpeedTestViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    SpeedPalette.sand,
                    Color(red: 0.98, green: 0.84, blue: 0.76),
                    SpeedPalette.mint
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(SpeedPalette.coral.opacity(0.18))
                    .frame(width: 170, height: 170)
                    .offset(x: 54, y: -74)
            }
            .overlay(alignment: .bottomLeading) {
                Circle()
                    .fill(SpeedPalette.accentSoft.opacity(0.82))
                    .frame(width: 220, height: 220)
                    .offset(x: -88, y: 104)
            }

            VStack(alignment: .leading, spacing: 16) {
                header
                heroCard
                metricGrid
                footer
            }
            .padding(18)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Speed")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(SpeedPalette.primaryText)

                Text(viewModel.statusLine)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(SpeedPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            if let lastMeasuredClock = viewModel.lastMeasuredClock {
                Text(lastMeasuredClock)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(SpeedPalette.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.74))
                    )
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(viewModel.heroTitle, systemImage: viewModel.isRunning ? "waveform.path.ecg" : "gauge.with.needle")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(SpeedPalette.secondaryText)

                Spacer()

                if viewModel.isRunning {
                    Text("\(viewModel.elapsedSeconds)s")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(SpeedPalette.accent)
                }
            }

            if viewModel.lastResult != nil {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text(viewModel.downloadValue)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(SpeedPalette.primaryText)

                        Text("Mbps")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(SpeedPalette.secondaryText)
                    }

                    Text("Download")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(SpeedPalette.secondaryText)
                }
            } else {
                Text(viewModel.isRunning ? "Wir sammeln gerade Messwerte." : "Noch keine Messung")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(SpeedPalette.primaryText)
            }

            Text(viewModel.heroDescription)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(SpeedPalette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            if let progress = viewModel.estimatedProgress {
                ProgressView(value: progress)
                    .tint(SpeedPalette.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.95), lineWidth: 1)
        )
    }

    private var metricGrid: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                MetricCardView(
                    title: "Upload",
                    value: viewModel.uploadValue,
                    unit: "Mbps",
                    icon: "arrow.up.right.circle",
                    note: "Senden"
                )

                MetricCardView(
                    title: "Ping",
                    value: viewModel.idleLatencyValue,
                    unit: "ms",
                    icon: "timer",
                    note: "Leerlauf"
                )
            }

            HStack(spacing: 10) {
                MetricCardView(
                    title: "Reaktion",
                    value: viewModel.responsivenessValue,
                    unit: "ms",
                    icon: "bolt.badge.clock",
                    note: "Apps & Calls"
                )

                MetricCardView(
                    title: "Profil",
                    value: viewModel.qualityValue,
                    unit: "",
                    icon: "sparkles",
                    note: viewModel.qualityNote
                )
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: viewModel.handlePrimaryAction) {
                HStack(spacing: 10) {
                    Image(systemName: viewModel.actionSymbol)
                        .font(.system(size: 14, weight: .bold))

                    Text(viewModel.actionTitle)
                        .font(.system(size: 14, weight: .bold, design: .rounded))

                    Spacer()

                    Text(viewModel.footerCaption)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .opacity(0.82)
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 15)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    SpeedPalette.accent,
                                    Color(red: 0.10, green: 0.53, blue: 0.56)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
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
                .foregroundStyle(SpeedPalette.accent)
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(SpeedPalette.secondaryText)
        }
    }
}
