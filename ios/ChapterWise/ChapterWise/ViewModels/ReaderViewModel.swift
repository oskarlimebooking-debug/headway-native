import Foundation
import SwiftData

enum ReaderMode: String, CaseIterable, Identifiable {
    case read = "Read"
    case listen = "Listen"
    case summary = "Summary"
    case quiz = "Quiz"
    case flashcards = "Cards"
    case chat = "Chat"
    case teachBack = "Teach"
    case socratic = "Socratic"
    case mindMap = "Map"
    case feed = "Feed"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .read: return "book"
        case .listen: return "headphones"
        case .summary: return "doc.text"
        case .quiz: return "questionmark.circle"
        case .flashcards: return "rectangle.on.rectangle"
        case .chat: return "bubble.left.and.bubble.right"
        case .teachBack: return "person.wave.2"
        case .socratic: return "brain.head.profile"
        case .mindMap: return "point.3.connected.trianglepath.dotted"
        case .feed: return "newspaper"
        }
    }
}

@Observable
class ReaderViewModel {
    var currentMode: ReaderMode = .read
    var isLoading = false
    var error: String?

    // Summary
    var summaryResult: SummaryResult?

    // Quiz
    var quizResult: QuizResult?
    var currentQuizIndex = 0
    var quizAnswers: [Int?] = []
    var quizSubmitted = false

    // Flashcards
    var flashcardsResult: FlashcardsResult?
    var currentFlashcardIndex = 0
    var isFlipped = false

    // Chat
    var chatMessages: [(role: String, content: String)] = []
    var chatInput = ""
    var isChatLoading = false

    // Teach Back
    var teachBackInput = ""
    var teachBackResult: TeachBackResult?

    // Socratic
    var socraticHistory: [(role: String, content: String)] = []
    var socraticResult: SocraticResult?
    var socraticInput = ""

    // Mind Map
    var mindMapResult: MindMapResult?

    // Feed
    var feedResult: FeedResult?

    // Cache tracking
    private var loadedModes: Set<ReaderMode> = [.read]

