import Foundation
import AVFoundation
import MediaPlayer

@Observable
class AudioPlayerService: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioPlayerService()

    private var audioPlayer: AVAudioPlayer?

    var isPlaying = false
    var progress: Double = 0
    var duration: TimeInterval = 0
    var currentTime: TimeInterval = 0
    var playbackRate: Float = 1.0

    // Persistent player state
    var currentChapterTitle: String?
    var currentBookTitle: String?
    var currentChapterId: String?
    var currentBookId: String?
    var isVisible = false

    private var progressTimer: Timer?

    override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommands()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seek(to: event.positionTime)
            return .success
        }
    }

    func loadAndPlay(data: Data, chapterTitle: String, bookTitle: String, chapterId: String, bookId: String) {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.enableRate = true
            audioPlayer?.rate = playbackRate
            audioPlayer?.prepareToPlay()

            duration = audioPlayer?.duration ?? 0
            currentChapterTitle = chapterTitle
            currentBookTitle = bookTitle
            currentChapterId = chapterId
            currentBookId = bookId
            isVisible = true

            play()
        } catch {
            print("Failed to load audio: \(error)")
        }
    }

    func play() {
        audioPlayer?.play()
        isPlaying = true
        startProgressTimer()
        updateNowPlayingInfo()
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopProgressTimer()
        updateNowPlayingInfo()
    }

    func stop() {
        audioPlayer?.stop()
        isPlaying = false
        progress = 0
        currentTime = 0
        stopProgressTimer()
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
        if duration > 0 {
            progress = time / duration
        }
        updateNowPlayingInfo()
    }

    func setRate(_ rate: Float) {
        playbackRate = rate
        audioPlayer?.rate = rate
        updateNowPlayingInfo()
    }

    static let speedPresets: [(label: String, rate: Float)] = [
        ("0.5x", 0.5),
        ("0.75x", 0.75),
        ("1x", 1.0),
        ("1.25x", 1.25),
        ("1.5x", 1.5),
        ("2x", 2.0)
    ]

    func cycleSpeed() -> Float {
        let rates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
        if let currentIndex = rates.firstIndex(of: playbackRate) {
            let nextIndex = (currentIndex + 1) % rates.count
            setRate(rates[nextIndex])
        } else {
            setRate(1.0)
        }
        return playbackRate
    }

    func dismiss() {
        stop()
        isVisible = false
        currentChapterTitle = nil
        currentBookTitle = nil
        currentChapterId = nil
        currentBookId = nil
    }

    // MARK: - Progress Timer
    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.currentTime = player.currentTime
            if self.duration > 0 {
                self.progress = player.currentTime / self.duration
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    // MARK: - Now Playing Info
    private func updateNowPlayingInfo() {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: currentChapterTitle ?? "Unknown",
            MPMediaItemPropertyArtist: currentBookTitle ?? "ChapterWise",
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? playbackRate : 0.0
        ]

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        progress = 1.0
        stopProgressTimer()
    }
}
