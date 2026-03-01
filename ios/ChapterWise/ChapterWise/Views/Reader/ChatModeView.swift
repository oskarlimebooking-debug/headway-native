import SwiftUI
import SwiftData

struct ChatModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: ReaderViewModel
    let chapter: Chapter

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.chatMessages.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 32))
                                    .foregroundColor(Theme.textMuted)
                                Text("Ask anything about this chapter")
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .padding(.top, 40)
                        }

                        ForEach(Array(viewModel.chatMessages.enumerated()), id: \.offset) { index, message in
                            HStack {
                                if message.role == "user" { Spacer() }

                                Text(message.content)
                                    .font(.system(size: 14))
                                    .foregroundColor(message.role == "user" ? .white : Theme.textPrimary)
                                    .padding(12)
                                    .background(message.role == "user" ? Theme.accent : Theme.bgCard)
                                    .cornerRadius(16)
                                    .textSelection(.enabled)

                                if message.role != "user" { Spacer() }
                            }
                            .id(index)
                        }

                        if viewModel.isChatLoading {
                            HStack {
                                ProgressView()
                                    .tint(Theme.accent)
                                    .padding(12)
                                    .background(Theme.bgCard)
                                    .cornerRadius(16)
                                Spacer()
                            }
                        }
                    }
                    .padding(16)
                }
                .onChange(of: viewModel.chatMessages.count) { _, _ in
                    withAnimation {
                        proxy.scrollTo(viewModel.chatMessages.count - 1)
                    }
                }
            }

            Divider().background(Theme.border)

            // Input
            HStack(spacing: 12) {
                TextField("Ask about this chapter...", text: $viewModel.chatInput)
                    .padding(12)
                    .background(Theme.bgElevated)
                    .cornerRadius(20)
                    .foregroundColor(Theme.textPrimary)

                Button(action: {
                    Task {
                        await viewModel.sendChatMessage(chapter: chapter, context: modelContext)
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(viewModel.chatInput.isEmpty ? Theme.textMuted : Theme.accent)
                }
                .disabled(viewModel.chatInput.isEmpty || viewModel.isChatLoading)
            }
            .padding(12)
            .background(Theme.bgSurface)
        }
    }
}
