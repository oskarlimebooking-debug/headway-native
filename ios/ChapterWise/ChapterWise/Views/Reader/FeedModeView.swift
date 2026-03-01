import SwiftUI

struct FeedModeView: View {
    let result: FeedResult?

    var body: some View {
        ScrollView {
            if let result = result {
                LazyVStack(spacing: 16) {
                    ForEach(result.posts) { post in
                        FeedPostCard(post: post)
                    }
                }
                .padding(16)
            } else {
                Text("Loading feed...")
                    .foregroundColor(Theme.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            }
        }
    }
}

private struct FeedPostCard: View {
    let post: FeedPost

    var personalityColor: Color {
        switch post.personality {
        case "professor": return Color(hex: "3B82F6")
        case "hype": return Color(hex: "EF4444")
        case "contrarian": return Color(hex: "F59E0B")
        case "unhinged": return Color(hex: "8B5CF6")
        case "nurturing": return Color(hex: "10B981")
        case "storyteller": return Color(hex: "EC4899")
        case "meme": return Color(hex: "F97316")
        default: return Theme.accent
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Text(post.avatar)
                    .font(.system(size: 24))
                    .frame(width: 40, height: 40)
                    .background(personalityColor.opacity(0.2))
                    .cornerRadius(20)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(post.username)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        if post.isViral {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                        }
                    }
                    Text(post.handle)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textMuted)
                }

                Spacer()

                Text(post.personality)
                    .font(.system(size: 10, weight: .semibold))
                    .textCase(.uppercase)
                    .foregroundColor(personalityColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(personalityColor.opacity(0.15))
                    .cornerRadius(8)
            }

            // Content
            Text(post.content)
                .font(.system(size: 14))
                .foregroundColor(Theme.textPrimary)
                .lineSpacing(4)

            // Stats
            HStack(spacing: 24) {
                Label(formatNumber(post.likes), systemImage: "heart")
                Label(formatNumber(post.retweets), systemImage: "arrow.2.squarepath")
                Label(formatNumber(post.views), systemImage: "eye")
            }
            .font(.system(size: 12))
            .foregroundColor(Theme.textMuted)
        }
        .padding(16)
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusMd)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusMd)
                .stroke(post.isViral ? personalityColor.opacity(0.3) : Theme.border, lineWidth: 1)
        )
    }

    private func formatNumber(_ n: Int) -> String {
        if n >= 1000 {
            return String(format: "%.1fK", Double(n) / 1000.0)
        }
        return "\(n)"
    }
}
