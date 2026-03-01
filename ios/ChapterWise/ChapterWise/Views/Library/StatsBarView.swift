import SwiftUI

struct StatsBarView: View {
    let bookCount: Int
    let chapterCount: Int
    let streak: Int

    var body: some View {
        HStack(spacing: 0) {
            StatItem(value: "\(bookCount)", label: "Books")
            StatItem(value: "\(chapterCount)", label: "Chapters")
            StatItem(value: "\(streak)", label: "Day Streak")
        }
        .padding(.vertical, 16)
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusMd)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusMd)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
}

private struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Theme.textMuted)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }
}
