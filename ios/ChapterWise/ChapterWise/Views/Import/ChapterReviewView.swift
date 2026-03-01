import SwiftUI

struct ChapterReviewView: View {
    let chapters: [(title: String, content: String)]
    let bookTitle: String
    let onConfirm: ([(title: String, content: String)]) -> Void
    let onCancel: () -> Void

    @State private var editableChapters: [(title: String, content: String)]
    @State private var expandedIndex: Int?

    init(chapters: [(title: String, content: String)], bookTitle: String, onConfirm: @escaping ([(title: String, content: String)]) -> Void, onCancel: @escaping () -> Void) {
        self.chapters = chapters
        self.bookTitle = bookTitle
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        self._editableChapters = State(initialValue: chapters)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgSurface.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        Text("Review \(editableChapters.count) detected chapters")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSecondary)
                            .padding(.bottom, 8)

                        ForEach(Array(editableChapters.enumerated()), id: \.offset) { index, chapter in
                            VStack(alignment: .leading, spacing: 8) {
                                Button(action: {
                                    withAnimation {
                                        expandedIndex = expandedIndex == index ? nil : index
                                    }
                                }) {
                                    HStack {
                                        Text("Chapter \(index + 1)")
                                            .font(.system(size: 12))
                                            .foregroundColor(Theme.textMuted)

                                        Text(chapter.title)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Theme.textPrimary)
                                            .lineLimit(1)

                                        Spacer()

                                        let wordCount = chapter.content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
                                        Text("\(wordCount) words")
                                            .font(.system(size: 11))
                                            .foregroundColor(Theme.textMuted)

                                        Image(systemName: expandedIndex == index ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 11))
                                            .foregroundColor(Theme.textMuted)
                                    }
                                }
                                .buttonStyle(.plain)

                                if expandedIndex == index {
                                    Text(String(chapter.content.prefix(500)))
                                        .font(.system(size: 13, design: .serif))
                                        .foregroundColor(Theme.textSecondary)
                                        .lineSpacing(4)
                                        .padding(.top, 4)

                                    if chapter.content.count > 500 {
                                        Text("... (\(chapter.content.count) characters total)")
                                            .font(.system(size: 11))
                                            .foregroundColor(Theme.textMuted)
                                    }
                                }
                            }
                            .padding(12)
                            .background(Theme.bgCard)
                            .cornerRadius(Theme.radiusSm)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.radiusSm)
                                    .stroke(Theme.border, lineWidth: 1)
                            )
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 80)
                }

                // Bottom buttons
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Button(action: onCancel) {
                            Text("Cancel")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Theme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Theme.bgCard)
                                .cornerRadius(Theme.radiusMd)
                        }

                        Button(action: { onConfirm(editableChapters) }) {
                            Text("Confirm & Import")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Theme.accentGradient)
                                .cornerRadius(Theme.radiusMd)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Theme.bgSurface)
                }
            }
            .navigationTitle("Review Chapters")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
