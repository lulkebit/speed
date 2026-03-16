import SwiftUI

struct MetricRowView: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let note: String?

    init(
        title: String,
        value: String,
        unit: String,
        icon: String,
        note: String? = nil
    ) {
        self.title = title
        self.value = value
        self.unit = unit
        self.icon = icon
        self.note = note
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(SpeedChrome.textSecondary)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(SpeedChrome.softFill)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(SpeedChrome.textPrimary)

                    if let note, !note.isEmpty {
                        Text(note)
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(SpeedChrome.textTertiary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 12)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: unit.isEmpty ? 15 : 20, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(SpeedChrome.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(SpeedChrome.textSecondary)
                }
            }
            .frame(minWidth: 70, alignment: .trailing)
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 10)
    }
}

struct PanelBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.52),
                    Color.black.opacity(0.68)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Rectangle()
                .fill(.ultraThinMaterial)

            LinearGradient(
                colors: [
                    Color.white.opacity(0.20),
                    Color.white.opacity(0.04),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    SpeedChrome.brand.opacity(0.20),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 16,
                endRadius: 380
            )

            RadialGradient(
                colors: [
                    Color.white.opacity(0.08),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 320
            )
        }
    }
}

struct SubtleDivider: View {
    var body: some View {
        Rectangle()
            .fill(SpeedChrome.divider)
            .frame(height: 1)
    }
}

struct SubtleBadge: View {
    let title: String
    var symbol: String? = nil
    var tint: Color = SpeedChrome.textSecondary

    var body: some View {
        HStack(spacing: 6) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(tint)
            }

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(SpeedChrome.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule(style: .continuous)
                .fill(SpeedChrome.softFill)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(SpeedChrome.stroke, lineWidth: 0.8)
        )
    }
}

enum SpeedChrome {
    static let panelWidth: CGFloat = 392
    static let brand = Color(red: 0.20, green: 0.52, blue: 0.95)
    static let stroke = Color.white.opacity(0.16)
    static let divider = Color.white.opacity(0.10)
    static let softFill = Color.white.opacity(0.08)
    static let hoverFill = Color.white.opacity(0.07)
    static let hoverStroke = Color.white.opacity(0.12)
    static let textPrimary = Color.white.opacity(0.96)
    static let textSecondary = Color.white.opacity(0.78)
    static let textTertiary = Color.white.opacity(0.56)
}

private struct HoverSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat
    let fill: Color
    let stroke: Color

    @State
    private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isHovered ? fill : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(isHovered ? stroke : Color.clear, lineWidth: 0.8)
            )
            .animation(.easeOut(duration: 0.16), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension View {
    func subtleHover(
        cornerRadius: CGFloat = 12,
        fill: Color = SpeedChrome.hoverFill,
        stroke: Color = SpeedChrome.hoverStroke
    ) -> some View {
        modifier(HoverSurfaceModifier(cornerRadius: cornerRadius, fill: fill, stroke: stroke))
    }
}
