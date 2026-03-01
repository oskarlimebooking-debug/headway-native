import Foundation

actor LazyBirdTTSService {
    static let shared = LazyBirdTTSService()

    struct Voice: Codable, Identifiable {
        let id: String
        let name: String
        let language: String?
        let gender: String?
        let preview_url: String?

        var displayName: String {
            var parts = [name]
            if let lang = language { parts.append("(\(lang))") }
            if let gen = gender { parts.append("[\(gen)]") }
            return parts.joined(separator: " ")
        }
    }

    struct StatusResponse: Codable {
        let status: String?
        let credits: Int?
    }

    /// Check API status
    func checkStatus(apiKey: String) async throws -> StatusResponse {
        var request = URLRequest(url: URL(string: "\(Constants.lazybirdBaseURL)/status")!)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw TTSError.apiUnavailable
        }
        return try JSONDecoder().decode(StatusResponse.self, from: data)
    }

    /// Fetch available voices
    func fetchVoices(apiKey: String) async throws -> [Voice] {
        var request = URLRequest(url: URL(string: "\(Constants.lazybirdBaseURL)/voices")!)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw TTSError.fetchVoicesFailed
        }
        return try JSONDecoder().decode([Voice].self, from: data)
    }

    /// Generate speech audio
    func generateSpeech(text: String, voiceId: String, apiKey: String) async throws -> Data {
        var request = URLRequest(url: URL(string: "\(Constants.lazybirdBaseURL)/generate-speech")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")

        let body = ["voiceId": voiceId, "text": text]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw TTSError.generationFailed
        }
        return data
    }
}

enum TTSError: LocalizedError {
    case apiUnavailable
    case fetchVoicesFailed
    case generationFailed
    case invalidAudioData
    case noVoiceSelected

    var errorDescription: String? {
        switch self {
        case .apiUnavailable: return "TTS API is not available"
        case .fetchVoicesFailed: return "Failed to fetch voices"
        case .generationFailed: return "Speech generation failed"
        case .invalidAudioData: return "Invalid audio data received"
        case .noVoiceSelected: return "No voice selected"
        }
    }
}
