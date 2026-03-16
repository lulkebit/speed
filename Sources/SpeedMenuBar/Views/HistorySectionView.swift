import Charts
import Observation
import SpeedCore
import SwiftUI

struct HistorySectionView: View {
    @Bindable var viewModel: SpeedTestViewModel
    let localization: SpeedLocalization

    @State
    private var selectedRange: HistoryTimeRange = .day

    @State
    private var selectedMeasurement: SpeedTestResult?

    @State
    private var activeChart: HistoryChartKind?

    private var strings: SpeedStrings {
        localization.strings
    }

    private var chartDomain: ClosedRange<Date> {
        selectedRange.chartDomain()
    }

    private var filteredHistory: [SpeedTestResult] {
        viewModel.history.filter { chartDomain.contains($0.measuredAt) }
    }

    private var recentMeasurements: [SpeedTestResult] {
        Array(filteredHistory.suffix(4).reversed())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 16) {
                Picker(strings.historyRangeLabel, selection: $selectedRange) {
                    ForEach(HistoryTimeRange.allCases) { range in
                        Text(range.title(using: strings))
                            .tag(range)
                    }
                }
                .pickerStyle(.segmented)

                if !filteredHistory.isEmpty {
                    Text(strings.historyMeasurementsDescription(count: filteredHistory.count))
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(SpeedChrome.textTertiary)
                        .lineLimit(1)
                }
            }

