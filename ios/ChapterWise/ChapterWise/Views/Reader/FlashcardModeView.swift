import SwiftUI

struct FlashcardModeView: View {
    @Bindable var viewModel: ReaderViewModel

    var body: some View {
        VStack(spacing: 24) {
            if let flashcards = viewModel.flashcardsResult?.flashcards, !flashcards.isEmpty {
                Spacer()

                // Counter
                Text("\(viewModel.currentFlashcardIndex + 1) / \(flashcards.count)")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textMuted)

                // Card
                let card = flashcards[viewModel.currentFlashcardIndex]
                Button(action: {
                    withAnimation(.spring(response: 0.4)) {
                        viewModel.isFlipped.toggle()
                    }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: Theme.radiusLg)
                            .fill(viewModel.isFlipped ? Theme.accent.opacity(0.1) : Theme.bgCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.radiusLg)
                                    .stroke(viewModel.isFlipped ? Theme.accent : Theme.border, lineWidth: 1)
                            )

                        VStack(spacing: 12) {
                            Text(viewModel.isFlipped ? "ANSWER" : "QUESTION")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.5)
                                .foregroundColor(viewModel.isFlipped ? Theme.accent : Theme.textMuted)

                            Text(viewModel.isFlipped ? card.back : card.front)
                                .font(.system(size: 18, design: .serif))
                                .foregroundColor(Theme.textPrimary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                    .frame(height: 280)
                    .rotation3DEffect(
                        .degrees(viewModel.isFlipped ? 180 : 0),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.5
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)

                Text("Tap to flip")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textMuted)

                // Navigation
                HStack(spacing: 40) {
                    Button(action: {
                        withAnimation {
                            viewModel.currentFlashcardIndex = max(0, viewModel.currentFlashcardIndex - 1)
                            viewModel.isFlipped = false
                        }
                    }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(viewModel.currentFlashcardIndex > 0 ? Theme.accent : Theme.bgElevated)
                    }
                    .disabled(viewModel.currentFlashcardIndex == 0)

                    Button(action: {
                        withAnimation {
                            viewModel.currentFlashcardIndex = min(flashcards.count - 1, viewModel.currentFlashcardIndex + 1)
                            viewModel.isFlipped = false
                        }
                    }) {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(viewModel.currentFlashcardIndex < flashcards.count - 1 ? Theme.accent : Theme.bgElevated)
                    }
                    .disabled(viewModel.currentFlashcardIndex >= flashcards.count - 1)
                }

                Spacer()
            } else {
                Text("No flashcards available")
                    .foregroundColor(Theme.textMuted)
            }
        }
    }
}
