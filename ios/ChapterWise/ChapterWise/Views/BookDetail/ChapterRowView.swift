import SwiftUI

struct ChapterRowView: View {
    let chapter: Chapter
    let number: Int
    let onTap: () -> Void
    let onToggleComplete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Completion toggle
            Button(action: onToggleComplete) {
                ZStack {
                    Circle()
                        .stroke(chapter.isComplete ? Theme.success : Theme.border, lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if chapter.isComplete {
                        Circle()
                            .fill(Theme.success)
                            .frame(width: 28, height: 28)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            // Chapter info
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Chapter \(number)")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textMuted)

                        if chapter.audioData != nil {
                            Image(systemName: "headphones")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.accent)
                        }
                    }

                    Text(chapter.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(chapter.isComplete ? Theme.textSecondary : Theme.textPrimary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        if chapter.readingTime > 0 {
                            Label("\(chapter.readingTime) min", systemImage: "clock")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textMuted)
                        }
                        if chapter.difficulty > 0 {
                            HStack(spacing: 2) {
                                ForEach(0..<5, id: \.self) { i in
                                    Circle()
                                        .fill(i < chapter.difficulty ? Theme.accent : Theme.bgElevated)
                                        .frame(width: 5, height: 5)
                                }
                            }
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusMd)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusMd)
                .stroke(chapter.isComplete ? Theme.success.opacity(0.3) : Theme.border, lineWidth: 1)
        )
    }
}
