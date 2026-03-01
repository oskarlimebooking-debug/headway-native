import SwiftUI

struct DailySuggestionCard: View {
    let bookTitle: String
    let chapterTitle: String
    let chapterNumber: Int
    let totalChapters: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text("TODAY'S READING")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.5)
                    .foregroundColor(.white.opacity(0.8))

                Text(bookTitle)
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundColor(.white)

                Text("Chapter \(chapterNumber) of \(totalChapters) \u{2022} \(chapterTitle)")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))

                HStack {
                    Text("Continue Reading")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusMd)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(Theme.radiusMd)

                    Spacer()
                }
                .padding(.top, 4)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.accentGradient)
            .cornerRadius(Theme.radiusLg)
        }
        .buttonStyle(.plain)
    }
}
