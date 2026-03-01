import Foundation
import SwiftData

enum ContentType: String, Codable {
    case summary
    case quiz
    case flashcards
    case teachback
    case mindmap
    case feed
    case chat
    case socratic
    case formattedText
    case ttsCleanText
}

@Model
final class GeneratedContent {
    @Attribute(.unique) var id: String
    var chapterId: String
    var typeRaw: String  // ContentType raw value
    @Attribute(.externalStorage) var jsonData: String
    var createdAt: Date

    var chapter: Chapter?

    var type: ContentType {
        get { ContentType(rawValue: typeRaw) ?? .summary }
        set { typeRaw = newValue.rawValue }
    }

    init(id: String = UUID().uuidString, chapterId: String, type: ContentType, jsonData: String) {
        self.id = id
        self.chapterId = chapterId
        self.typeRaw = type.rawValue
        self.jsonData = jsonData
        self.createdAt = Date()
    }
}
