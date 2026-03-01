import Foundation
import SwiftData

actor DataExportService {
    static let shared = DataExportService()

    struct ExportData: Codable {
        let version: String
        let exportDate: String
        let books: [ExportBook]
        let progress: [ExportProgress]
    }

    struct ExportBook: Codable {
        let id: String
        let title: String
        let emoji: String
        let tags: [String]
        let addedAt: String
        let totalChapters: Int
        let completedChapters: Int
        let chapters: [ExportChapter]
    }

    struct ExportChapter: Codable {
        let id: String
        let title: String
        let content: String
        let order: Int
        let isComplete: Bool
        let readingTime: Int
        let difficulty: Int
    }

    struct ExportProgress: Codable {
        let date: String
        let bookId: String
        let chapterId: String
    }

    func exportAll(context: ModelContext) async throws -> Data {
        let books = try context.fetch(FetchDescriptor<Book>())
        let allProgress = try context.fetch(FetchDescriptor<ReadingProgress>())

        let dateFormatter = ISO8601DateFormatter()

        let exportBooks = books.map { book -> ExportBook in
            let bookId = book.id
            let descriptor = FetchDescriptor<Chapter>(
                predicate: #Predicate { $0.bookId == bookId },
                sortBy: [SortDescriptor(\Chapter.order)]
            )
            let chapters = (try? context.fetch(descriptor)) ?? []

            return ExportBook(
                id: book.id,
                title: book.title,
                emoji: book.emoji,
                tags: book.tags,
                addedAt: dateFormatter.string(from: book.addedAt),
                totalChapters: book.totalChapters,
                completedChapters: book.completedChapters,
                chapters: chapters.map { ch in
                    ExportChapter(
                        id: ch.id,
                        title: ch.title,
                        content: ch.content,
                        order: ch.order,
                        isComplete: ch.isComplete,
                        readingTime: ch.readingTime,
                        difficulty: ch.difficulty
                    )
                }
            )
        }

        let exportProgress = allProgress.map { p in
            ExportProgress(date: p.date, bookId: p.bookId, chapterId: p.chapterId)
        }

        let export = ExportData(
            version: "1.0.0",
            exportDate: dateFormatter.string(from: Date()),
            books: exportBooks,
            progress: exportProgress
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(export)
    }

    func importData(_ data: Data, context: ModelContext) async throws {
        let decoder = JSONDecoder()
        let importData = try decoder.decode(ExportData.self, from: data)

        for importBook in importData.books {
            // Check if book already exists
            let bookId = importBook.id
            let existingDescriptor = FetchDescriptor<Book>(
                predicate: #Predicate { $0.id == bookId }
            )
            if let existing = try? context.fetch(existingDescriptor).first {
                // Update existing
                existing.title = importBook.title
                existing.emoji = importBook.emoji
                existing.tags = importBook.tags
                existing.totalChapters = importBook.totalChapters
                existing.completedChapters = importBook.completedChapters
            } else {
                // Create new
                let book = Book(id: importBook.id, title: importBook.title, emoji: importBook.emoji, tags: importBook.tags, totalChapters: importBook.totalChapters)
                book.completedChapters = importBook.completedChapters
                context.insert(book)

                for importChapter in importBook.chapters {
                    let chapter = Chapter(
                        id: importChapter.id,
                        bookId: importBook.id,
                        title: importChapter.title,
                        content: importChapter.content,
                        order: importChapter.order
                    )
                    chapter.isComplete = importChapter.isComplete
                    chapter.readingTime = importChapter.readingTime
                    chapter.difficulty = importChapter.difficulty
                    chapter.book = book
                    context.insert(chapter)
                }
            }
        }

        try context.save()
    }
}
