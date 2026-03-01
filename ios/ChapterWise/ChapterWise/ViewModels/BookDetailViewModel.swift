import Foundation
import SwiftData

@Observable
class BookDetailViewModel {
    var isEditingBook = false
    var editTitle = ""
    var editEmoji = ""
    var editTags = ""
    var isGeneratingAudio = false
    var audioProgress: String?

    func loadEditData(from book: Book) {
        editTitle = book.title
        editEmoji = book.emoji
        editTags = book.tags.joined(separator: ", ")
        isEditingBook = true
    }

    func saveEdits(book: Book, context: ModelContext) {
        book.title = editTitle
        book.emoji = editEmoji
        book.tags = editTags.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        try? context.save()
        isEditingBook = false
    }

    func sortedChapters(for book: Book, context: ModelContext) -> [Chapter] {
        let bookId = book.id
        let descriptor = FetchDescriptor<Chapter>(
            predicate: #Predicate { $0.bookId == bookId },
            sortBy: [SortDescriptor(\Chapter.order)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func toggleChapterComplete(_ chapter: Chapter, book: Book, context: ModelContext) {
        chapter.isComplete.toggle()

        let bookId = book.id
        let descriptor = FetchDescriptor<Chapter>(
            predicate: #Predicate { $0.bookId == bookId && $0.isComplete == true }
        )
        book.completedChapters = (try? context.fetchCount(descriptor)) ?? 0

        if chapter.isComplete {
            let progress = ReadingProgress(bookId: book.id, chapterId: chapter.id)
            context.insert(progress)
            book.lastReadAt = Date()
            book.lastChapterId = chapter.id
        }

        try? context.save()
    }

    func deleteBook(_ book: Book, context: ModelContext) {
        context.delete(book)
        try? context.save()
    }

    func reSplitChapters(book: Book, context: ModelContext) async throws {
        // Delete existing chapters
        let bookId = book.id
        let descriptor = FetchDescriptor<Chapter>(
            predicate: #Predicate { $0.bookId == bookId }
        )
        if let chapters = try? context.fetch(descriptor) {
            let fullText = chapters.sorted(by: { $0.order < $1.order }).map { $0.content }.joined(separator: "\n\n")

            for chapter in chapters {
                context.delete(chapter)
            }

            // Re-split
            let apiKeyDescriptor = FetchDescriptor<AppSettings>(
                predicate: #Predicate { $0.key == "geminiApiKey" }
            )
            guard let apiKey = try? context.fetch(apiKeyDescriptor).first?.value else {
                throw GeminiServiceError.apiError("No API key configured")
            }

            let newChapters = try await GeminiService.shared.splitIntoChapters(
                text: fullText,
                bookTitle: book.title,
                apiKey: apiKey
            )

            await MainActor.run {
                book.totalChapters = newChapters.count
                book.completedChapters = 0

                for (index, chapterData) in newChapters.enumerated() {
                    let chapter = Chapter(
                        bookId: book.id,
                        title: chapterData.title,
                        content: chapterData.content,
                        order: index
                    )
                    chapter.book = book
                    context.insert(chapter)
                }

                try? context.save()
            }
        }
    }
}
