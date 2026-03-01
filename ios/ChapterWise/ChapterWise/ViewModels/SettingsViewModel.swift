import Foundation
import SwiftData

@Observable
class SettingsViewModel {
    var geminiApiKey = ""
    var selectedModel = Constants.defaultModel
    var selectedImageModel = Constants.imageModels.first ?? ""
    var readingSpeed = "200"
    var ttsProvider = "native"

    // Lazybird
    var lazybirdApiKey = ""
    var lazybirdVoiceId = ""
    var lazybirdLanguage = ""
    var lazybirdVoices: [LazyBirdTTSService.Voice] = []

    // Google TTS
    var googleTTSApiKey = ""
    var googleTTSVoice = ""
    var googleTTSLanguage = "en-US"
    var googleTTSModel = ""
    var googleTTSVoices: [GoogleTTSService.Voice] = []

    // Google Drive
    var googleClientId = ""
    var isSyncConnected = false
    var lastSyncTime: String?
    var isSyncing = false

    func loadSettings(context: ModelContext) {
        geminiApiKey = getSetting("geminiApiKey", context: context) ?? ""
        selectedModel = getSetting("geminiModel", context: context) ?? Constants.defaultModel
        selectedImageModel = getSetting("imageModel", context: context) ?? Constants.imageModels.first ?? ""
        readingSpeed = getSetting("readingSpeed", context: context) ?? "200"
        ttsProvider = getSetting("ttsProvider", context: context) ?? "native"
        lazybirdApiKey = getSetting("lazybirdApiKey", context: context) ?? ""
        lazybirdVoiceId = getSetting("lazybirdVoiceId", context: context) ?? ""
        lazybirdLanguage = getSetting("lazybirdLanguage", context: context) ?? ""
        googleTTSApiKey = getSetting("googleTTSApiKey", context: context) ?? ""
        googleTTSVoice = getSetting("googleTTSVoice", context: context) ?? ""
        googleTTSLanguage = getSetting("googleTTSLanguage", context: context) ?? "en-US"
        googleTTSModel = getSetting("googleTTSModel", context: context) ?? ""
        googleClientId = getSetting("googleClientId", context: context) ?? ""
        lastSyncTime = getSetting("lastSyncTime", context: context)
        isSyncConnected = getSetting("googleAccessToken", context: context) != nil
    }

    func saveSettings(context: ModelContext) {
        saveSetting("geminiApiKey", value: geminiApiKey, context: context)
        saveSetting("geminiModel", value: selectedModel, context: context)
        saveSetting("imageModel", value: selectedImageModel, context: context)
        saveSetting("readingSpeed", value: readingSpeed, context: context)
        saveSetting("ttsProvider", value: ttsProvider, context: context)
        saveSetting("lazybirdApiKey", value: lazybirdApiKey, context: context)
        saveSetting("lazybirdVoiceId", value: lazybirdVoiceId, context: context)
        saveSetting("lazybirdLanguage", value: lazybirdLanguage, context: context)
        saveSetting("googleTTSApiKey", value: googleTTSApiKey, context: context)
        saveSetting("googleTTSVoice", value: googleTTSVoice, context: context)
        saveSetting("googleTTSLanguage", value: googleTTSLanguage, context: context)
        saveSetting("googleTTSModel", value: googleTTSModel, context: context)
        saveSetting("googleClientId", value: googleClientId, context: context)
        try? context.save()
    }

    func fetchLazybirdVoices() async {
        guard !lazybirdApiKey.isEmpty else { return }
        do {
            lazybirdVoices = try await LazyBirdTTSService.shared.fetchVoices(apiKey: lazybirdApiKey)
        } catch {
            print("Failed to fetch Lazybird voices: \(error)")
        }
    }

    func fetchGoogleTTSVoices() async {
        guard !googleTTSApiKey.isEmpty else { return }
        do {
            googleTTSVoices = try await GoogleTTSService.shared.fetchVoices(apiKey: googleTTSApiKey)
        } catch {
            print("Failed to fetch Google TTS voices: \(error)")
        }
    }

    private func getSetting(_ key: String, context: ModelContext) -> String? {
        let descriptor = FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.key == key }
        )
        return try? context.fetch(descriptor).first?.value
    }

    private func saveSetting(_ key: String, value: String, context: ModelContext) {
        let descriptor = FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.key == key }
        )

        if let existing = try? context.fetch(descriptor).first {
            existing.value = value
        } else if !value.isEmpty {
            let setting = AppSettings(key: key, value: value)
            context.insert(setting)
        }
    }
}
