import SwiftUI
import SwiftData

struct ListenModeView: View {
    @Environment(\.modelContext) private var modelContext
    let chapter: Chapter
    let showToast: (String, ToastType) -> Void
    @State private var audioVM = AudioViewModel()
    @State private var ttsService = TTSService.shared
    @State private var selectedSpeedIndex = 2 // 1x

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Provider selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("TTS Provider")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textSecondary)

                    Picker("Provider", selection: $audioVM.ttsProvider) {
                        Text("Native").tag("native")
                        Text("Lazybird").tag("lazybird")
                        Text("Google Cloud").tag("google")
                    }
                    .pickerStyle(.segmented)
                }

                // Play controls
                VStack(spacing: 20) {
                    // Progress (for native TTS)
                    if audioVM.ttsProvider == "native" {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Theme.bgElevated)
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Theme.accent)
                                    .frame(width: geo.size.width * ttsService.progress, height: 6)
                            }
                        }
                        .frame(height: 6)
                    }

                    // Main controls
                    HStack(spacing: 32) {
                        // Speed
                        Button(action: {
                            selectedSpeedIndex = (selectedSpeedIndex + 1) % TTSService.speedPresets.count
                            ttsService.setRate(TTSService.speedPresets[selectedSpeedIndex].rate)
                        }) {
                            Text(TTSService.speedPresets[selectedSpeedIndex].label)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Theme.bgCard)
                                .cornerRadius(16)
                        }

                        // Play/Pause
                        Button(action: {
                            if audioVM.ttsProvider == "native" {
                                ttsService.togglePlayPause(text: chapter.content)
                            } else if chapter.audioData != nil {
                                audioVM.playExistingAudio(for: chapter)
                            } else {
                                Task {
                                    await audioVM.generateAudio(for: chapter, context: modelContext)
                                }
                            }
                        }) {
                            Image(systemName: ttsService.isPlaying || AudioPlayerService.shared.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(Theme.accent)
                        }

                        // Stop
                        Button(action: {
                            ttsService.stop()
                            AudioPlayerService.shared.stop()
                        }) {
                            Image(systemName: "stop.circle")
                                .font(.system(size: 28))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }

                    // Generate button for API TTS
                    if audioVM.ttsProvider != "native" && chapter.audioData == nil {
                        Button(action: {
                            Task {
                                await audioVM.generateAudio(for: chapter, context: modelContext)
                                if chapter.audioData != nil {
                                    showToast("Audio generated!", .success)
                                }
                            }
                        }) {
                            HStack {
                                if audioVM.isGenerating {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "waveform")
                                }
                                Text(audioVM.isGenerating ? (audioVM.generationProgress ?? "Generating...") : "Generate Audio")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Theme.accentGradient)
                            .cornerRadius(Theme.radiusMd)
                        }
                        .disabled(audioVM.isGenerating)
                    }

                    if chapter.audioData != nil {
                        Label("Audio cached", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.success)
                    }
                }
                .padding(20)
                .background(Theme.bgCard)
                .cornerRadius(Theme.radiusMd)

                // Text preview
                Text(chapter.content)
                    .font(.system(size: 15, design: .serif))
                    .foregroundColor(Theme.textSecondary)
                    .lineSpacing(6)
                    .lineLimit(20)
            }
            .padding(16)
        }
    }
}
