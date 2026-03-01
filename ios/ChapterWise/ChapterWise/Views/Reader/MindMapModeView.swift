import SwiftUI

struct MindMapModeView: View {
    let result: MindMapResult?

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            if let result = result {
                VStack(spacing: 32) {
                    // Center node
                    Text(result.center)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Theme.accent)
                        .cornerRadius(Theme.radiusLg)

                    // Branches
                    ForEach(Array(result.branches.enumerated()), id: \.offset) { index, branch in
                        VStack(spacing: 16) {
                            // Branch title
                            Text(branch.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color(hex: branch.color))
                                .cornerRadius(Theme.radiusMd)

                            // Sub-branches
                            HStack(alignment: .top, spacing: 16) {
                                ForEach(Array(branch.subbranches.enumerated()), id: \.offset) { _, sub in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(sub.title)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(hex: branch.color))

                                        ForEach(sub.items, id: \.self) { item in
                                            HStack(alignment: .top, spacing: 6) {
                                                Circle()
                                                    .fill(Color(hex: branch.color).opacity(0.5))
                                                    .frame(width: 6, height: 6)
                                                    .padding(.top, 5)
                                                Text(item)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(Theme.textSecondary)
                                            }
                                        }
                                    }
                                    .padding(12)
                                    .background(Theme.bgCard)
                                    .cornerRadius(Theme.radiusSm)
                                    .frame(minWidth: 140)
                                }
                            }
                        }
                        .padding(16)
                        .background(Theme.bgElevated.opacity(0.5))
                        .cornerRadius(Theme.radiusMd)
                    }
                }
                .padding(24)
                .frame(minWidth: 600)
            } else {
                Text("Loading mind map...")
                    .foregroundColor(Theme.textMuted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
