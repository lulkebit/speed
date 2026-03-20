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
    private var selectedEntry: SpeedTestHistoryEntry?

    @State
    private var activeChart: HistoryChartKind?

    private var strings: SpeedStrings {
        localization.strings
    }

    private var chartDomain: ClosedRange<Date> {
        selectedRange.chartDomain()
    }

    private var filteredHistory: [SpeedTestHistoryEntry] {
        viewModel.history.filter { chartDomain.contains($0.measuredAt) }
    }

    private var filteredMeasurements: [SpeedTestResult] {
        filteredHistory.compactMap(\.result)
    }

    private var filteredIssues: [NetworkIssueRecord] {
        filteredHistory.compactMap(\.issue)
    }

    private var recentEntries: [SpeedTestHistoryEntry] {
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

                if !recentEntries.isEmpty {
                    SubtleDivider()
                        .padding(.vertical, 16)

                    recentEntriesSection
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
                HistoryLegendItem(title: strings.historyLegendUpload, color: .green),
                HistoryLegendItem(
                    title: strings.historyLegendIncidents,
                    color: .red,
                    symbolName: "exclamationmark.triangle.fill"
                )
            ]
        ) {
            Chart {
                if filteredMeasurements.isEmpty {
                    RuleMark(y: .value("Placeholder", 0))
                        .foregroundStyle(.clear)
                }

                ForEach(filteredMeasurements) { result in
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

                if let selectedEntry {
                    RuleMark(x: .value("Selected time", selectedEntry.measuredAt))
                        .foregroundStyle(SpeedChrome.textTertiary.opacity(0.55))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }

                if let selectedMeasurement = selectedEntry?.result {
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
                    selectionOverlay(
                        proxy: proxy,
                        geometry: geometry,
                        chart: .throughput,
                        issues: filteredIssues
                    )
                }
            }
            .frame(height: 154)
            .padding(.top, issueMarkerLaneHeight)
        }
    }

    private var latencyChartSection: some View {
        chartSection(
            title: strings.historyChartLatencyTitle,
            legends: [
                HistoryLegendItem(title: strings.historyLegendLatency, color: .orange),
                HistoryLegendItem(title: strings.historyLegendResponsiveness, color: .pink),
                HistoryLegendItem(
                    title: strings.historyLegendIncidents,
                    color: .red,
                    symbolName: "exclamationmark.triangle.fill"
                )
            ]
        ) {
            Chart {
                if filteredMeasurements.isEmpty {
                    RuleMark(y: .value("Placeholder", 0))
                        .foregroundStyle(.clear)
                }

                ForEach(filteredMeasurements) { result in
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

                if let selectedEntry {
                    RuleMark(x: .value("Selected time", selectedEntry.measuredAt))
                        .foregroundStyle(SpeedChrome.textTertiary.opacity(0.55))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }

                if let selectedMeasurement = selectedEntry?.result {
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
                    selectionOverlay(
                        proxy: proxy,
                        geometry: geometry,
                        chart: .latency,
                        issues: filteredIssues
                    )
                }
            }
            .frame(height: 154)
            .padding(.top, issueMarkerLaneHeight)
        }
    }

    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(strings.historyRecentMeasurementsTitle)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(SpeedChrome.textPrimary)

            ForEach(Array(recentEntries.enumerated()), id: \.element.id) { index, entry in
                if let result = entry.result {
                    recentMeasurementRow(result)
                } else if let issue = entry.issue {
                    recentIssueRow(issue)
                }

                if index < recentEntries.count - 1 {
                    SubtleDivider()
                }
            }
        }
    }

    private func recentMeasurementRow(_ result: SpeedTestResult) -> some View {
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
    }

    private func recentIssueRow(_ issue: NetworkIssueRecord) -> some View {
        HStack(alignment: .center, spacing: 12) {
            NetworkIssueMarkerView(issue: issue, size: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(issue.title(using: strings))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(SpeedChrome.textPrimary)

                Text(issueTimestampLabel(issue))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SpeedChrome.textTertiary)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 2) {
                if let pathStatus = issue.pathStatusTitle(using: strings) {
                    Text(pathStatus)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(issue.tintColor)
                }

                Text(issueRecentSummary(issue))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SpeedChrome.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 240, alignment: .trailing)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .subtleHover(
            cornerRadius: 12,
            fill: issue.tintColor.opacity(0.10),
            stroke: issue.tintColor.opacity(0.18)
        )
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
                            if let symbolName = legend.symbolName {
                                Image(systemName: symbolName)
                                    .font(.system(size: 9.5, weight: .semibold))
                                    .foregroundStyle(legend.color)
                            } else {
                                Circle()
                                    .fill(legend.color)
                                    .frame(width: 7, height: 7)
                            }

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
    private func chartTooltip(for entry: SpeedTestHistoryEntry, chart: HistoryChartKind) -> some View {
        if let issue = entry.issue {
            issueTooltip(issue)
        } else if let result = entry.result {
            switch chart {
            case .throughput:
                measurementTooltip(
                    timestamp: tooltipTimestamp(for: result.measuredAt),
                    primaryColor: SpeedChrome.brand,
                    primaryTitle: strings.historyLegendDownload,
                    primaryValue: exactSpeed(result.downloadMbps),
                    secondaryColor: .green,
                    secondaryTitle: strings.historyLegendUpload,
                    secondaryValue: exactSpeed(result.uploadMbps),
                    result: result
                )
            case .latency:
                measurementTooltip(
                    timestamp: tooltipTimestamp(for: result.measuredAt),
                    primaryColor: .orange,
                    primaryTitle: strings.historyLegendLatency,
                    primaryValue: exactMilliseconds(result.idleLatencyMs),
                    secondaryColor: .pink,
                    secondaryTitle: strings.historyLegendResponsiveness,
                    secondaryValue: exactMilliseconds(result.worstResponsivenessMs),
                    result: result
                )
            }
        }
    }

    private func measurementTooltip(
        timestamp: String,
        primaryColor: Color,
        primaryTitle: String,
        primaryValue: String,
        secondaryColor: Color,
        secondaryTitle: String,
        secondaryValue: String,
        result: SpeedTestResult
    ) -> some View {
        tooltipCard(timestamp: timestamp) {
            tooltipValueRow(color: primaryColor, title: primaryTitle, value: primaryValue)
            tooltipValueRow(color: secondaryColor, title: secondaryTitle, value: secondaryValue)
            tooltipMetadataRow(
                title: strings.historyTooltipInterfaceLabel,
                value: result.interfaceName.uppercased(with: localization.locale)
            )
            tooltipMetadataRow(
                title: strings.historyTooltipServerLabel,
                value: normalizedServerName(result.serverName)
            )
        }
    }

    private func issueTooltip(_ issue: NetworkIssueRecord) -> some View {
        tooltipCard(timestamp: issueTooltipTimestamp(issue)) {
            NetworkIssueBadgeView(issue: issue, strings: strings)

            if issue.occurrenceCount > 1 {
                tooltipMetadataRow(
                    title: strings.historyIssueOccurrencesLabel,
                    value: "\(issue.occurrenceCount)x"
                )
            }

            if let durationSeconds = issue.disturbanceDurationSeconds {
                tooltipMetadataRow(
                    title: strings.historyIssueDurationLabel,
                    value: formattedIssueDuration(durationSeconds)
                )
            }

            if let pathStatus = issue.pathStatusTitle(using: strings) {
                tooltipMetadataRow(
                    title: strings.historyIssueNetworkStatusLabel,
                    value: pathStatus
                )
            }

            if let interfaces = issue.interfaceSummary {
                tooltipMetadataRow(
                    title: strings.historyIssueInterfacesLabel,
                    value: interfaces
                )
            }

            if let serverName = issue.normalizedServerName {
                tooltipMetadataRow(
                    title: strings.historyTooltipServerLabel,
                    value: serverName
                )
            }

            if let diagnosticCode = issue.diagnosticCode {
                tooltipMetadataRow(
                    title: strings.historyIssueCodeLabel,
                    value: diagnosticCode
                )
            }

            if let message = issue.message, !message.isEmpty {
                tooltipMetadataRow(
                    title: strings.historyIssueDetailsLabel,
                    value: message,
                    multiline: true
                )
            }
        }
    }

    private func tooltipCard<Content: View>(
        timestamp: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(timestamp)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(SpeedChrome.textSecondary)

            content()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: tooltipWidth, alignment: .leading)
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

    private func tooltipMetadataRow(
        title: String,
        value: String,
        multiline: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased(with: localization.locale))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(SpeedChrome.textTertiary)
                .tracking(0.6)

            Text(value)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(SpeedChrome.textPrimary)
                .fixedSize(horizontal: false, vertical: multiline)
                .lineLimit(multiline ? nil : 1)
        }
    }

    private func selectionOverlay(
        proxy: ChartProxy,
        geometry: GeometryProxy,
        chart: HistoryChartKind,
        issues: [NetworkIssueRecord]
    ) -> some View {
        Group {
            if let plotFrameAnchor = proxy.plotFrame {
                let plotFrame = geometry[plotFrameAnchor]
                let hoverFrame = interactionFrame(for: plotFrame)

                ZStack(alignment: .topLeading) {
                    issueMarkers(proxy: proxy, plotFrame: plotFrame, chart: chart, issues: issues)

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
                                hoverFrame: hoverFrame,
                                chart: chart,
                                issues: issues
                            )
                        }

                    if activeChart == chart,
                       let selectedEntry,
                       let plotX = proxy.position(forX: selectedEntry.measuredAt) {
                        let pointX = plotFrame.minX + plotX

                        chartTooltip(for: selectedEntry, chart: chart)
                            .position(
                                x: preferredTooltipX(for: pointX, in: plotFrame),
                                y: plotFrame.minY + 28
                            )
                            .allowsHitTesting(false)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func issueMarkers(
        proxy: ChartProxy,
        plotFrame: CGRect,
        chart: HistoryChartKind,
        issues: [NetworkIssueRecord]
    ) -> some View {
        ForEach(issues, id: \.measuredAt) { issue in
            if let plotX = proxy.position(forX: issue.measuredAt) {
                NetworkIssueMarkerView(
                    issue: issue,
                    isSelected: activeChart == chart && selectedEntry?.issue == issue,
                    size: activeChart == chart && selectedEntry?.issue == issue ? 18 : 15
                )
                .position(x: plotFrame.minX + plotX, y: issueMarkerY(in: plotFrame))
                .allowsHitTesting(false)
            }
        }
    }

    private func handleHover(
        _ phase: HoverPhase,
        proxy: ChartProxy,
        plotFrame: CGRect,
        hoverFrame: CGRect,
        chart: HistoryChartKind,
        issues: [NetworkIssueRecord]
    ) {
        switch phase {
        case let .active(location):
            if let hoveredIssue = hoveredIssue(
                at: location,
                proxy: proxy,
                plotFrame: plotFrame,
                issues: issues
            ) {
                selectedEntry = SpeedTestHistoryEntry(issue: hoveredIssue)
                activeChart = chart
                return
            }

            guard hoverFrame.contains(location) else {
                if activeChart == chart {
                    clearSelection()
                }
                return
            }

            let plotX = min(max(location.x - plotFrame.origin.x, 0), plotFrame.width)
            guard let hoveredDate: Date = proxy.value(atX: plotX) else {
                clearSelection()
                return
            }

            selectedEntry = nearestEntry(to: hoveredDate)
            activeChart = chart
        case .ended:
            if activeChart == chart {
                clearSelection()
            }
        }
    }

    private func hoveredIssue(
        at location: CGPoint,
        proxy: ChartProxy,
        plotFrame: CGRect,
        issues: [NetworkIssueRecord]
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
        let topEdge = min(issueMarkerY(in: plotFrame) - issueHoverRadius, plotFrame.minY)
        return CGRect(
            x: plotFrame.minX - hoverHorizontalInset,
            y: topEdge,
            width: plotFrame.width + hoverHorizontalInset * 2,
            height: plotFrame.maxY - topEdge + hoverVerticalInset
        )
    }

    private func nearestEntry(to hoveredDate: Date) -> SpeedTestHistoryEntry? {
        filteredHistory.min { lhs, rhs in
            abs(lhs.measuredAt.timeIntervalSince(hoveredDate))
                < abs(rhs.measuredAt.timeIntervalSince(hoveredDate))
        }
    }

    private func clearSelection() {
        selectedEntry = nil
        activeChart = nil
    }

    private func preferredTooltipX(for pointX: CGFloat, in plotFrame: CGRect) -> CGFloat {
        let halfWidth = tooltipWidth / 2
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

    private func normalizedServerName(_ serverName: String) -> String {
        serverName.replacingOccurrences(of: ".aaplimg.com", with: "")
    }

    private func issueRecentSummary(_ issue: NetworkIssueRecord) -> String {
        var segments = [String]()

        if issue.occurrenceCount > 1 {
            segments.append("\(issue.occurrenceCount)x")
        }

        if let pathStatus = issue.pathStatusTitle(using: strings) {
            segments.append(pathStatus)
        }

        if let diagnosticCode = issue.diagnosticCode {
            segments.append(diagnosticCode)
        }

        if !segments.isEmpty, segments.count > 1 {
            return segments.joined(separator: " • ")
        }

        if let firstSegment = segments.first {
            return firstSegment
        }

        if let interfaces = issue.interfaceSummary {
            return interfaces
        }

        if let message = issue.message, !message.isEmpty {
            return message
        }

        return strings.networkIssueTitle(issue.kind)
    }

    private func issueTimestampLabel(_ issue: NetworkIssueRecord) -> String {
        if issue.coversMultipleEvents {
            return "\(timestampLabel(for: issue.startedAt)) - \(timestampLabel(for: issue.lastObservedAt))"
        }

        return timestampLabel(for: issue.measuredAt)
    }

    private func issueTooltipTimestamp(_ issue: NetworkIssueRecord) -> String {
        if issue.coversMultipleEvents {
            return "\(tooltipTimestamp(for: issue.startedAt)) - \(tooltipTimestamp(for: issue.lastObservedAt))"
        }

        return tooltipTimestamp(for: issue.measuredAt)
    }

    private func formattedIssueDuration(_ totalSeconds: Int) -> String {
        if totalSeconds < 60 {
            return "\(totalSeconds)s"
        }

        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        if minutes < 60 {
            return seconds == 0 ? "\(minutes)m" : "\(minutes)m \(seconds)s"
        }

        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return remainingMinutes == 0 ? "\(hours)h" : "\(hours)h \(remainingMinutes)m"
    }

    private func issueMarkerY(in plotFrame: CGRect) -> CGFloat {
        max(plotFrame.minY - issueMarkerLaneHeight * 0.45, issueMarkerLaneHeight * 0.5)
    }

    private var tooltipWidth: CGFloat {
        228
    }

    private var issueMarkerLaneHeight: CGFloat {
        22
    }

    private var issueHoverRadius: CGFloat {
        18
    }

    private var hoverHorizontalInset: CGFloat {
        12
    }

    private var hoverVerticalInset: CGFloat {
        10
    }
}

private struct HistoryLegendItem: Identifiable {
    let title: String
    let color: Color
    var symbolName: String? = nil

    var id: String {
        title
    }
}

private enum HistoryChartKind {
    case throughput
    case latency
}
