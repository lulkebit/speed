import SwiftUI

struct MetricCardView: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(SpeedPalette.secondaryText)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(SpeedPalette.primaryText)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(SpeedPalette.secondaryText)
                }
            }

            Text(note)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(SpeedPalette.secondaryText)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.78))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.95), lineWidth: 1)
        )
    }
}

enum SpeedPalette {
    static let primaryText = Color(red: 0.11, green: 0.19, blue: 0.28)
    static let secondaryText = Color(red: 0.29, green: 0.37, blue: 0.47)
    static let accent = Color(red: 0.14, green: 0.39, blue: 0.54)
    static let accentSoft = Color(red: 0.89, green: 0.95, blue: 0.97)
    static let coral = Color(red: 0.94, green: 0.55, blue: 0.39)
    static let sand = Color(red: 0.97, green: 0.93, blue: 0.88)
    static let mint = Color(red: 0.84, green: 0.92, blue: 0.87)
}
