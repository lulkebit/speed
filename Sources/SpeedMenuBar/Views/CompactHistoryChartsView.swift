import Charts
import SpeedCore
import SwiftUI

struct CompactHistoryChartsView: View {
    let entries: [SpeedTestHistoryEntry]
    let localization: SpeedLocalization

    private var recentHistory: [SpeedTestHistoryEntry] {
        Array(entries.suffix(12))
    }

    private var latestMeasurement: SpeedTestResult? {
        recentHistory.compactMap(\.result).last
    }

    private var recentIssues: [NetworkIssueRecord] {
        recentHistory.compactMap(\.issue)
    }

    var body: some View {
        Group {
            if recentHistory.count >= 2 {
                VStack(alignment: .leading, spacing: 12) {
                    CompactTrendSection(
                        points: throughputPoints,
                        issues: recentIssues,
                        strings: localization.strings,
                        locale: localization.locale,
                        primaryColor: SpeedChrome.brand,
                        secondaryColor: .green,
                        primaryTitle: localization.strings.historyLegendDownload,
                        secondaryTitle: localization.strings.historyLegendUpload,
                        primaryLegend: MiniMetricLegend(
                            symbol: "arrow.down",
                            value: MetricFormatter.speed(
                                latestMeasurement?.downloadMbps,
                                locale: localization.locale
                            ),
                            tint: SpeedChrome.brand
                        ),
                        secondaryLegend: MiniMetricLegend(
                            symbol: "arrow.up",
                            value: MetricFormatter.speed(
                                latestMeasurement?.uploadMbps,
                                locale: localization.locale
                            ),
                            tint: .green
                        ),
                        valueFormatter: { value in
                            "\(value.formatted(.number.locale(localization.locale).precision(.fractionLength(1)))) Mbps"
                        }
                    )

                    SubtleDivider()

                    CompactTrendSection(
                        points: latencyPoints,
                        issues: recentIssues,
                        strings: localization.strings,
                        locale: localization.locale,
                        primaryColor: .orange,
                        secondaryColor: .pink,
                        primaryTitle: localization.strings.historyLegendLatency,
                        secondaryTitle: localization.strings.historyLegendResponsiveness,
                        primaryLegend: MiniMetricLegend(
                            symbol: "timer",
                            value: MetricFormatter.milliseconds(
                                latestMeasurement?.idleLatencyMs,
                                locale: localization.locale
                            ) + " ms",
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
        recentHistory.compactMap(\.result).map { result in
            CompactTrendPoint(
                measuredAt: result.measuredAt,
                primary: result.downloadMbps,
                secondary: result.uploadMbps
            )
        }
    }

    private var latencyPoints: [CompactTrendPoint] {
        recentHistory.compactMap(\.result).map { result in
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
    let issues: [NetworkIssueRecord]
    let strings: SpeedStrings
    let locale: Locale
    let primaryColor: Color
    let secondaryColor: Color
    let primaryTitle: String
    let secondaryTitle: String
    let primaryLegend: MiniMetricLegend
    let secondaryLegend: MiniMetricLegend
    let valueFormatter: (Double) -> String

    @State
    private var selectedEvent: CompactTrendEvent?

    @State
    private var selectedPlotX: CGFloat?

    @State
    private var plotFrame: CGRect = .zero

    @State
    private var isHovering = false

    private var events: [CompactTrendEvent] {
        let pointEvents = points.map { point in
            CompactTrendEvent(measuredAt: point.measuredAt, point: point, issue: nil)
        }
        let issueEvents = issues.map { issue in
            CompactTrendEvent(measuredAt: issue.measuredAt, point: nil, issue: issue)
        }

        return (pointEvents + issueEvents).sorted { $0.measuredAt < $1.measuredAt }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                MiniMetricLegendView(legend: primaryLegend)

                Spacer(minLength: 0)

                MiniMetricLegendView(legend: secondaryLegend)
            }

            ZStack(alignment: .topLeading) {
                Chart {
                    if points.isEmpty {
                        RuleMark(y: .value("Placeholder", 0))
                            .foregroundStyle(.clear)
                    }

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

                    if let selectedEvent {
                        RuleMark(x: .value("Selected", selectedEvent.measuredAt))
                            .foregroundStyle(Color.white.opacity(0.12))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    }

                    if let selectedPoint = selectedEvent?.point {
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
                    plot.background(Color.clear)
                }
                .frame(height: chartHeight)
                .padding(.top, tooltipLaneHeight)

                if isHovering,
                   let selectedEvent,
                   let selectedPlotX,
                   !plotFrame.isEmpty {
                    compactTooltip(for: selectedEvent)
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
                let hoverFrame = interactionFrame(for: plotFrame)

                ZStack(alignment: .topLeading) {
                    issueMarkers(proxy: proxy, plotFrame: plotFrame)

                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .frame(width: hoverFrame.width, height: hoverFrame.height)
                        .position(x: hoverFrame.midX, y: hoverFrame.midY)
                        .onContinuousHover { phase in
                            handleHover(
                                phase,
                                proxy: proxy,
                                plotFrame: plotFrame,
                                hoverFrame: hoverFrame
                            )
                        }
                }
            }
        }
    }

    @ViewBuilder
    private func issueMarkers(proxy: ChartProxy, plotFrame: CGRect) -> some View {
        ForEach(issues, id: \.measuredAt) { issue in
            if let plotX = proxy.position(forX: issue.measuredAt) {
                NetworkIssueMarkerView(
                    issue: issue,
                    isSelected: selectedEvent?.issue == issue,
                    size: selectedEvent?.issue == issue
                        ? (issue.occurrenceCount > 1 ? 18 : 16)
                        : (issue.occurrenceCount > 1 ? 15 : 13)
                )
                .position(x: plotFrame.minX + plotX, y: issueMarkerY(in: plotFrame))
                .allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder
    private func compactTooltip(for event: CompactTrendEvent) -> some View {
        if let issue = event.issue {
            CompactTrendIssueTooltip(
                timestamp: compactIssueTimestamp(issue),
                issue: issue,
                strings: strings
            )
        } else if let point = event.point {
            CompactTrendTooltip(
                timestamp: event.measuredAt.formatted(
                    Date.FormatStyle(date: .omitted, time: .shortened)
                        .locale(locale)
                ),
                primaryTitle: primaryTitle,
                primaryValue: valueFormatter(point.primary),
                primaryColor: primaryColor,
                secondaryTitle: secondaryTitle,
                secondaryValue: valueFormatter(point.secondary),
                secondaryColor: secondaryColor
            )
        }
    }

    private func handleHover(
        _ phase: HoverPhase,
        proxy: ChartProxy,
        plotFrame: CGRect,
        hoverFrame: CGRect
    ) {
        switch phase {
        case let .active(location):
            self.plotFrame = plotFrame

            if let hoveredIssue = hoveredIssue(at: location, proxy: proxy, plotFrame: plotFrame) {
                isHovering = true
                selectedEvent = CompactTrendEvent(
                    measuredAt: hoveredIssue.measuredAt,
                    point: nil,
                    issue: hoveredIssue
                )
                selectedPlotX = issueMarkerX(for: hoveredIssue, proxy: proxy, plotFrame: plotFrame)
                return
            }

            guard hoverFrame.contains(location) else {
                isHovering = false
                selectedEvent = nil
                selectedPlotX = nil
                return
            }

            isHovering = true

            let plotX = min(max(location.x - plotFrame.origin.x, 0), plotFrame.width)
            guard let hoveredDate: Date = proxy.value(atX: plotX) else {
                selectedEvent = nil
                selectedPlotX = nil
                return
            }

            let event = nearestEvent(to: hoveredDate)
            selectedEvent = event

            if let event, let snappedPlotX = proxy.position(forX: event.measuredAt) {
                selectedPlotX = plotFrame.minX + snappedPlotX
            } else {
                selectedPlotX = nil
            }
        case .ended:
            isHovering = false
            selectedEvent = nil
            selectedPlotX = nil
        }
    }

    private func nearestEvent(to hoveredDate: Date) -> CompactTrendEvent? {
        events.min { lhs, rhs in
            abs(lhs.measuredAt.timeIntervalSince(hoveredDate))
                < abs(rhs.measuredAt.timeIntervalSince(hoveredDate))
        }
    }

    private func hoveredIssue(
        at location: CGPoint,
        proxy: ChartProxy,
        plotFrame: CGRect
    ) -> NetworkIssueRecord? {
        issues.first { issue in
            guard let markerX = issueMarkerX(for: issue, proxy: proxy, plotFrame: plotFrame) else {
                return false
            }

            let markerCenter = CGPoint(x: markerX, y: issueMarkerY(in: plotFrame))
            return hypot(location.x - markerCenter.x, location.y - markerCenter.y) <= issueHoverRadius
        }
    }

    private func issueMarkerX(
        for issue: NetworkIssueRecord,
        proxy: ChartProxy,
        plotFrame: CGRect
    ) -> CGFloat? {
        guard let plotX = proxy.position(forX: issue.measuredAt) else {
            return nil
        }

        return plotFrame.minX + plotX
    }

    private func interactionFrame(for plotFrame: CGRect) -> CGRect {
        CGRect(
            x: plotFrame.minX - hoverHorizontalInset,
            y: min(issueMarkerY(in: plotFrame) - issueHoverRadius, plotFrame.minY),
            width: plotFrame.width + hoverHorizontalInset * 2,
            height: plotFrame.maxY - min(issueMarkerY(in: plotFrame) - issueHoverRadius, plotFrame.minY) + hoverVerticalInset
        )
    }

    private func preferredTooltipX(for pointX: CGFloat, in plotFrame: CGRect) -> CGFloat {
        let halfWidth: CGFloat = 84
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
        44
    }

    private var chartHeight: CGFloat {
        56
    }

    private func compactIssueTimestamp(_ issue: NetworkIssueRecord) -> String {
        let style = Date.FormatStyle(date: .omitted, time: .shortened).locale(locale)

        if issue.coversMultipleEvents {
            return "\(issue.startedAt.formatted(style)) - \(issue.lastObservedAt.formatted(style))"
        }

        return issue.measuredAt.formatted(style)
    }

    private func issueMarkerY(in plotFrame: CGRect) -> CGFloat {
        min(plotFrame.minY - 6, issueMarkerTopInset)
    }

    private var issueMarkerTopInset: CGFloat {
        4
    }

    private var issueHoverRadius: CGFloat {
        18
    }

    private var hoverHorizontalInset: CGFloat {
        14
    }

    private var hoverVerticalInset: CGFloat {
        10
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

private struct CompactTrendIssueTooltip: View {
    let timestamp: String
    let issue: NetworkIssueRecord
    let strings: SpeedStrings

    private var summaryText: String? {
        if let pathStatus = issue.pathStatusTitle(using: strings) {
            return pathStatus
        }

        if let diagnosticCode = issue.diagnosticCode {
            return diagnosticCode
        }

        if let message = issue.message, !message.isEmpty {
            return message
        }

        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(timestamp)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(SpeedChrome.textTertiary)

            HStack(spacing: 6) {
                Image(systemName: issue.kind.symbolName)
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(issue.tintColor)

                Text(issue.occurrenceCount > 1 ? "\(issue.title(using: strings)) \(issue.occurrenceCount)x" : issue.title(using: strings))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(SpeedChrome.textPrimary)
            }

            if let summaryText {
                Text(summaryText)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(SpeedChrome.textSecondary)
                    .lineLimit(2)
                    .frame(maxWidth: 160, alignment: .leading)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(issue.tintColor.opacity(0.06))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(issue.tintColor.opacity(0.18), lineWidth: 0.8)
        )
        .shadow(color: .black.opacity(0.14), radius: 10, y: 4)
    }
}

private struct CompactTrendPoint: Identifiable, Equatable {
    let measuredAt: Date
    let primary: Double
    let secondary: Double

    var id: Date {
        measuredAt
    }
}

private struct CompactTrendEvent: Identifiable, Equatable {
    let measuredAt: Date
    let point: CompactTrendPoint?
    let issue: NetworkIssueRecord?

    var id: Date {
        measuredAt
    }
}
