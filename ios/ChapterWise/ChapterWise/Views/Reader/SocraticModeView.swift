import SwiftUI
import SwiftData

struct SocraticModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: ReaderViewModel
    let chapter: Chapter

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Socratic Method")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)

                    Text("Answer questions to deepen your understanding through guided inquiry.")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)

                    // Question
                    if let result = viewModel.socraticResult {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(result.question)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.textPrimary)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Theme.accentSoft)
                                .cornerRadius(Theme.radiusMd)
                        }
                    }

                    // History
                    ForEach(Array(viewModel.socraticHistory.enumerated()), id: \.offset) { _, entry in
                        HStack {
                            if entry.role == "student" { Spacer() }

                            Text(entry.content)
                                .font(.system(size: 14))
                                .foregroundColor(entry.role == "student" ? .white : Theme.textPrimary)
                                .padding(12)
                                .background(entry.role == "student" ? Theme.accent : Theme.bgCard)
                                .cornerRadius(16)

                            if entry.role != "student" { Spacer() }
                        }
                    }
                }
                .padding(16)
            }

            Divider().background(Theme.border)

            // Input
            HStack(spacing: 12) {
                TextField("Your answer...", text: $viewModel.socraticInput)
                    .padding(12)
                    .background(Theme.bgElevated)
                    .cornerRadius(20)
                    .foregroundColor(Theme.textPrimary)

                Button(action: {
                    Task {
                        await viewModel.submitSocraticAnswer(chapter: chapter, context: modelContext)
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(viewModel.socraticInput.isEmpty ? Theme.textMuted : Theme.accent)
                }
                .disabled(viewModel.socraticInput.isEmpty || viewModel.isLoading)
            }
            .padding(12)
            .background(Theme.bgSurface)
        }
    }
}
