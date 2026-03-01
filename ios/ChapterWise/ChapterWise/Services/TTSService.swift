import Foundation
import AVFoundation

@Observable
class TTSService: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = TTSService()

    private let synthesizer = AVSpeechSynthesizer()

    var isPlaying = false
    var isPaused = false
    var currentRate: Float = 0.5  // AVSpeechUtterance rate (0.0 to 1.0, default 0.5)
    var availableVoices: [AVSpeechSynthesisVoice] = []
    var selectedVoiceIdentifier: String?
    var progress: Double = 0

    private var totalTextLength: Int = 0
    private var spokenLength: Int = 0

    override init() {
        super.init()
        synthesizer.delegate = self
        loadVoices()
    }

    func loadVoices() {
        availableVoices = AVSpeechSynthesisVoice.speechVoices()
            .sorted { $0.language < $1.language }
    }

    func speak(text: String) {
        stop()

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = currentRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        if let voiceId = selectedVoiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }

        totalTextLength = text.count
        spokenLength = 0

        // Configure audio session
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenContent)
        try? AVAudioSession.sharedInstance().setActive(true)

        synthesizer.speak(utterance)
        isPlaying = true
        isPaused = false
    }

    func pause() {
        synthesizer.pauseSpeaking(at: .word)
        isPlaying = false
        isPaused = true
    }

    func resume() {
        synthesizer.continueSpeaking()
        isPlaying = true
        isPaused = false
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        isPaused = false
        progress = 0
    }

    func togglePlayPause(text: String) {
        if isPlaying {
            pause()
        } else if isPaused {
            resume()
        } else {
            speak(text: text)
        }
    }

    func setRate(_ rate: Float) {
        currentRate = rate
    }

    // Speed presets matching PWA (0.5x, 0.75x, 1x, 1.25x, 1.5x, 2x)
    static let speedPresets: [(label: String, rate: Float)] = [
        ("0.5x", 0.3),
        ("0.75x", 0.4),
        ("1x", 0.5),
        ("1.25x", 0.55),
        ("1.5x", 0.6),
        ("2x", 0.7)
    ]

    // MARK: - AVSpeechSynthesizerDelegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isPlaying = true
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isPlaying = false
        isPaused = false
        progress = 1.0
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isPlaying = false
        isPaused = false
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        spokenLength = characterRange.location + characterRange.length
        if totalTextLength > 0 {
            progress = Double(spokenLength) / Double(totalTextLength)
        }
    }
}
