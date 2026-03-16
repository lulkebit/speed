import Charts
import Observation
import SpeedCore
import SwiftUI

struct HistorySectionView: View {
    @Bindable var viewModel: SpeedTestViewModel
    let localization: SpeedLocalization

    @State
    private var selectedRange: HistoryTimeRange = .day

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
        Array(filteredHistory.suffix(5).reversed())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker(strings.historyRangeLabel, selection: $selectedRange) {
                ForEach(HistoryTimeRange.allCases) { range in
                    Text(range.title(using: strings))
                        .tag(range)
                }
            }
            .pickerStyle(.segmented)

            Text(strings.historyMeasurementsDescription(count: filteredHistory.count))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            if filteredHistory.isEmpty {
                emptyState
            } else {
                throughputChartCard
                latencyChartCard
                recentMeasurementsCard
            }
        }
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(strings.historyEmptyTitle)
                .font(.system(size: 13, weight: .semibold))

            Text(strings.historyEmptyDescription)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
    }

    private var throughputChartCard: some View {
        chartCard(title: strings.historyChartThroughputTitle) {
            Chart {
                ForEach(filteredHistory) { result in
                    LineMark(
                        x: .value("Time", result.measuredAt),
                        y: .value(strings.historyLegendDownload, result.downloadMbps),
                        series: .value("Series", strings.historyLegendDownload)
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Time", result.measuredAt),
                        y: .value(strings.historyLegendUpload, result.uploadMbps),
                        series: .value("Series", strings.historyLegendUpload)
                    )
                    .interpolationMethod(.catmullRom)

                    if filteredHistory.count == 1 {
                        PointMark(
                            x: .value("Time", result.measuredAt),
                            y: .value(strings.historyLegendDownload, result.downloadMbps)
                        )

                        PointMark(
                            x: .value("Time", result.measuredAt),
                            y: .value(strings.historyLegendUpload, result.uploadMbps)
                        )
                    }
                }
            }
            .chartLegend(position: .top, spacing: 16)
            .chartForegroundStyleScale([
                strings.historyLegendDownload: SpeedChrome.brand,
                strings.historyLegendUpload: Color.green
            ])
            .chartXScale(domain: chartDomain)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: selectedRange == .day ? 4 : 5)) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: selectedRange.axisFormatStyle(locale: localization.locale))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 170)
        }
    }

    private var latencyChartCard: some View {
        chartCard(title: strings.historyChartLatencyTitle) {
            Chart {
                ForEach(filteredHistory) { result in
                    LineMark(
                        x: .value("Time", result.measuredAt),
                        y: .value(strings.historyLegendLatency, result.idleLatencyMs),
                        series: .value("Series", strings.historyLegendLatency)
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Time", result.measuredAt),
                        y: .value(strings.historyLegendResponsiveness, result.worstResponsivenessMs),
                        series: .value("Series", strings.historyLegendResponsiveness)
                    )
                    .interpolationMethod(.catmullRom)

                    if filteredHistory.count == 1 {
                        PointMark(
                            x: .value("Time", result.measuredAt),
                            y: .value(strings.historyLegendLatency, result.idleLatencyMs)
                        )

                        PointMark(
                            x: .value("Time", result.measuredAt),
                            y: .value(strings.historyLegendResponsiveness, result.worstResponsivenessMs)
                        )
                    }
                }
            }
            .chartLegend(position: .top, spacing: 16)
            .chartForegroundStyleScale([
                strings.historyLegendLatency: Color.orange,
                strings.historyLegendResponsiveness: Color.pink
            ])
            .chartXScale(domain: chartDomain)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: selectedRange == .day ? 4 : 5)) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: selectedRange.axisFormatStyle(locale: localization.locale))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 170)
        }
    }

    private var recentMeasurementsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(strings.historyRecentMeasurementsTitle)
                .font(.system(size: 13, weight: .semibold))

            ForEach(Array(recentMeasurements.enumerated()), id: \.element.id) { index, result in
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(timestampLabel(for: result.measuredAt))
                            .font(.system(size: 12, weight: .semibold))

                        Text(result.interfaceName.uppercased(with: localization.locale))
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 12)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(
                            "\(MetricFormatter.speed(result.downloadMbps, locale: localization.locale))↓  \(MetricFormatter.speed(result.uploadMbps, locale: localization.locale))↑"
                        )
                        .font(.system(size: 12.5, weight: .semibold))
                        .monospacedDigit()

                        Text(
                            "\(MetricFormatter.milliseconds(result.idleLatencyMs, locale: localization.locale)) ms • \(MetricFormatter.milliseconds(result.worstResponsivenessMs, locale: localization.locale)) ms"
                        )
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    }
                }

                if index < recentMeasurements.count - 1 {
                    Divider()
                }
            }
        }
        .padding(14)
        .background(cardBackground)
        .overlay(cardBorder)
    }

    private func chartCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))

            content()
        }
        .padding(14)
        .background(cardBackground)
        .overlay(cardBorder)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.92))
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 1)
    }

    private func timestampLabel(for date: Date) -> String {
        let style = Date.FormatStyle(
            date: selectedRange == .day ? .omitted : .abbreviated,
            time: .shortened
        )
        return date.formatted(style.locale(localization.locale))
    }
}
