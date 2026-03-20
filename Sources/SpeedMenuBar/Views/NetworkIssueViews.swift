import SpeedCore
import SwiftUI

extension NetworkIssueRecord {
    var tintColor: Color {
        switch kind {
        case .timeout:
            return .yellow
        case .internetUnavailable:
            return .red
        case .failure:
            return .purple
        }
    }
}

struct NetworkIssueMarkerView: View {
    let issue: NetworkIssueRecord
    var isSelected = false
    var size: CGFloat = 16

    var body: some View {
        ZStack {
            Circle()
                .fill(issue.tintColor.opacity(isSelected ? 0.24 : 0.16))

            Circle()
                .stroke(issue.tintColor.opacity(isSelected ? 0.95 : 0.55), lineWidth: isSelected ? 1.2 : 0.9)

            Image(systemName: issue.kind.symbolName)
                .font(.system(size: size * 0.43, weight: .bold))
                .foregroundStyle(issue.tintColor)
        }
        .frame(width: size, height: size)
        .shadow(color: issue.tintColor.opacity(isSelected ? 0.22 : 0.12), radius: isSelected ? 8 : 4, y: 1)
    }
}

struct NetworkIssueBadgeView: View {
    let issue: NetworkIssueRecord
    let strings: SpeedStrings

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: issue.kind.symbolName)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(issue.tintColor)

            Text(issue.title(using: strings))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(SpeedChrome.textPrimary)
                .lineLimit(1)

            if issue.occurrenceCount > 1 {
                Text("\(issue.occurrenceCount)x")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(SpeedChrome.textSecondary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule(style: .continuous)
                .fill(issue.tintColor.opacity(0.12))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(issue.tintColor.opacity(0.22), lineWidth: 0.8)
        )
    }
}
