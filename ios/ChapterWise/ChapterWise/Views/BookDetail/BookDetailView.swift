import SwiftUI
import SwiftData

struct BookDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let book: Book
    let onChapterSelected: (Chapter) -> Void
    let showToast: (String, ToastType) -> Void

    @State private var viewModel = BookDetailViewModel()
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            Theme.bgSurface.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Book header
                    VStack(spacing: 12) {
                        // Cover
                        if let coverData = book.coverImageData,
                           let uiImage = UIImage(data: coverData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(3/4, contentMode: .fit)
                                .frame(height: 200)
                                .cornerRadius(Theme.radiusMd)
                                .shadow(color: Theme.shadow, radius: 12)
                        } else {
                            RoundedRectangle(cornerRadius: Theme.radiusMd)
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.bgElevated, Theme.bgCard],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 150, height: 200)
                                .overlay(
                                    Text(book.emoji)
                                        .font(.system(size: 60))
                                )
                                .shadow(color: Theme.shadow, radius: 12)
                        }

                        Text(book.title)
                            .font(.system(size: 24, weight: .semibold, design: .serif))
                            .foregroundColor(Theme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("\(book.totalChapters) chapters • \(Int(book.progress * 100))% complete")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSecondary)

                        // Tags
                        if !book.tags.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(book.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 12))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Theme.accentSoft)
                                        .foregroundColor(Theme.accent)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding(.top, 12)

                    // Action buttons
                    HStack(spacing: 12) {
                        ActionButton(icon: "pencil", label: "Edit") {
                            viewModel.loadEditData(from: book)
                        }

                        ActionButton(icon: "arrow.triangle.2.circlepath", label: "Re-split") {
                            Task {
                                do {
                                    try await viewModel.reSplitChapters(book: book, context: modelContext)
                                    showToast("Chapters re-split successfully", .success)
                                } catch {
                                    showToast("Failed: \(error.localizedDescription)", .error)
                                }
                            }
                        }

                        ActionButton(icon: "trash", label: "Delete", isDestructive: true) {
                            showDeleteConfirm = true
                        }
                    }

                    // Chapter list
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Chapters")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.textSecondary)

                        let chapters = viewModel.sortedChapters(for: book, context: modelContext)
                        ForEach(chapters) { chapter in
                            ChapterRowView(
                                chapter: chapter,
                                number: chapter.order + 1,
                                onTap: { onChapterSelected(chapter) },
                                onToggleComplete: {
                                    viewModel.toggleChapterComplete(chapter, book: book, context: modelContext)
                                }
                            )
                        }
                    }
                }
                .padding(24)
                .padding(.bottom, 80)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Book Details")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
            }
        }
        .sheet(isPresented: $viewModel.isEditingBook) {
            EditBookView(viewModel: viewModel, book: book)
        }
        .alert("Delete Book", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                viewModel.deleteBook(book, context: modelContext)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete \"\(book.title)\"? This cannot be undone.")
        }
    }
}

private struct ActionButton: View {
    let icon: String
    let label: String
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 11))
            }
            .foregroundColor(isDestructive ? Theme.error : Theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Theme.bgCard)
            .cornerRadius(Theme.radiusSm)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusSm)
                    .stroke(Theme.border, lineWidth: 1)
            )
        }
    }
}
