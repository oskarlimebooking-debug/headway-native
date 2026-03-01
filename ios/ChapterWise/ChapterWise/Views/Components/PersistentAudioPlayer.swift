import SwiftUI

struct PersistentAudioPlayer: View {
    @State private var player = AudioPlayerService.shared

    var body: some View {
        if player.isVisible {
            VStack(spacing: 0) {
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Theme.bgElevated)
                        Rectangle()
                            .fill(Theme.accent)
                            .frame(width: geo.size.width * player.progress)
                    }
                }
                .frame(height: 3)

                HStack(spacing: 12) {
                    // Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(player.currentChapterTitle ?? "Unknown")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(1)
                        Text(player.currentBookTitle ?? "")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textMuted)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Controls
                    HStack(spacing: 16) {
                        Button(action: { player.togglePlayPause() }) {
                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Theme.textPrimary)
                        }

                        Button(action: {
                            let rate = player.cycleSpeed()
                            _ = rate
                        }) {
                            Text(String(format: "%.1fx", player.playbackRate))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.bgElevated)
                                .cornerRadius(8)
                        }

                        Button(action: { player.dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.textMuted)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(Theme.bgCard)
            .overlay(
                Rectangle()
                    .fill(Theme.border)
                    .frame(height: 1),
                alignment: .top
            )
        }
    }
}
