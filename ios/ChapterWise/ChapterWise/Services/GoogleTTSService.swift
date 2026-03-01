import Foundation

actor GoogleTTSService {
    static let shared = GoogleTTSService()

    struct Voice: Codable, Identifiable {
        let name: String
        let languageCodes: [String]
        let ssmlGender: String
        let naturalSampleRateHertz: Int?

        var id: String { name }

        var displayName: String {
            let lang = languageCodes.first ?? ""
            return "\(name) (\(lang)) [\(ssmlGender)]"
        }

        var isNeural: Bool {
            name.contains("Neural2") || name.contains("Studio") || name.contains("Journey")
        }

        var isWavenet: Bool {
            name.contains("Wavenet")
        }
    }

    struct VoicesResponse: Codable {
        let voices: [Voice]
    }

    struct SynthesisRequest: Codable {
        let input: SynthesisInput
        let voice: VoiceSelection
        let audioConfig: AudioConfig
    }

    struct SynthesisInput: Codable {
        let text: String
    }

    struct VoiceSelection: Codable {
        let languageCode: String
        let name: String
    }

    struct AudioConfig: Codable {
        let audioEncoding: String
        let speakingRate: Double?
    }

    struct SynthesisResponse: Codable {
        let audioContent: String  // base64 encoded audio
    }

    /// Fetch available voices
    func fetchVoices(apiKey: String) async throws -> [Voice] {
        let url = URL(string: "\(Constants.googleTTSBaseURL)/voices?key=\(apiKey)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw TTSError.fetchVoicesFailed
        }
        let voicesResponse = try JSONDecoder().decode(VoicesResponse.self, from: data)
        return voicesResponse.voices
    }

    /// Generate speech
    func generateSpeech(text: String, voiceName: String, languageCode: String, apiKey: String, speakingRate: Double = 1.0) async throws -> Data {
        let url = URL(string: "\(Constants.googleTTSBaseURL)/text:synthesize?key=\(apiKey)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let synthesisRequest = SynthesisRequest(
            input: SynthesisInput(text: text),
            voice: VoiceSelection(languageCode: languageCode, name: voiceName),
            audioConfig: AudioConfig(audioEncoding: "MP3", speakingRate: speakingRate)
        )

        request.httpBody = try JSONEncoder().encode(synthesisRequest)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw TTSError.generationFailed
        }

        let synthesisResponse = try JSONDecoder().decode(SynthesisResponse.self, from: data)
        guard let audioData = Data(base64Encoded: synthesisResponse.audioContent) else {
            throw TTSError.invalidAudioData
        }

        return audioData
    }
}
