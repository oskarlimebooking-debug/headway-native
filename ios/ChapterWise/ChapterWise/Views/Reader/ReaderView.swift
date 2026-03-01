import SwiftUI
import SwiftData

struct ReaderView: View {
    @Environment(\.modelContext) private var modelContext
    let chapter: Chapter
    let showToast: (String, ToastType) -> Void

    @State private var viewModel = ReaderViewModel()
    @State private var showMarkComplete = true

    var body: some View {
        ZStack {
            Theme.bgSurface.ignoresSafeArea()

            VStack(spacing: 0) {
                // Mode tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(ReaderMode.allCases) { mode in
                            Button(action: {
                                viewModel.currentMode = mode
                                if mode != .read {
                                    Task {
                                        await viewModel.loadContent(for: mode, chapter: chapter, context: modelContext)
                                    }
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: mode.icon)
                                        .font(.system(size: 11))
                                    Text(mode.rawValue)
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(viewModel.currentMode == mode ? Theme.accent : Theme.bgCard)
                                .foregroundColor(viewModel.currentMode == mode ? .white : Theme.textSecondary)
                                .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(Theme.bgSurface)

                Divider().background(Theme.border)

                // Content area
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(Theme.accent)
                            .scaleEffect(1.2)
                        Text("Generating content...")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 32))
                            .foregroundColor(Theme.warning)
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                await viewModel.loadContent(for: viewModel.currentMode, chapter: chapter, context: modelContext)
                            }
                        }
                        .foregroundColor(Theme.accent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    modeContent
                }

                // Mark complete button
                if showMarkComplete {
                    Button(action: {
                        chapter.isComplete.toggle()
                        if let book = chapter.book {
                            let bookId = book.id
                            let descriptor = FetchDescriptor<Chapter>(
                                predicate: #Predicate { $0.bookId == bookId && $0.isComplete == true }
                            )
                            book.completedChapters = (try? modelContext.fetchCount(descriptor)) ?? 0
                            if chapter.isComplete {
                                let progress = ReadingProgress(bookId: book.id, chapterId: chapter.id)
                                modelContext.insert(progress)
                                book.lastReadAt = Date()
                            }
                        }
                        try? modelContext.save()
                        showToast(chapter.isComplete ? "Chapter marked complete!" : "Chapter marked incomplete", .success)
                    }) {
                        HStack {
                            Image(systemName: chapter.isComplete ? "checkmark.circle.fill" : "circle")
                            Text(chapter.isComplete ? "Completed" : "Mark as Complete")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(chapter.isComplete ? Theme.success : Theme.accentGradient)
                        .cornerRadius(Theme.radiusMd)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, AudioPlayerService.shared.isVisible ? 70 : 16)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(chapter.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var modeContent: some View {
        switch viewModel.currentMode {
        case .read:
            ReadModeView(content: chapter.content)
        case .listen:
            ListenModeView(chapter: chapter, showToast: showToast)
        case .summary:
            SummaryModeView(result: viewModel.summaryResult)
        case .quiz:
            QuizModeView(viewModel: viewModel)
        case .flashcards:
            FlashcardModeView(viewModel: viewModel)
        case .chat:
            ChatModeView(viewModel: viewModel, chapter: chapter)
        case .teachBack:
            TeachBackModeView(viewModel: viewModel, chapter: chapter)
        case .socratic:
            SocraticModeView(viewModel: viewModel, chapter: chapter)
        case .mindMap:
            MindMapModeView(result: viewModel.mindMapResult)
        case .feed:
            FeedModeView(result: viewModel.feedResult)
        }
    }
}
