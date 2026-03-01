import SwiftUI

struct SummaryModeView: View {
    let result: SummaryResult?

    var body: some View {
        ScrollView {
            if let result = result {
                VStack(alignment: .leading, spacing: 20) {
                    // Key concepts
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Key Concepts")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)

                        FlowLayout(spacing: 8) {
                            ForEach(result.keyConcepts, id: \.self) { concept in
                                Text(concept)
                                    .font(.system(size: 13))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Theme.accentSoft)
                                    .foregroundColor(Theme.accent)
                                    .cornerRadius(16)
                            }
                        }
                    }

                    // Stats row
                    HStack(spacing: 16) {
                        Label("\(result.readingTime) min", systemImage: "clock")

                        HStack(spacing: 3) {
                            Text("Difficulty:")
                            ForEach(0..<5, id: \.self) { i in
                                Image(systemName: i < result.difficulty ? "star.fill" : "star")
                                    .font(.system(size: 10))
                                    .foregroundColor(i < result.difficulty ? Theme.warning : Theme.textMuted)
                            }
                        }
                    }
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textMuted)

                    // Summary
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)

                        Text(result.summary)
                            .font(.system(size: 15, design: .serif))
                            .foregroundColor(Theme.textSecondary)
                            .lineSpacing(6)
                    }
                }
                .padding(20)
            } else {
                Text("Loading summary...")
                    .foregroundColor(Theme.textMuted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (positions, CGSize(width: maxWidth, height: y + rowHeight))
    }
}
