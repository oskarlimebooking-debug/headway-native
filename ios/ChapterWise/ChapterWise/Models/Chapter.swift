import Foundation
import SwiftData

@Model
final class Chapter {
    @Attribute(.unique) var id: String
    var bookId: String
    var title: String
    @Attribute(.externalStorage) var content: String
    var order: Int
    var isComplete: Bool
    var readingTime: Int  // minutes
    var difficulty: Int   // 1-5
    @Attribute(.externalStorage) var audioData: Data?
    var audioProvider: String?  // "native", "lazybird", "google"

    var book: Book?

    @Relationship(deleteRule: .cascade, inverse: \GeneratedContent.chapter)
    var generatedContent: [GeneratedContent] = []

    init(id: String = UUID().uuidString, bookId: String, title: String, content: String, order: Int) {
        self.id = id
        self.bookId = bookId
        self.title = title
        self.content = content
        self.order = order
        self.isComplete = false
        self.readingTime = max(1, content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count / 200)
        self.difficulty = 0
    }
}
