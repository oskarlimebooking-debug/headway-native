import Foundation
import UIKit

// MARK: - Gemini API Response Types
struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?
    let error: GeminiError?
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String?
    let inlineData: InlineData?

    struct InlineData: Codable {
        let mimeType: String
        let data: String
    }
}

struct GeminiError: Codable {
    let message: String?
    let code: Int?
}

// MARK: - Generated Content Types
struct SummaryResult: Codable {
    let keyConcepts: [String]
    let summary: String
    let difficulty: Int
    let readingTime: Int
}

struct QuizResult: Codable {
    let questions: [QuizQuestion]
}

struct QuizQuestion: Codable {
    let type: String  // "multiple_choice", "true_false", "open_ended"
    let question: String
    let options: [String]?
    let correctIndex: Int?
    let correct: Bool?
    let explanation: String?
    let sampleAnswer: String?
}

struct FlashcardsResult: Codable {
    let flashcards: [Flashcard]
}

struct Flashcard: Codable {
    let front: String
    let back: String
}

struct TeachBackResult: Codable {
    let strengths: String
    let gaps: String
    let suggestions: String
    let score: Int
}

struct MindMapResult: Codable {
    let center: String
    let branches: [MindMapBranch]
}

struct MindMapBranch: Codable {
    let title: String
    let color: String
    let subbranches: [MindMapSubBranch]
}

struct MindMapSubBranch: Codable {
    let title: String
    let items: [String]
}

struct SocraticResult: Codable {
    let question: String
    let hint: String
    let keyInsight: String
}

struct FeedResult: Codable {
    let posts: [FeedPost]
}

struct FeedPost: Codable, Identifiable {
    let id: Int
    let username: String
    let handle: String
    let avatar: String
    let personality: String
    let content: String
    let likes: Int
    let retweets: Int
    let views: Int
    let isViral: Bool
    let hasImage: Bool
    let imagePrompt: String?
    let hasLink: Bool
    let linkTopic: String?
}

struct ChapterMarker: Codable {
    let title: String
    let startMarker: String
}

struct ChunkBoundary: Codable {
    let position: Int
    let title: String
    let firstWords: String
}

