import Foundation
import SwiftData

@Model
final class ReadingProgress {
    @Attribute(.unique) var id: String
    var date: String      // "yyyy-MM-dd"
    var bookId: String
    var chapterId: String
    var completedAt: Date

    init(bookId: String, chapterId: String) {
        self.id = UUID().uuidString
        self.date = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: Date())
        }()
        self.bookId = bookId
        self.chapterId = chapterId
        self.completedAt = Date()
    }
}
