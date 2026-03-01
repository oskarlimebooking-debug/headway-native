import SwiftUI
import SwiftData

struct TeachBackModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: ReaderViewModel
    let chapter: Chapter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Teach Back (Feynman Technique)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)

                    Text("Explain what you learned from this chapter in your own words. Pretend you're teaching it to someone who knows nothing about the topic.")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                }

                // Text input
                TextEditor(text: $viewModel.teachBackInput)
                    .font(.system(size: 15))
                    .foregroundColor(Theme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 200)
                    .padding(12)
                    .background(Theme.bgCard)
                    .cornerRadius(Theme.radiusMd)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusMd)
                            .stroke(Theme.border, lineWidth: 1)
                    )

                // Submit
                Button(action: {
                    Task {
                        await viewModel.submitTeachBack(chapter: chapter, context: modelContext)
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView().tint(.white)
                        }
                        Text("Get Feedback")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accentGradient)
                    .cornerRadius(Theme.radiusMd)
                }
                .disabled(viewModel.teachBackInput.isEmpty || viewModel.isLoading)

                // Results
                if let result = viewModel.teachBackResult {
                    VStack(alignment: .leading, spacing: 16) {
                        // Score
                        HStack {
                            Text("Score:")
                                .font(.system(size: 16, weight: .semibold))
                            Text("\(result.score)/10")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(result.score >= 7 ? Theme.success : result.score >= 4 ? Theme.warning : Theme.error)
                        }

                        FeedbackSection(title: "Strengths", content: result.strengths, color: Theme.success)
                        FeedbackSection(title: "Gaps", content: result.gaps, color: Theme.warning)
                        FeedbackSection(title: "Suggestions", content: result.suggestions, color: Theme.accent)
                    }
                    .padding(16)
                    .background(Theme.bgCard)
                    .cornerRadius(Theme.radiusMd)
                }
            }
            .padding(16)
        }
    }
}

private struct FeedbackSection: View {
    let title: String
    let content: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
        }
    }
}