            if filteredHistory.isEmpty {
                SubtleDivider()
                    .padding(.vertical, 16)

                emptyState
            } else {
                SubtleDivider()
                    .padding(.vertical, 16)

                throughputChartSection

                SubtleDivider()
                    .padding(.vertical, 16)

                latencyChartSection

                if !recentMeasurements.isEmpty {
                    SubtleDivider()
                        .padding(.vertical, 16)

                    recentMeasurementsSection
                }
            }
        }
        .padding(.vertical, 4)
        .onChange(of: selectedRange) { _, _ in
            clearSelection()
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(strings.historyEmptyTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SpeedChrome.textPrimary)

            Text(strings.historyEmptyDescription)
                .font(.system(size: 12))
                .foregroundStyle(SpeedChrome.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var throughputChartSection: some View {
        chartSection(
            title: strings.historyChartThroughputTitle,
            legends: [
                HistoryLegendItem(title: strings.historyLegendDownload, color: SpeedChrome.brand),
                HistoryLegendItem(title: strings.historyLegendUpload, color: .green)
            ]
        ) {
            Chart {
                ForEach(filteredHistory) { result in
                    LineMark(
                        x: .value("Time", result.measuredAt),
                        y: .value(strings.historyLegendDownload, result.downloadMbps),
                        series: .value("Series", strings.historyLegendDownload)
                    )
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(SpeedChrome.brand)

                    PointMark(
                        x: .value("Time", result.measuredAt),
                        y: .value(strings.historyLegendDownload, result.downloadMbps)
                    )
                    .symbolSize(14)
                    .foregroundStyle(SpeedChrome.brand.opacity(0.35))

                    LineMark(
                        x: .value("Time", result.measuredAt),
                        y: .value(strings.historyLegendUpload, result.uploadMbps),
                        series: .value("Series", strings.historyLegendUpload)
                    )
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(.green)

                    PointMark(
                        x: .value("Time", result.measuredAt),
                        y: .value(strings.historyLegendUpload, result.uploadMbps)
                    )
                    .symbolSize(14)
                    .foregroundStyle(Color.green.opacity(0.35))
                }

                if let selectedMeasurement {
                    RuleMark(x: .value("Selected time", selectedMeasurement.measuredAt))
                        .foregroundStyle(SpeedChrome.textTertiary.opacity(0.55))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                    PointMark(
                        x: .value("Time", selectedMeasurement.measuredAt),
                        y: .value(strings.historyLegendDownload, selectedMeasurement.downloadMbps)
                    )
                    .symbolSize(42)
                    .foregroundStyle(SpeedChrome.brand)

                    PointMark(
                        x: .value("Time", selectedMeasurement.measuredAt),
                        y: .value(strings.historyLegendUpload, selectedMeasurement.uploadMbps)
                    )
                    .symbolSize(42)
                    .foregroundStyle(.green)
                }
            }
            .chartLegend(.hidden)
            .chartForegroundStyleScale([
                strings.historyLegendDownload: SpeedChrome.brand,
                strings.historyLegendUpload: Color.green
            ])
            .chartXScale(domain: chartDomain)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: axisDesiredCount)) {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.7))
                        .foregroundStyle(SpeedChrome.divider)
                    AxisTick(stroke: StrokeStyle(lineWidth: 0.7))
                        .foregroundStyle(SpeedChrome.textTertiary)
                    AxisValueLabel(format: selectedRange.axisFormatStyle(locale: localization.locale))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.7))
                        .foregroundStyle(SpeedChrome.divider)
                    AxisTick(stroke: StrokeStyle(lineWidth: 0.7))
                        .foregroundStyle(SpeedChrome.textTertiary)
                    AxisValueLabel()
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    selectionOverlay(proxy: proxy, geometry: geometry, chart: .throughput) {
                        throughputTooltip
                    }
                }
            }
            .frame(height: 154)
        }
    }

    private var latencyChartSection: some View {
        chartSection(
            title: strings.historyChartLatencyTitle,
            legends: [
                HistoryLegendItem(title: strings.historyLegendLatency, color: .orange),
                HistoryLegendItem(title: strings.historyLegendResponsiveness, color: .pink)
            ]
        ) {
            Chart {
                ForEach(filteredHistory) { result in
                    LineMark(
                        x: .value("Time", result.measuredAt),
                        y: .value(strings.historyLegendLatency, result.idleLatencyMs),
                        series: .value("Series", strings.historyLegendLatency)
                    )
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(.orange)

                    PointMark(
                        x: .value("Time", result.measuredAt),
                        y: .value(strings.historyLegendLatency, result.idleLatencyMs)
                    )
                    .symbolSize(14)
                    .foregroundStyle(Color.orange.opacity(0.35))

                    LineMark(
                        x: .value("Time", result.measuredAt),
                        y: .value(strings.historyLegendResponsiveness, result.worstResponsivenessMs),
                        series: .value("Series", strings.historyLegendResponsiveness)
                    )
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(.pink)

                    PointMark(
                        x: .value("Time", result.measuredAt),
                        y: .value(strings.historyLegendResponsiveness, result.worstResponsivenessMs)
                    )
                    .symbolSize(14)
                    .foregroundStyle(Color.pink.opacity(0.35))
                }

                if let selectedMeasurement {
                    RuleMark(x: .value("Selected time", selectedMeasurement.measuredAt))
                        .foregroundStyle(SpeedChrome.textTertiary.opacity(0.55))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                    PointMark(
                        x: .value("Time", selectedMeasurement.measuredAt),
                        y: .value(strings.historyLegendLatency, selectedMeasurement.idleLatencyMs)
                    )
                    .symbolSize(42)
                    .foregroundStyle(.orange)

                    PointMark(
                        x: .value("Time", selectedMeasurement.measuredAt),
                        y: .value(
                            strings.historyLegendResponsiveness,
                            selectedMeasurement.worstResponsivenessMs
                        )
                    )
                    .symbolSize(42)
                    .foregroundStyle(.pink)
                }
            }
            .chartLegend(.hidden)
            .chartForegroundStyleScale([
                strings.historyLegendLatency: Color.orange,
                strings.historyLegendResponsiveness: Color.pink
            ])
            .chartXScale(domain: chartDomain)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: axisDesiredCount)) {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.7))
                        .foregroundStyle(SpeedChrome.divider)
                    AxisTick(stroke: StrokeStyle(lineWidth: 0.7))
                        .foregroundStyle(SpeedChrome.textTertiary)
                    AxisValueLabel(format: selectedRange.axisFormatStyle(locale: localization.locale))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.7))
                        .foregroundStyle(SpeedChrome.divider)
                    AxisTick(stroke: StrokeStyle(lineWidth: 0.7))
                        .foregroundStyle(SpeedChrome.textTertiary)
                    AxisValueLabel()
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    selectionOverlay(proxy: proxy, geometry: geometry, chart: .latency) {
                        latencyTooltip
                    }
                }
            }
            .frame(height: 154)
        }
    }

    private var recentMeasurementsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(strings.historyRecentMeasurementsTitle)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(SpeedChrome.textPrimary)

            ForEach(Array(recentMeasurements.enumerated()), id: \.element.id) { index, result in
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(timestampLabel(for: result.measuredAt))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(SpeedChrome.textPrimary)

                        Text(result.interfaceName.uppercased(with: localization.locale))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(SpeedChrome.textTertiary)
                    }

                    Spacer(minLength: 12)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(
                            "\(MetricFormatter.speed(result.downloadMbps, locale: localization.locale))↓  \(MetricFormatter.speed(result.uploadMbps, locale: localization.locale))↑"
                        )
                        .font(.system(size: 12, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(SpeedChrome.textPrimary)

                        Text(
                            "\(MetricFormatter.milliseconds(result.idleLatencyMs, locale: localization.locale)) ms  \(MetricFormatter.milliseconds(result.worstResponsivenessMs, locale: localization.locale)) ms"
                        )
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(SpeedChrome.textSecondary)
                        .monospacedDigit()
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .subtleHover(cornerRadius: 12)

                if index < recentMeasurements.count - 1 {
                    SubtleDivider()
                }
            }
        }
    }

    private func chartSection<Content: View>(
        title: String,
        legends: [HistoryLegendItem],
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(SpeedChrome.textPrimary)

                Spacer(minLength: 12)

                HStack(spacing: 12) {
                    ForEach(legends) { legend in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(legend.color)
                                .frame(width: 7, height: 7)

                            Text(legend.title)
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundStyle(SpeedChrome.textTertiary)
                        }
                    }
                }
            }

            content()
        }
    }

    private var axisDesiredCount: Int {
        switch selectedRange {
        case .hour:
            6
        case .day:
            4
        case .week, .month:
            5
        }
    }

    private func timestampLabel(for date: Date) -> String {
        let style = Date.FormatStyle(
            date: selectedRange == .hour || selectedRange == .day ? .omitted : .abbreviated,
            time: .shortened
        )
        return date.formatted(style.locale(localization.locale))
    }

    @ViewBuilder
    private var throughputTooltip: some View {
        if let selectedMeasurement {
            tooltipCard(timestamp: tooltipTimestamp(for: selectedMeasurement.measuredAt)) {
                tooltipValueRow(
                    color: SpeedChrome.brand,
                    title: strings.historyLegendDownload,
                    value: exactSpeed(selectedMeasurement.downloadMbps)
                )

                tooltipValueRow(
                    color: .green,
                    title: strings.historyLegendUpload,
                    value: exactSpeed(selectedMeasurement.uploadMbps)
                )
            }
        }
    }

    @ViewBuilder
    private var latencyTooltip: some View {
        if let selectedMeasurement {
            tooltipCard(timestamp: tooltipTimestamp(for: selectedMeasurement.measuredAt)) {
                tooltipValueRow(
                    color: .orange,
                    title: strings.historyLegendLatency,
                    value: exactMilliseconds(selectedMeasurement.idleLatencyMs)
                )

                tooltipValueRow(
                    color: .pink,
                    title: strings.historyLegendResponsiveness,
                    value: exactMilliseconds(selectedMeasurement.worstResponsivenessMs)
                )
            }
        }
    }

    private func tooltipCard<Content: View>(
        timestamp: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(timestamp)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(SpeedChrome.textSecondary)

            content()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: 176, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(SpeedChrome.stroke, lineWidth: 0.8)
        )
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }

    private func tooltipValueRow(color: Color, title: String, value: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(SpeedChrome.textSecondary)

            Spacer(minLength: 8)

            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(SpeedChrome.textPrimary)
        }
    }

    private func selectionOverlay<Tooltip: View>(
        proxy: ChartProxy,
        geometry: GeometryProxy,
        chart: HistoryChartKind,
        @ViewBuilder tooltip: () -> Tooltip
    ) -> some View {
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
                            handleHover(phase, proxy: proxy, plotFrame: plotFrame, chart: chart)
                        }

                    if activeChart == chart,
                       selectedMeasurement != nil,
                       let selectedMeasurement,
                       let plotX = proxy.position(forX: selectedMeasurement.measuredAt) {
                        let pointX = plotFrame.minX + plotX

                        tooltip()
                            .position(
                                x: preferredTooltipX(for: pointX, in: plotFrame),
                                y: plotFrame.minY + 24
                            )
                            .allowsHitTesting(false)
                    }
                }
            }
        }
    }

    private func handleHover(
        _ phase: HoverPhase,
        proxy: ChartProxy,
        plotFrame: CGRect,
        chart: HistoryChartKind
    ) {
        switch phase {
        case let .active(location):
            guard plotFrame.contains(location) else {
                if activeChart == chart {
                    clearSelection()
                }
                return
            }

            let plotX = location.x - plotFrame.origin.x
            guard let hoveredDate: Date = proxy.value(atX: plotX) else {
                clearSelection()
                return
            }

            selectedMeasurement = nearestMeasurement(to: hoveredDate)
            activeChart = chart
        case .ended:
            if activeChart == chart {
                clearSelection()
            }
        }
    }

    private func nearestMeasurement(to hoveredDate: Date) -> SpeedTestResult? {
        filteredHistory.min { lhs, rhs in
            abs(lhs.measuredAt.timeIntervalSince(hoveredDate))
                < abs(rhs.measuredAt.timeIntervalSince(hoveredDate))
        }
    }

    private func clearSelection() {
        selectedMeasurement = nil
        activeChart = nil
    }

    private func preferredTooltipX(for pointX: CGFloat, in plotFrame: CGRect) -> CGFloat {
        let halfWidth: CGFloat = 88
        let clearance: CGFloat = 24

        if pointX <= plotFrame.midX {
            let tooltipX = pointX + halfWidth + clearance
            return min(tooltipX, plotFrame.maxX - halfWidth)
        } else {
            let tooltipX = pointX - halfWidth - clearance
            return max(tooltipX, plotFrame.minX + halfWidth)
        }
    }

    private func tooltipTimestamp(for date: Date) -> String {
        date.formatted(
            Date.FormatStyle(date: .abbreviated, time: .shortened)
                .locale(localization.locale)
        )
    }

    private func exactSpeed(_ value: Double) -> String {
        "\(value.formatted(.number.locale(localization.locale).precision(.fractionLength(1)))) Mbps"
    }

    private func exactMilliseconds(_ value: Double) -> String {
        "\(value.formatted(.number.locale(localization.locale).precision(.fractionLength(1)))) ms"
    }
}

private struct HistoryLegendItem: Identifiable {
    let title: String
    let color: Color

    var id: String {
        title
    }
}

private enum HistoryChartKind {
    case throughput
    case latency
}
