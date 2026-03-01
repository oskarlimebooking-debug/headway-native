import Foundation
import SwiftData

@Model
final class Book {
    @Attribute(.unique) var id: String
    var title: String
    var emoji: String
    var tags: [String]
    var addedAt: Date
    var totalChapters: Int
    var completedChapters: Int
    @Attribute(.externalStorage) var coverImageData: Data?
    @Attribute(.externalStorage) var originalPDFData: Data?
    var lastReadAt: Date?
    var lastChapterId: String?

    @Relationship(deleteRule: .cascade, inverse: \Chapter.book)
    var chapters: [Chapter] = []

    var progress: Double {
        guard totalChapters > 0 else { return 0 }
        return Double(completedChapters) / Double(totalChapters)
    }

    init(id: String = UUID().uuidString, title: String, emoji: String = "📖", tags: [String] = [], totalChapters: Int = 0) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.tags = tags
        self.addedAt = Date()
        self.totalChapters = totalChapters
        self.completedChapters = 0
    }
}
