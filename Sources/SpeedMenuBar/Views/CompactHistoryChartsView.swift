import Charts
import SpeedCore
import SwiftUI

struct CompactHistoryChartsView: View {
    let results: [SpeedTestResult]
    let localization: SpeedLocalization

    private var recentHistory: [SpeedTestResult] {
        Array(results.suffix(12))
    }

    private var latestMeasurement: SpeedTestResult? {
        recentHistory.last
    }

    var body: some View {
        Group {
            if recentHistory.count >= 2 {
                VStack(alignment: .leading, spacing: 12) {
                    CompactTrendSection(
                        points: throughputPoints,
                        primaryColor: SpeedChrome.brand,
                        secondaryColor: .green,
                        locale: localization.locale,
                        primaryTitle: localization.strings.historyLegendDownload,
                        secondaryTitle: localization.strings.historyLegendUpload,
                        primaryLegend: MiniMetricLegend(
                            symbol: "arrow.down",
                            value: MetricFormatter.speed(latestMeasurement?.downloadMbps, locale: localization.locale),
                            tint: SpeedChrome.brand
                        ),
                        secondaryLegend: MiniMetricLegend(
                            symbol: "arrow.up",
                            value: MetricFormatter.speed(latestMeasurement?.uploadMbps, locale: localization.locale),
                            tint: .green
                        ),
                        valueFormatter: { value in
                            "\(value.formatted(.number.locale(localization.locale).precision(.fractionLength(1)))) Mbps"
                        }
                    )

                    SubtleDivider()

                    CompactTrendSection(
                        points: latencyPoints,
                        primaryColor: .orange,
                        secondaryColor: .pink,
                        locale: localization.locale,
                        primaryTitle: localization.strings.historyLegendLatency,
                        secondaryTitle: localization.strings.historyLegendResponsiveness,
                        primaryLegend: MiniMetricLegend(
                            symbol: "timer",
                            value: MetricFormatter.milliseconds(latestMeasurement?.idleLatencyMs, locale: localization.locale) + " ms",
                            tint: .orange
                        ),
                        secondaryLegend: MiniMetricLegend(
                            symbol: "bolt",
                            value: MetricFormatter.milliseconds(
                                latestMeasurement?.worstResponsivenessMs,
                                locale: localization.locale
                            ) + " ms",
                            tint: .pink
                        ),
                        valueFormatter: { value in
                            "\(value.formatted(.number.locale(localization.locale).precision(.fractionLength(1)))) ms"
                        }
                    )
                }
            }
        }
    }

    private var throughputPoints: [CompactTrendPoint] {
        recentHistory.map { result in
            CompactTrendPoint(
                measuredAt: result.measuredAt,
                primary: result.downloadMbps,
                secondary: result.uploadMbps
            )
        }
    }

    private var latencyPoints: [CompactTrendPoint] {
        recentHistory.map { result in
            CompactTrendPoint(
                measuredAt: result.measuredAt,
                primary: result.idleLatencyMs,
                secondary: result.worstResponsivenessMs
            )
        }
    }
}

private struct CompactTrendSection: View {
    let points: [CompactTrendPoint]
    let primaryColor: Color
    let secondaryColor: Color
    let locale: Locale
    let primaryTitle: String
    let secondaryTitle: String
    let primaryLegend: MiniMetricLegend
    let secondaryLegend: MiniMetricLegend
    let valueFormatter: (Double) -> String

    @State
    private var selectedPoint: CompactTrendPoint?

    @State
    private var selectedPlotX: CGFloat?

    @State
    private var plotFrame: CGRect = .zero

    @State
    private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                MiniMetricLegendView(legend: primaryLegend)

                Spacer(minLength: 0)