    func loadContent(for mode: ReaderMode, chapter: Chapter, context: ModelContext) async {
        guard !loadedModes.contains(mode) else { return }

        isLoading = true
        error = nil

        do {
            // Check cache first
            let chapterId = chapter.id
            let typeRaw = contentType(for: mode).rawValue
            let descriptor = FetchDescriptor<GeneratedContent>(
                predicate: #Predicate { $0.chapterId == chapterId && $0.typeRaw == typeRaw }
            )

            if let cached = try? context.fetch(descriptor).first {
                await loadFromCache(cached, mode: mode)
                loadedModes.insert(mode)
                isLoading = false
                return
            }

            // Generate new content
            let apiKey = try getApiKey(context: context)
            let model = getModel(context: context)

            try await generateContent(for: mode, chapter: chapter, apiKey: apiKey, model: model, context: context)
            loadedModes.insert(mode)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func contentType(for mode: ReaderMode) -> ContentType {
        switch mode {
        case .summary: return .summary
        case .quiz: return .quiz
        case .flashcards: return .flashcards
        case .mindMap: return .mindmap
        case .feed: return .feed
        default: return .summary
        }
    }

    @MainActor
    private func loadFromCache(_ cached: GeneratedContent, mode: ReaderMode) {
        guard let data = cached.jsonData.data(using: .utf8) else { return }

        switch mode {
        case .summary:
            summaryResult = try? JSONDecoder().decode(SummaryResult.self, from: data)
        case .quiz:
            quizResult = try? JSONDecoder().decode(QuizResult.self, from: data)
            quizAnswers = Array(repeating: nil, count: quizResult?.questions.count ?? 0)
        case .flashcards:
            flashcardsResult = try? JSONDecoder().decode(FlashcardsResult.self, from: data)
        case .mindMap:
            mindMapResult = try? JSONDecoder().decode(MindMapResult.self, from: data)
        case .feed:
            feedResult = try? JSONDecoder().decode(FeedResult.self, from: data)
        default:
            break
        }
    }

    private func generateContent(for mode: ReaderMode, chapter: Chapter, apiKey: String, model: String?, context: ModelContext) async throws {
        let gemini = GeminiService.shared

        switch mode {
        case .summary:
            let result = try await gemini.generateSummary(chapterContent: chapter.content, chapterTitle: chapter.title, apiKey: apiKey, model: model)
            await MainActor.run { summaryResult = result }
            saveToCache(result, type: .summary, chapterId: chapter.id, context: context)

        case .quiz:
            let result = try await gemini.generateQuiz(chapterContent: chapter.content, chapterTitle: chapter.title, apiKey: apiKey, model: model)
            await MainActor.run {
                quizResult = result
                quizAnswers = Array(repeating: nil, count: result.questions.count)
            }
            saveToCache(result, type: .quiz, chapterId: chapter.id, context: context)

        case .flashcards:
            let result = try await gemini.generateFlashcards(chapterContent: chapter.content, chapterTitle: chapter.title, apiKey: apiKey, model: model)
            await MainActor.run { flashcardsResult = result }
            saveToCache(result, type: .flashcards, chapterId: chapter.id, context: context)

        case .mindMap:
            let result = try await gemini.generateMindMap(chapterContent: chapter.content, chapterTitle: chapter.title, apiKey: apiKey, model: model)
            await MainActor.run { mindMapResult = result }
            saveToCache(result, type: .mindmap, chapterId: chapter.id, context: context)

        case .feed:
            let result = try await gemini.generateFeed(chapterContent: chapter.content, chapterTitle: chapter.title, apiKey: apiKey, model: model)
            await MainActor.run { feedResult = result }
            saveToCache(result, type: .feed, chapterId: chapter.id, context: context)

        case .socratic:
            let result = try await gemini.generateSocraticQuestion(
                chapterContent: chapter.content,
                chapterTitle: chapter.title,
                history: "",
                apiKey: apiKey,
                model: model
            )
            await MainActor.run { socraticResult = result }

        default:
            break
        }
    }

    private func saveToCache<T: Encodable>(_ result: T, type: ContentType, chapterId: String, context: ModelContext) {
        guard let jsonData = try? JSONEncoder().encode(result),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return }

        let content = GeneratedContent(chapterId: chapterId, type: type, jsonData: jsonString)
        Task { @MainActor in
            context.insert(content)
            try? context.save()
        }
    }

    // Chat
    func sendChatMessage(chapter: Chapter, context: ModelContext) async {
        guard !chatInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let message = chatInput
        await MainActor.run {
            chatMessages.append((role: "user", content: message))
            chatInput = ""
            isChatLoading = true
        }

        do {
            let apiKey = try getApiKey(context: context)
            let model = getModel(context: context)
            let response = try await GeminiService.shared.chat(
                message: message,
                chapterContent: chapter.content,
                chapterTitle: chapter.title,
                history: chatMessages,
                apiKey: apiKey,
                model: model
            )
            await MainActor.run {
                chatMessages.append((role: "assistant", content: response))
            }
        } catch {
            await MainActor.run {
                chatMessages.append((role: "assistant", content: "Error: \(error.localizedDescription)"))
            }
        }

        await MainActor.run { isChatLoading = false }
    }

    // Teach Back
    func submitTeachBack(chapter: Chapter, context: ModelContext) async {
        guard !teachBackInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        isLoading = true
        do {
            let apiKey = try getApiKey(context: context)
            let model = getModel(context: context)
            let result = try await GeminiService.shared.evaluateTeachBack(
                chapterContent: chapter.content,
                chapterTitle: chapter.title,
                userExplanation: teachBackInput,
                apiKey: apiKey,
                model: model
            )
            await MainActor.run { teachBackResult = result }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // Socratic
    func submitSocraticAnswer(chapter: Chapter, context: ModelContext) async {
        guard !socraticInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let answer = socraticInput
        await MainActor.run {
            socraticHistory.append((role: "student", content: answer))
            socraticInput = ""
        }

        isLoading = true
        do {
            let apiKey = try getApiKey(context: context)
            let model = getModel(context: context)
            let historyText = socraticHistory.map { "\($0.role): \($0.content)" }.joined(separator: "\n")
            let result = try await GeminiService.shared.generateSocraticQuestion(
                chapterContent: chapter.content,
                chapterTitle: chapter.title,
                history: historyText,
                apiKey: apiKey,
                model: model
            )
            await MainActor.run {
                socraticResult = result
                socraticHistory.append((role: "tutor", content: result.question))
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // Helpers
    private func getApiKey(context: ModelContext) throws -> String {
        let descriptor = FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.key == "geminiApiKey" }
        )
        guard let setting = try? context.fetch(descriptor).first, !setting.value.isEmpty else {
            throw GeminiServiceError.apiError("No API key configured")
        }
        return setting.value
    }

    private func getModel(context: ModelContext) -> String? {
        let descriptor = FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.key == "geminiModel" }
        )
        return try? context.fetch(descriptor).first?.value
    }

    func resetMode() {
        currentQuizIndex = 0
        quizAnswers = []
        quizSubmitted = false
        currentFlashcardIndex = 0
        isFlipped = false
        teachBackInput = ""
        teachBackResult = nil
        socraticInput = ""
    }
}
