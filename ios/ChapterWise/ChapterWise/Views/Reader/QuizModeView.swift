import SwiftUI

struct QuizModeView: View {
    @Bindable var viewModel: ReaderViewModel

    var body: some View {
        ScrollView {
            if let quiz = viewModel.quizResult {
                VStack(spacing: 20) {
                    ForEach(Array(quiz.questions.enumerated()), id: \.offset) { index, question in
                        VStack(alignment: .leading, spacing: 12) {
                            // Question header
                            HStack {
                                Text("Q\(index + 1)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Theme.accent)
                                    .cornerRadius(8)

                                Text(question.type.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textMuted)
                            }

                            Text(question.question)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Theme.textPrimary)

                            // Options (for multiple choice)
                            if let options = question.options {
                                ForEach(Array(options.enumerated()), id: \.offset) { optIndex, option in
                                    Button(action: {
                                        if !viewModel.quizSubmitted {
                                            viewModel.quizAnswers[index] = optIndex
                                        }
                                    }) {
                                        HStack {
                                            Text(option)
                                                .font(.system(size: 14))
                                                .foregroundColor(Theme.textPrimary)
                                            Spacer()

                                            if viewModel.quizSubmitted {
                                                if optIndex == question.correctIndex {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(Theme.success)
                                                } else if viewModel.quizAnswers[safe: index] == optIndex {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(Theme.error)
                                                }
                                            } else if viewModel.quizAnswers[safe: index] == optIndex {
                                                Image(systemName: "circle.fill")
                                                    .foregroundColor(Theme.accent)
                                                    .font(.system(size: 10))
                                            }
                                        }
                                        .padding(12)
                                        .background(
                                            viewModel.quizSubmitted && optIndex == question.correctIndex ? Theme.success.opacity(0.15) :
                                            viewModel.quizAnswers[safe: index] == optIndex ? Theme.accentSoft :
                                            Theme.bgElevated
                                        )
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            // True/False
                            if question.type == "true_false" {
                                HStack(spacing: 12) {
                                    ForEach([("True", 0), ("False", 1)], id: \.1) { label, value in
                                        Button(action: {
                                            if !viewModel.quizSubmitted {
                                                viewModel.quizAnswers[index] = value
                                            }
                                        }) {
                                            Text(label)
                                                .font(.system(size: 14, weight: .medium))
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(
                                                    viewModel.quizAnswers[safe: index] == value ? Theme.accentSoft : Theme.bgElevated
                                                )
                                                .foregroundColor(Theme.textPrimary)
                                                .cornerRadius(8)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            // Explanation (shown after submit)
                            if viewModel.quizSubmitted, let explanation = question.explanation {
                                Text(explanation)
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.textSecondary)
                                    .padding(12)
                                    .background(Theme.bgElevated)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(16)
                        .background(Theme.bgCard)
                        .cornerRadius(Theme.radiusMd)
                    }

                    // Submit / Score
                    if !viewModel.quizSubmitted {
                        Button(action: { viewModel.quizSubmitted = true }) {
                            Text("Submit Answers")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Theme.accentGradient)
                                .cornerRadius(Theme.radiusMd)
                        }
                    } else {
                        let correct = zip(viewModel.quizAnswers, quiz.questions).filter { answer, q in
                            if q.type == "multiple_choice" { return answer == q.correctIndex }
                            if q.type == "true_false" { return (answer == 0) == (q.correct ?? true) }
                            return false
                        }.count
                        let total = quiz.questions.filter { $0.type != "open_ended" }.count

                        Text("Score: \(correct)/\(total)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Theme.accent)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.bgCard)
                            .cornerRadius(Theme.radiusMd)
                    }
                }
                .padding(16)
            }
        }
    }
}
