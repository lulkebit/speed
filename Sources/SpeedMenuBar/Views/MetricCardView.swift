import SwiftUI

struct MetricRowView: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let note: String

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(SpeedChrome.iconFill)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .strokeBorder(SpeedChrome.iconStroke, lineWidth: 0.8)
                    )

                Image(systemName: icon)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(note)
                    .font(.system(size: 11.5, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: unit.isEmpty ? 16 : 22, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .multilineTextAlignment(.trailing)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minWidth: 78, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }
}

struct FrostedBackground: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.regularMaterial.opacity(0.92))

            LinearGradient(
                colors: [
                    Color.white.opacity(0.16),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct GlassDivider: View {
    var body: some View {
        Rectangle()
            .fill(SpeedChrome.divider)
            .frame(height: 1)
    }
}

enum SpeedChrome {
    static let panelWidth: CGFloat = 372
    static let panelCornerRadius: CGFloat = 20
    static let sectionCornerRadius: CGFloat = 18
    static let brand = Color(red: 0.20, green: 0.55, blue: 0.98)
    static let stroke = Color.white.opacity(0.16)
    static let divider = Color.white.opacity(0.11)
    static let iconFill = Color.white.opacity(0.09)
    static let iconStroke = Color.white.opacity(0.08)
}

struct GlassPill: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(.thinMaterial)
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(SpeedChrome.stroke, lineWidth: 0.8)
            )
    }
}

enum GlassSectionProminence {
    case standard
    case prominent
}

private struct GlassSectionModifier: ViewModifier {
    let prominence: GlassSectionProminence

    func body(content: Content) -> some View {
        let highlight = prominence == .prominent ? Color.white.opacity(0.06) : Color.white.opacity(0.03)
        let shadowOpacity = prominence == .prominent ? 0.10 : 0.05

        return content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: SpeedChrome.sectionCornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: SpeedChrome.sectionCornerRadius, style: .continuous)
                            .fill(highlight)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: SpeedChrome.sectionCornerRadius, style: .continuous)
                    .strokeBorder(SpeedChrome.stroke, lineWidth: 0.8)
            )
            .shadow(color: .black.opacity(shadowOpacity), radius: 14, y: 6)
    }
}

extension View {
    func glassPill() -> some View {
        modifier(GlassPill())
    }

    func glassSection(prominence: GlassSectionProminence = .standard) -> some View {
        modifier(GlassSectionModifier(prominence: prominence))
    }
}