// MARK: - GeminiService
actor GeminiService {
    static let shared = GeminiService()

    struct Options {
        var temperature: Double = 0.7
        var maxOutputTokens: Int = 65536
        var jsonMode: Bool = false
    }

    // MARK: - Core API Call
    func callAPI(prompt: String, apiKey: String, model: String? = nil, options: Options = Options()) async throws -> String {
        let selectedModel = model ?? Constants.defaultModel
        let url = URL(string: "\(Constants.geminiBaseURL)/\(selectedModel):generateContent?key=\(apiKey)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var generationConfig: [String: Any] = [
            "temperature": options.temperature,
            "maxOutputTokens": options.maxOutputTokens
        ]
        if options.jsonMode {
            generationConfig["responseMimeType"] = "application/json"
        }

        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": generationConfig
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiServiceError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(GeminiResponse.self, from: data) {
                throw GeminiServiceError.apiError(errorResponse.error?.message ?? "Request failed with status \(httpResponse.statusCode)")
            }
            throw GeminiServiceError.apiError("Request failed with status \(httpResponse.statusCode)")
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = geminiResponse.candidates?.first?.content.parts.first?.text else {
            throw GeminiServiceError.noContent
        }

        return text
    }

    // MARK: - Vision API Call (for OCR)
    func callVisionAPI(prompt: String, imageData: Data, apiKey: String, model: String? = nil) async throws -> String {
        let selectedModel = model ?? "gemini-2.0-flash"
        let url = URL(string: "\(Constants.geminiBaseURL)/\(selectedModel):generateContent?key=\(apiKey)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let base64Image = imageData.base64EncodedString()

        let body: [String: Any] = [
            "contents": [
                ["parts": [
                    ["text": prompt],
                    ["inlineData": [
                        "mimeType": "image/png",
                        "data": base64Image
                    ]]
                ]]
            ],
            "generationConfig": [
                "temperature": 0.3,
                "maxOutputTokens": 8192
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GeminiServiceError.apiError("Vision API request failed")
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = geminiResponse.candidates?.first?.content.parts.first?.text else {
            throw GeminiServiceError.noContent
        }

        return text
    }

    // MARK: - Chapter Splitting
    func splitIntoChapters(text: String, bookTitle: String, apiKey: String, model: String? = nil) async throws -> [(title: String, content: String)] {
        // Step 1: Try pattern-based detection first
        let patternChapters = detectChapterPatterns(in: text)
        if patternChapters.count >= 2 {
            // Enhance titles with AI
            if let enhanced = try? await enhanceChapterTitles(patternChapters, bookTitle: bookTitle, apiKey: apiKey, model: model) {
                return enhanced
            }
            return patternChapters
        }

        // Step 2: Try AI-based detection
        let totalLength = text.count
        let chunkSize = 25000

        if totalLength <= Int(Double(chunkSize) * 1.5) {
            return try await singlePassChapterDetection(text: text, bookTitle: bookTitle, apiKey: apiKey, model: model)
        }

        // Sequential chunk-based detection for long texts
        return try await sequentialChapterDetection(text: text, bookTitle: bookTitle, apiKey: apiKey, model: model)
    }

    private func detectChapterPatterns(in text: String) -> [(title: String, content: String)] {
        let patterns: [(regex: String, hasPrefix: Bool)] = [
            ("(?:^|\\n)[ \\t]*(Chapter|CHAPTER|chapter)[ \\t]+([0-9]+|[IVXLCDM]+|One|Two|Three|Four|Five|Six|Seven|Eight|Nine|Ten|Eleven|Twelve)[:\\.]?[ \\t]*([^\\n]*?)[ \\t]*\\n", true),
            ("(?:^|\\n)[ \\t]*(Part|PART|part)[ \\t]+([0-9]+|[IVXLCDM]+|One|Two|Three|Four|Five|Six|Seven|Eight|Nine|Ten)[:\\.]?[ \\t]*([^\\n]*?)[ \\t]*\\n", true),
            ("(?:^|\\n)[ \\t]*(Section|SECTION)[ \\t]+([0-9]+|[IVXLCDM]+)[:\\.]?[ \\t]*([^\\n]*?)[ \\t]*\\n", true),
        ]

        for (pattern, hasPrefix) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            let nsText = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

            if matches.count >= 2 {
                var chapters: [(title: String, content: String)] = []

                for (i, match) in matches.enumerated() {
                    let startPos = match.range.location
                    let endPos = i < matches.count - 1 ? matches[i + 1].range.location : nsText.length

                    var title: String
                    if hasPrefix && match.numberOfRanges >= 4 {
                        let prefix = nsText.substring(with: match.range(at: 1))
                        let number = nsText.substring(with: match.range(at: 2))
                        let subtitle = match.range(at: 3).location != NSNotFound ? nsText.substring(with: match.range(at: 3)).trimmingCharacters(in: .whitespaces) : ""
                        title = subtitle.isEmpty ? "\(prefix) \(number)" : "\(prefix) \(number): \(subtitle)"
                    } else {
                        title = "Chapter \(i + 1)"
                    }

                    let content = nsText.substring(with: NSRange(location: startPos, length: endPos - startPos)).trimmingCharacters(in: .whitespacesAndNewlines)

                    if content.count > 100 {
                        chapters.append((title: title, content: content))
                    }
                }

                if chapters.count >= 2 {
                    return chapters
                }
            }
        }

        return []
    }

    private func singlePassChapterDetection(text: String, bookTitle: String, apiKey: String, model: String?) async throws -> [(title: String, content: String)] {
        let prompt = Prompts.chapterSplit
            .replacingOccurrences(of: "{{bookTitle}}", with: bookTitle)
            .replacingOccurrences(of: "{{content}}", with: text)

        let response = try await callAPI(prompt: prompt, apiKey: apiKey, model: model, options: Options(jsonMode: true))
        let jsonString = response.extractedJSON

        guard let data = jsonString.data(using: .utf8),
              let markers = try? JSONDecoder().decode([ChapterMarker].self, from: data),
              !markers.isEmpty else {
            return splitByWordCount(text: text, bookTitle: bookTitle)
        }

        let chapters = extractChaptersFromMarkers(text: text, markers: markers)
        return chapters.isEmpty ? splitByWordCount(text: text, bookTitle: bookTitle) : chapters
    }

    private func sequentialChapterDetection(text: String, bookTitle: String, apiKey: String, model: String?) async throws -> [(title: String, content: String)] {
        let chunkSize = 25000
        let overlapSize = 3000
        var allBoundaries: [(position: Int, title: String, firstWords: String)] = []
        var chunkStart = 0
        var chunkIndex = 0

        while chunkStart < text.count {
            let startIndex = text.index(text.startIndex, offsetBy: chunkStart)
            let endIndex = text.index(text.startIndex, offsetBy: min(chunkStart + chunkSize, text.count))
            let chunk = String(text[startIndex..<endIndex])

            let prompt = Prompts.chunkBoundary
                .replacingOccurrences(of: "{{bookTitle}}", with: bookTitle)
                .replacingOccurrences(of: "{{chunkIndex}}", with: "\(chunkIndex + 1)")
                .replacingOccurrences(of: "{{content}}", with: chunk)

            if let response = try? await callAPI(prompt: prompt, apiKey: apiKey, model: model, options: Options(jsonMode: true)),
               let data = response.extractedJSON.data(using: .utf8),
               let boundaries = try? JSONDecoder().decode([ChunkBoundary].self, from: data) {
                for b in boundaries {
                    allBoundaries.append((
                        position: chunkStart + b.position,
                        title: b.title,
                        firstWords: b.firstWords
                    ))
                }
            }

            chunkStart = min(chunkStart + chunkSize, text.count) - overlapSize
            if chunkStart + overlapSize >= text.count { break }
            chunkIndex += 1

            try await Task.sleep(nanoseconds: 500_000_000)
        }

        // Merge and deduplicate
        allBoundaries.sort { $0.position < $1.position }
        var merged: [(position: Int, title: String, firstWords: String)] = []
        let tolerance = 500

        for boundary in allBoundaries {
            let isDuplicate = merged.contains { abs($0.position - boundary.position) < tolerance }
            if !isDuplicate {
                merged.append(boundary)
            }
        }

        if merged.isEmpty {
            return splitByWordCount(text: text, bookTitle: bookTitle)
        }

        // Build chapters
        var chapters: [(title: String, content: String)] = []
        for (i, boundary) in merged.enumerated() {
            let startPos = boundary.position
            let endPos = i < merged.count - 1 ? merged[i + 1].position : text.count

            guard startPos < text.count && endPos <= text.count else { continue }
            let startIndex = text.index(text.startIndex, offsetBy: startPos)
            let endIndex = text.index(text.startIndex, offsetBy: endPos)
            let content = String(text[startIndex..<endIndex]).trimmingCharacters(in: .whitespacesAndNewlines)

            if content.count > 100 {
                chapters.append((title: boundary.title, content: content))
            }
        }

        return chapters.isEmpty ? splitByWordCount(text: text, bookTitle: bookTitle) : chapters
    }

    private func extractChaptersFromMarkers(text: String, markers: [ChapterMarker]) -> [(title: String, content: String)] {
        var chapters: [(title: String, content: String)] = []

        for (i, marker) in markers.enumerated() {
            guard let range = text.range(of: marker.startMarker) else { continue }
            let startPos = range.lowerBound

            var endPos = text.endIndex
            if i < markers.count - 1 {
                for nextMarker in markers[(i+1)...] {
                    if let nextRange = text.range(of: nextMarker.startMarker, range: startPos..<text.endIndex) {
                        if nextRange.lowerBound > startPos {
                            endPos = nextRange.lowerBound
                            break
                        }
                    }
                }
            }

            let content = String(text[startPos..<endPos]).trimmingCharacters(in: .whitespacesAndNewlines)
            if content.count > 100 {
                chapters.append((title: marker.title, content: content))
            }
        }

        return chapters
    }

    private func splitByWordCount(text: String, bookTitle: String, wordsPerChapter: Int = 3000) -> [(title: String, content: String)] {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        var chapters: [(title: String, content: String)] = []
        var index = 0
        var chapterNum = 1

        while index < words.count {
            let endIndex = min(index + wordsPerChapter, words.count)
            let chapterWords = Array(words[index..<endIndex])
            let content = chapterWords.joined(separator: " ")

            chapters.append((title: "Chapter \(chapterNum)", content: content))

            index = endIndex
            chapterNum += 1
        }

        return chapters
    }

    private func enhanceChapterTitles(_ chapters: [(title: String, content: String)], bookTitle: String, apiKey: String, model: String?) async throws -> [(title: String, content: String)] {
        let chapterList = chapters.enumerated().map { (i, ch) in
            let preview = String(ch.content.prefix(200))
            return "\(i + 1). \(ch.title) (\(preview)...)"
        }.joined(separator: "\n")

        let prompt = Prompts.enhanceTitles
            .replacingOccurrences(of: "{{bookTitle}}", with: bookTitle)
            .replacingOccurrences(of: "{{chapterCount}}", with: "\(chapters.count)")
            .replacingOccurrences(of: "{{chapterList}}", with: chapterList)

        let response = try await callAPI(prompt: prompt, apiKey: apiKey, model: model)
        let jsonString = response.extractedJSON

        guard let data = jsonString.data(using: .utf8),
              let titles = try? JSONDecoder().decode([String].self, from: data) else {
            return chapters
        }

        var enhanced = chapters
        for i in 0..<min(enhanced.count, titles.count) {
            if titles[i].count > 3 {
                enhanced[i] = (title: titles[i], content: chapters[i].content)
            }
        }

        return enhanced
    }

    // MARK: - Content Generation
    func generateSummary(chapterContent: String, chapterTitle: String, apiKey: String, model: String? = nil) async throws -> SummaryResult {
        let prompt = Prompts.summary
            .replacingOccurrences(of: "{{chapterTitle}}", with: chapterTitle)
            .replacingOccurrences(of: "{{content}}", with: chapterContent)

        let response = try await callAPI(prompt: prompt, apiKey: apiKey, model: model, options: Options(jsonMode: true))
        let data = response.extractedJSON.data(using: .utf8)!
        return try JSONDecoder().decode(SummaryResult.self, from: data)
    }

    func generateQuiz(chapterContent: String, chapterTitle: String, apiKey: String, model: String? = nil) async throws -> QuizResult {
        let prompt = Prompts.quiz
            .replacingOccurrences(of: "{{chapterTitle}}", with: chapterTitle)
            .replacingOccurrences(of: "{{content}}", with: chapterContent)

        let response = try await callAPI(prompt: prompt, apiKey: apiKey, model: model, options: Options(jsonMode: true))
        let data = response.extractedJSON.data(using: .utf8)!
        return try JSONDecoder().decode(QuizResult.self, from: data)
    }

    func generateFlashcards(chapterContent: String, chapterTitle: String, apiKey: String, model: String? = nil) async throws -> FlashcardsResult {
        let prompt = Prompts.flashcards
            .replacingOccurrences(of: "{{chapterTitle}}", with: chapterTitle)
            .replacingOccurrences(of: "{{content}}", with: chapterContent)

        let response = try await callAPI(prompt: prompt, apiKey: apiKey, model: model, options: Options(jsonMode: true))
        let data = response.extractedJSON.data(using: .utf8)!
        return try JSONDecoder().decode(FlashcardsResult.self, from: data)
    }

    func evaluateTeachBack(chapterContent: String, chapterTitle: String, userExplanation: String, apiKey: String, model: String? = nil) async throws -> TeachBackResult {
        let prompt = Prompts.teachback
            .replacingOccurrences(of: "{{chapterTitle}}", with: chapterTitle)
            .replacingOccurrences(of: "{{content}}", with: chapterContent)
            .replacingOccurrences(of: "{{userExplanation}}", with: userExplanation)

        let response = try await callAPI(prompt: prompt, apiKey: apiKey, model: model, options: Options(jsonMode: true))
        let data = response.extractedJSON.data(using: .utf8)!
        return try JSONDecoder().decode(TeachBackResult.self, from: data)
    }

    func generateMindMap(chapterContent: String, chapterTitle: String, apiKey: String, model: String? = nil) async throws -> MindMapResult {
        let prompt = Prompts.mindmap
            .replacingOccurrences(of: "{{chapterTitle}}", with: chapterTitle)
            .replacingOccurrences(of: "{{content}}", with: chapterContent)

        let response = try await callAPI(prompt: prompt, apiKey: apiKey, model: model, options: Options(jsonMode: true))
        let data = response.extractedJSON.data(using: .utf8)!
        return try JSONDecoder().decode(MindMapResult.self, from: data)
    }

    func generateSocraticQuestion(chapterContent: String, chapterTitle: String, history: String, apiKey: String, model: String? = nil) async throws -> SocraticResult {
        let prompt = Prompts.socratic
            .replacingOccurrences(of: "{{chapterTitle}}", with: chapterTitle)
            .replacingOccurrences(of: "{{content}}", with: chapterContent)
            .replacingOccurrences(of: "{{history}}", with: history)

        let response = try await callAPI(prompt: prompt, apiKey: apiKey, model: model, options: Options(jsonMode: true))
        let data = response.extractedJSON.data(using: .utf8)!
        return try JSONDecoder().decode(SocraticResult.self, from: data)
    }

    func generateFeed(chapterContent: String, chapterTitle: String, apiKey: String, model: String? = nil) async throws -> FeedResult {
        let prompt = Prompts.feed
            .replacingOccurrences(of: "{{chapterTitle}}", with: chapterTitle)
            .replacingOccurrences(of: "{{content}}", with: chapterContent)

        let response = try await callAPI(prompt: prompt, apiKey: apiKey, model: model, options: Options(jsonMode: true))
        let data = response.extractedJSON.data(using: .utf8)!
        return try JSONDecoder().decode(FeedResult.self, from: data)
    }

    func chat(message: String, chapterContent: String, chapterTitle: String, history: [(role: String, content: String)], apiKey: String, model: String? = nil) async throws -> String {
        var contextHistory = "Chapter: \"\(chapterTitle)\"\n\nContent:\n\(chapterContent)\n\nConversation:\n"
        for msg in history {
            contextHistory += "\(msg.role): \(msg.content)\n"
        }
        contextHistory += "User: \(message)\n\nRespond helpfully and concisely about this chapter's content."

        return try await callAPI(prompt: contextHistory, apiKey: apiKey, model: model)
    }

    func cleanTextForTTS(content: String, apiKey: String, model: String? = nil) async throws -> String {
        let prompt = Prompts.ttsClean
            .replacingOccurrences(of: "{{content}}", with: content)
        return try await callAPI(prompt: prompt, apiKey: apiKey, model: model)
    }

    func formatText(content: String, chapterTitle: String, apiKey: String, model: String? = nil) async throws -> String {
        let prompt = Prompts.formatText
            .replacingOccurrences(of: "{{chapterTitle}}", with: chapterTitle)
            .replacingOccurrences(of: "{{content}}", with: content)
        return try await callAPI(prompt: prompt, apiKey: apiKey, model: model)
    }

    func performOCR(imageData: Data, apiKey: String, model: String? = nil) async throws -> String {
        let prompt = "Extract ALL text from this image. Return the text exactly as it appears, preserving paragraph structure. Return ONLY the extracted text, no commentary."
        return try await callVisionAPI(prompt: prompt, imageData: imageData, apiKey: apiKey, model: model)
    }
}

// MARK: - Errors
enum GeminiServiceError: LocalizedError {
    case invalidResponse
    case apiError(String)
    case noContent
    case invalidJSON

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from server"
        case .apiError(let message): return message
        case .noContent: return "No content in response"
        case .invalidJSON: return "Failed to parse JSON response"
        }
    }
}

