import Foundation
import SwiftData
import SwiftUI

@Observable
class LibraryViewModel {
    var searchText = ""
    var sortOption: SortOption = .recent
    var selectedTags: Set<String> = []
    var isMultiSelectMode = false
    var selectedBookIds: Set<String> = []
    var isImporting = false
    var importProgress: String?

    enum SortOption: String, CaseIterable {
        case recent = "Recent"
        case title = "Title"
        case progress = "Progress"
    }

    func filteredBooks(_ books: [Book]) -> [Book] {
        var result = books

        // Search filter
        if !searchText.isEmpty {
            result = result.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        // Tag filter
        if !selectedTags.isEmpty {
            result = result.filter { book in
                !selectedTags.isDisjoint(with: Set(book.tags))
            }
        }

        // Sort
        switch sortOption {
        case .recent:
            result.sort { ($0.lastReadAt ?? $0.addedAt) > ($1.lastReadAt ?? $1.addedAt) }
        case .title:
            result.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .progress:
            result.sort { $0.progress > $1.progress }
        }

        return result
    }

    func allTags(from books: [Book]) -> [String] {
        let tags = books.flatMap { $0.tags }
        return Array(Set(tags)).sorted()
    }

    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }

    func toggleBookSelection(_ bookId: String) {
        if selectedBookIds.contains(bookId) {
            selectedBookIds.remove(bookId)
        } else {
            selectedBookIds.insert(bookId)
        }
    }

    func dailySuggestion(from books: [Book], context: ModelContext) -> (book: Book, chapter: Chapter)? {
        let incompletBooks = books.filter { $0.progress < 1.0 }
        guard let book = incompletBooks.first(where: { $0.lastReadAt != nil }) ?? incompletBooks.first else {
            return nil
        }

        let descriptor = FetchDescriptor<Chapter>(
            predicate: #Predicate { $0.bookId == book.id && !$0.isComplete },
            sortBy: [SortDescriptor(\Chapter.order)]
        )

        guard let chapters = try? context.fetch(descriptor),
              let nextChapter = chapters.first else {
            return nil
        }

        return (book: book, chapter: nextChapter)
    }

    func stats(from books: [Book], context: ModelContext) -> (books: Int, chapters: Int, streak: Int) {
        let totalBooks = books.count
        let totalChapters = books.reduce(0) { $0 + $1.completedChapters }

        // Calculate streak
        var streak = 0
        let calendar = Calendar.current
        var date = Date()

        while true {
            let dateKey: String = {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter.string(from: date)
            }()

            let descriptor = FetchDescriptor<ReadingProgress>(
                predicate: #Predicate { $0.date == dateKey }
            )

            if let count = try? context.fetchCount(descriptor), count > 0 {
                streak += 1
                date = calendar.date(byAdding: .day, value: -1, to: date) ?? date
            } else {
                // Allow today to not have progress yet
                if streak == 0 && calendar.isDateInToday(date) {
                    date = calendar.date(byAdding: .day, value: -1, to: date) ?? date
                    continue
                }
                break
            }
        }

        return (books: totalBooks, chapters: totalChapters, streak: streak)
    }

    // MARK: - Import
    func importFile(url: URL, context: ModelContext) async throws {
        isImporting = true
        importProgress = "Reading file..."

        defer {
            Task { @MainActor in
                isImporting = false
                importProgress = nil
            }
        }

        let ext = url.pathExtension.lowercased()

        if ext == "pdf" {
            try await importPDF(url: url, context: context)
        } else if ext == "epub" {
            try await importEPUB(url: url, context: context)
        } else {
            throw ImportError.noContent
        }
    }

    private func importPDF(url: URL, context: ModelContext) async throws {
        await MainActor.run { importProgress = "Extracting text from PDF..." }

        let result = try await PDFImportService.shared.importPDF(from: url)

        await MainActor.run { importProgress = "Splitting into chapters..." }

        // Get API key
        let apiKey = try await getApiKey(context: context)
        let model = await getModel(context: context)

        let chapterData = try await GeminiService.shared.splitIntoChapters(
            text: result.text,
            bookTitle: result.title ?? "Untitled",
            apiKey: apiKey,
            model: model
        )

        await MainActor.run { importProgress = "Saving book..." }

        await saveBook(
            title: result.title ?? "Untitled",
            chapters: chapterData,
            pdfData: result.pdfData,
            context: context
        )
    }

    private func importEPUB(url: URL, context: ModelContext) async throws {
        await MainActor.run { importProgress = "Parsing EPUB..." }

        let result = try await EPUBImportService.shared.importEPUB(from: url)

        if let epubChapters = result.chapters, epubChapters.count > 1 {
            // EPUB already has chapter structure
            await MainActor.run { importProgress = "Saving book..." }
            await saveBook(
                title: result.title,
                chapters: epubChapters,
                coverData: result.coverImage,
                context: context
            )
        } else {
            // Need AI to split
            await MainActor.run { importProgress = "Splitting into chapters..." }
            let apiKey = try await getApiKey(context: context)
            let model = await getModel(context: context)

            let chapterData = try await GeminiService.shared.splitIntoChapters(
                text: result.text,
                bookTitle: result.title,
                apiKey: apiKey,
                model: model
            )

            await MainActor.run { importProgress = "Saving book..." }
            await saveBook(
                title: result.title,
                chapters: chapterData,
                coverData: result.coverImage,
                context: context
            )
        }
    }

    @MainActor
    private func saveBook(title: String, chapters: [(title: String, content: String)], pdfData: Data? = nil, coverData: Data? = nil, context: ModelContext) {
        let book = Book(title: title, totalChapters: chapters.count)
        book.originalPDFData = pdfData
        book.coverImageData = coverData
        context.insert(book)

        for (index, chapterData) in chapters.enumerated() {
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

    private func getApiKey(context: ModelContext) async throws -> String {
        let descriptor = FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.key == "geminiApiKey" }
        )
        guard let setting = try? context.fetch(descriptor).first, !setting.value.isEmpty else {
            throw GeminiServiceError.apiError("No API key configured. Please add your Gemini API key in Settings.")
        }
        return setting.value
    }

    private func getModel(context: ModelContext) async -> String? {
        let descriptor = FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.key == "geminiModel" }
        )
        return try? context.fetch(descriptor).first?.value
    }

    func deleteBooks(ids: Set<String>, context: ModelContext) {
        let descriptor = FetchDescriptor<Book>()
        guard let books = try? context.fetch(descriptor) else { return }

        for book in books where ids.contains(book.id) {
            context.delete(book)
        }
        try? context.save()
        selectedBookIds.removeAll()
    }
}
