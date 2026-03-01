import Foundation
import SwiftData

@Model
final class AppSettings {
    @Attribute(.unique) var key: String
    var value: String

    init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

// MARK: - Settings Keys
enum SettingsKey: String {
    case geminiApiKey
    case geminiModel
    case imageModel
    case readingSpeed
    case useLazybirdTTS
    case lazybirdApiKey
    case lazybirdVoiceId
    case lazybirdLanguage
    case googleTTSApiKey
    case googleTTSVoice
    case googleTTSLanguage
    case googleTTSModel
    case googleClientId
    case googleAccessToken
    case googleTokenExpiry
    case lastSyncTime
    case ttsProvider  // "native", "lazybird", "google"
}