                MiniMetricLegendView(legend: secondaryLegend)
            }

            ZStack(alignment: .topLeading) {
                Chart {
                    ForEach(points) { point in
                        LineMark(
                            x: .value("Time", point.measuredAt),
                            y: .value("Value", point.primary),
                            series: .value("Series", "primary")
                        )
                        .interpolationMethod(.monotone)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .foregroundStyle(primaryColor)
                    }

                    ForEach(points) { point in
                        LineMark(
                            x: .value("Time", point.measuredAt),
                            y: .value("Value", point.secondary),
                            series: .value("Series", "secondary")
                        )
                        .interpolationMethod(.monotone)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .foregroundStyle(secondaryColor.opacity(0.88))
                    }

                    if let selectedPoint {
                        RuleMark(x: .value("Selected", selectedPoint.measuredAt))
                            .foregroundStyle(Color.white.opacity(0.12))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                        PointMark(
                            x: .value("Time", selectedPoint.measuredAt),
                            y: .value("Primary", selectedPoint.primary)
                        )
                        .symbolSize(24)
                        .foregroundStyle(primaryColor)

                        PointMark(
                            x: .value("Time", selectedPoint.measuredAt),
                            y: .value("Secondary", selectedPoint.secondary)
                        )
                        .symbolSize(24)
                        .foregroundStyle(secondaryColor)
                    } else if let lastPoint = points.last {
                        PointMark(
                            x: .value("Time", lastPoint.measuredAt),
                            y: .value("Primary", lastPoint.primary)
                        )
                        .symbolSize(16)
                        .foregroundStyle(primaryColor)

                        PointMark(
                            x: .value("Time", lastPoint.measuredAt),
                            y: .value("Secondary", lastPoint.secondary)
                        )
                        .symbolSize(16)
                        .foregroundStyle(secondaryColor)
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartLegend(.hidden)
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        compactSelectionOverlay(proxy: proxy, geometry: geometry)
                    }
                }
                .chartPlotStyle { plot in
                    plot
                        .background(Color.clear)
                }
                .frame(height: chartHeight)
                .padding(.top, tooltipLaneHeight)

                if isHovering,
                   let selectedPoint,
                   let selectedPlotX,
                   !plotFrame.isEmpty {
                    CompactTrendTooltip(
                        timestamp: selectedPoint.measuredAt.formatted(
                            Date.FormatStyle(date: .omitted, time: .shortened)
                                .locale(locale)
                        ),
                        primaryTitle: primaryTitle,
                        primaryValue: valueFormatter(selectedPoint.primary),
                        primaryColor: primaryColor,
                        secondaryTitle: secondaryTitle,
                        secondaryValue: valueFormatter(selectedPoint.secondary),
                        secondaryColor: secondaryColor
                    )
                    .position(
                        x: preferredTooltipX(for: selectedPlotX, in: plotFrame),
                        y: tooltipLaneHeight * 0.5
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .zIndex(2)
                    .allowsHitTesting(false)
                }
            }
            .frame(height: chartHeight + tooltipLaneHeight)
            .animation(.easeOut(duration: 0.12), value: isHovering)
        }
    }

    private func compactSelectionOverlay(proxy: ChartProxy, geometry: GeometryProxy) -> some View {
        Group {
            if let plotFrameAnchor = proxy.plotFrame {
                let plotFrame = geometry[plotFrameAnchor]

                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .frame(width: plotFrame.width, height: plotFrame.height)
                        .position(x: plotFrame.midX, y: plotFrame.midY)
                        .onContinuousHover { phase in
                            handleHover(phase, proxy: proxy, plotFrame: plotFrame)
                        }
                }
            }
        }
    }

    private func handleHover(
        _ phase: HoverPhase,
        proxy: ChartProxy,
        plotFrame: CGRect
    ) {
        switch phase {
        case let .active(location):
            guard plotFrame.contains(location) else {
                isHovering = false
                selectedPoint = nil
                selectedPlotX = nil
                return
            }

            self.plotFrame = plotFrame
            isHovering = true

            let plotX = location.x - plotFrame.origin.x
            guard let hoveredDate: Date = proxy.value(atX: plotX) else {
                selectedPoint = nil
                selectedPlotX = nil
                return
            }

            let point = nearestPoint(to: hoveredDate)
            selectedPoint = point

            if let point, let snappedPlotX = proxy.position(forX: point.measuredAt) {
                selectedPlotX = plotFrame.minX + snappedPlotX
            } else {
                selectedPlotX = nil
            }
        case .ended:
            isHovering = false
            selectedPoint = nil
            selectedPlotX = nil
        }
    }

    private func nearestPoint(to hoveredDate: Date) -> CompactTrendPoint? {
        points.min { lhs, rhs in
            abs(lhs.measuredAt.timeIntervalSince(hoveredDate))
                < abs(rhs.measuredAt.timeIntervalSince(hoveredDate))
        }
    }

    private func preferredTooltipX(for pointX: CGFloat, in plotFrame: CGRect) -> CGFloat {
        let halfWidth: CGFloat = 76
        let clearance: CGFloat = 28

        if pointX <= plotFrame.midX {
            let tooltipX = pointX + halfWidth + clearance
            return min(tooltipX, plotFrame.maxX - halfWidth)
        } else {
            let tooltipX = pointX - halfWidth - clearance
            return max(tooltipX, plotFrame.minX + halfWidth)
        }
    }

    private var tooltipLaneHeight: CGFloat {
        34
    }

    private var chartHeight: CGFloat {
        56
    }
}

private struct MiniMetricLegend {
    let symbol: String
    let value: String
    let tint: Color
}

private struct MiniMetricLegendView: View {
    let legend: MiniMetricLegend

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: legend.symbol)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(legend.tint)

            Text(legend.value)
                .font(.system(size: 11.5, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(SpeedChrome.textSecondary)
        }
    }
}

private struct CompactTrendTooltip: View {
    let timestamp: String
    let primaryTitle: String
    let primaryValue: String
    let primaryColor: Color
    let secondaryTitle: String
    let secondaryValue: String
    let secondaryColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(timestamp)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(SpeedChrome.textTertiary)

            HStack(spacing: 10) {
                compactRow(title: primaryTitle, value: primaryValue, color: primaryColor)
                compactRow(title: secondaryTitle, value: secondaryValue, color: secondaryColor)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 0.8)
        )
        .shadow(color: .black.opacity(0.14), radius: 10, y: 4)
    }

    private func compactRow(title: String, value: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(SpeedChrome.textTertiary)

                Text(value)
                    .font(.system(size: 11, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(SpeedChrome.textPrimary)
            }
        }
    }
}

private struct CompactTrendPoint: Identifiable {
    let measuredAt: Date
    let primary: Double
    let secondary: Double

    var id: Date {
        measuredAt
    }
}
