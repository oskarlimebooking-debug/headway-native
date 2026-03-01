import Foundation
import SwiftData

@Observable
class AudioViewModel {
    var ttsProvider: String = "native"  // "native", "lazybird", "google"
    var isGenerating = false
    var generationProgress: String?

    func generateAudio(for chapter: Chapter, context: ModelContext) async {
        isGenerating = true
        generationProgress = "Generating audio..."

        defer {
            Task { @MainActor in
                isGenerating = false
                generationProgress = nil
            }
        }

        do {
            let apiKey = try getApiKey(context: context, key: ttsProvider == "lazybird" ? "lazybirdApiKey" : ttsProvider == "google" ? "googleTTSApiKey" : "geminiApiKey")

            var audioData: Data

            switch ttsProvider {
            case "lazybird":
                let voiceId = getSetting(context: context, key: "lazybirdVoiceId") ?? ""
                audioData = try await LazyBirdTTSService.shared.generateSpeech(
                    text: chapter.content,
                    voiceId: voiceId,
                    apiKey: apiKey
                )
            case "google":
                let voiceName = getSetting(context: context, key: "googleTTSVoice") ?? "en-US-Neural2-C"
                let langCode = getSetting(context: context, key: "googleTTSLanguage") ?? "en-US"
                audioData = try await GoogleTTSService.shared.generateSpeech(
                    text: chapter.content,
                    voiceName: voiceName,
                    languageCode: langCode,
                    apiKey: apiKey
                )
            default:
                return  // Native TTS doesn't generate audio data
            }

            await MainActor.run {
                chapter.audioData = audioData
                chapter.audioProvider = ttsProvider
                try? context.save()
            }

            // Play it
            let book = chapter.book
            AudioPlayerService.shared.loadAndPlay(
                data: audioData,
                chapterTitle: chapter.title,
                bookTitle: book?.title ?? "Unknown",
                chapterId: chapter.id,
                bookId: book?.id ?? ""
            )
        } catch {
            await MainActor.run {
                generationProgress = "Error: \(error.localizedDescription)"
            }
        }
    }

    func playExistingAudio(for chapter: Chapter) {
        guard let audioData = chapter.audioData else { return }
        AudioPlayerService.shared.loadAndPlay(
            data: audioData,
            chapterTitle: chapter.title,
            bookTitle: chapter.book?.title ?? "Unknown",
            chapterId: chapter.id,
            bookId: chapter.book?.id ?? ""
        )
    }

    private func getApiKey(context: ModelContext, key: String) throws -> String {
        let descriptor = FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.key == key }
        )
        guard let setting = try? context.fetch(descriptor).first, !setting.value.isEmpty else {
            throw GeminiServiceError.apiError("API key not configured for \(key)")
        }
        return setting.value
    }

    private func getSetting(context: ModelContext, key: String) -> String? {
        let descriptor = FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.key == key }
        )
        return try? context.fetch(descriptor).first?.value
    }
}
