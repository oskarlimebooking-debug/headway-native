import SwiftUI

struct ReadModeView: View {
    let content: String
    @State private var fontSize: CGFloat = 17

    var body: some View {
        VStack(spacing: 0) {
            // Font size controls
            HStack {
                Button(action: { fontSize = max(12, fontSize - 1) }) {
                    Text("A-")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                        .padding(8)
                        .background(Theme.bgCard)
                        .cornerRadius(6)
                }

                Text("\(Int(fontSize))pt")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textMuted)

                Button(action: { fontSize = min(28, fontSize + 1) }) {
                    Text("A+")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                        .padding(8)
                        .background(Theme.bgCard)
                        .cornerRadius(6)
                }

                Spacer()

                let wordCount = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
                Text("\(wordCount) words • \(max(1, wordCount / 200)) min read")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            ScrollView {
                Text(content)
                    .font(.system(size: fontSize, design: .serif))
                    .foregroundColor(Theme.textPrimary)
                    .lineSpacing(8)
                    .padding(20)
                    .textSelection(.enabled)
            }
        }
    }
}
