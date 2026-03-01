import SwiftUI
import SwiftData

struct EditBookView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: BookDetailViewModel
    let book: Book

    let emojiOptions = ["📖", "📚", "📘", "📕", "📗", "📙", "📓", "📔", "🎓", "🧠", "💡", "🔬", "🎨", "🌍", "💻", "📊", "🏛️", "⚡"]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgSurface.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Emoji picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Icon")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.textSecondary)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                ForEach(emojiOptions, id: \.self) { emoji in
                                    Button(action: { viewModel.editEmoji = emoji }) {
                                        Text(emoji)
                                            .font(.system(size: 28))
                                            .frame(width: 44, height: 44)
                                            .background(viewModel.editEmoji == emoji ? Theme.accentSoft : Theme.bgElevated)
                                            .cornerRadius(Theme.radiusSm)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: Theme.radiusSm)
                                                    .stroke(viewModel.editEmoji == emoji ? Theme.accent : Color.clear, lineWidth: 2)
                                            )
                                    }
                                }
                            }
                        }

                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.textSecondary)

                            TextField("Book title", text: $viewModel.editTitle)
                                .padding(12)
                                .background(Theme.bgElevated)
                                .cornerRadius(Theme.radiusSm)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.radiusSm)
                                        .stroke(Theme.border, lineWidth: 1)
                                )
                                .foregroundColor(Theme.textPrimary)
                        }

                        // Tags
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags (comma separated)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.textSecondary)

                            TextField("e.g., Science, Philosophy, Self-Help", text: $viewModel.editTags)
                                .padding(12)
                                .background(Theme.bgElevated)
                                .cornerRadius(Theme.radiusSm)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.radiusSm)
                                        .stroke(Theme.border, lineWidth: 1)
                                )
                                .foregroundColor(Theme.textPrimary)
                        }

                        // Save button
                        Button(action: {
                            viewModel.saveEdits(book: book, context: modelContext)
                            dismiss()
                        }) {
                            Text("Save Changes")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Theme.accentGradient)
                                .cornerRadius(Theme.radiusMd)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Edit Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
        }
    }
}
