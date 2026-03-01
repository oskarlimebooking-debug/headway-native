import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.addedAt, order: .reverse) private var books: [Book]
    @State private var viewModel = LibraryViewModel()

    let onBookSelected: (Book) -> Void
    let onShowSettings: () -> Void
    let onShowImporter: () -> Void
    let showToast: (String, ToastType) -> Void

    var body: some View {
        ZStack {
            Theme.bgSurface.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Daily Suggestion
                    if let suggestion = viewModel.dailySuggestion(from: books, context: modelContext) {
                        DailySuggestionCard(
                            bookTitle: suggestion.book.title,
                            chapterTitle: suggestion.chapter.title,
                            chapterNumber: suggestion.chapter.order + 1,
                            totalChapters: suggestion.book.totalChapters
                        ) {
                            onBookSelected(suggestion.book)
                        }
                    }

                    // Stats
                    let stats = viewModel.stats(from: books, context: modelContext)
                    StatsBarView(
                        bookCount: stats.books,
                        chapterCount: stats.chapters,
                        streak: stats.streak
                    )

                    // Library toolbar
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            // Search
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(Theme.textMuted)
                                TextField("Search books...", text: $viewModel.searchText)
                                    .foregroundColor(Theme.textPrimary)
                                if !viewModel.searchText.isEmpty {
                                    Button(action: { viewModel.searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(Theme.textMuted)
                                    }
                                }
                            }
                            .padding(10)
                            .background(Theme.bgElevated)
                            .cornerRadius(Theme.radiusSm)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.radiusSm)
                                    .stroke(Theme.border, lineWidth: 1)
                            )

                            // Sort
                            Menu {
                                ForEach(LibraryViewModel.SortOption.allCases, id: \.self) { option in
                                    Button(action: { viewModel.sortOption = option }) {
                                        HStack {
                                            Text(option.rawValue)
                                            if viewModel.sortOption == option {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: "arrow.up.arrow.down")
                                    .foregroundColor(Theme.textSecondary)
                                    .padding(10)
                                    .background(Theme.bgElevated)
                                    .cornerRadius(Theme.radiusSm)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.radiusSm)
                                            .stroke(Theme.border, lineWidth: 1)
                                    )
                            }
                        }

                        // Tag filters
                        let allTags = viewModel.allTags(from: books)
                        if !allTags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(allTags, id: \.self) { tag in
                                        TagChipView(
                                            tag: tag,
                                            isSelected: viewModel.selectedTags.contains(tag)
                                        ) {
                                            viewModel.toggleTag(tag)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Book grid
                    let filtered = viewModel.filteredBooks(books)
                    if filtered.isEmpty {
                        VStack(spacing: 16) {
                            Text("\u{1F4DA}")
                                .font(.system(size: 48))
                            Text(books.isEmpty ? "Your library is empty" : "No books match your search")
                                .font(.system(size: 16, design: .default))
                                .foregroundColor(Theme.textSecondary)
                            if books.isEmpty {
                                Text("Tap + to add your first book")
                                    .font(.system(size: 14, design: .default))
                                    .foregroundColor(Theme.textMuted)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(filtered) { book in
                                BookCardView(book: book) {
                                    onBookSelected(book)
                                }
                            }
                        }
                    }
                }
                .padding(24)
                .padding(.bottom, 80)
            }

            // Import FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { onShowImporter() }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Theme.accentGradient)
                            .clipShape(Circle())
                            .shadow(color: Theme.accent.opacity(0.4), radius: 12, x: 0, y: 4)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, AudioPlayerService.shared.isVisible ? 80 : 24)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("ChapterWise")
                    .font(.system(size: 24, weight: .bold, design: .default))
                    .foregroundStyle(Theme.headerGradient)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: onShowSettings) {
                    Image(systemName: "gearshape")
                        .foregroundColor(Theme.textSecondary)
                        .padding(8)
                        .background(Theme.bgCard)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Theme.border, lineWidth: 1))
                }
            }
        }
    }
}
