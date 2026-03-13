import SwiftUI

struct MetricRowView: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let note: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.16))
                    .frame(width: 30, height: 30)

                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(note)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: unit.isEmpty ? 17 : 22, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
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
            .fill(Color.white.opacity(0.15))
            .frame(height: 1)
    }
}

enum SpeedPalette {
    static let stroke = Color.white.opacity(0.20)
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
                    .strokeBorder(SpeedPalette.stroke, lineWidth: 0.8)
            )
    }
}

extension View {
    func glassPill() -> some View {
        modifier(GlassPill())
    }

    func glassSection() -> some View {
        padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(SpeedPalette.stroke, lineWidth: 0.8)
        )
    }
}
