import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedBook: Book?
    @State private var selectedChapter: Chapter?
    @State private var showSettings = false
    @State private var showImporter = false
    @State private var toastMessage: String?
    @State private var toastType: ToastType = .success
    @State private var navigationPath = NavigationPath()

    var body: some View {
        ZStack {
            Theme.bgSurface.ignoresSafeArea()

            NavigationStack(path: $navigationPath) {
                LibraryView(
                    onBookSelected: { book in
                        navigationPath.append(BookNavigation.bookDetail(book))
                    },
                    onShowSettings: { showSettings = true },
                    onShowImporter: { showImporter = true },
                    showToast: showToast
                )
                .navigationDestination(for: BookNavigation.self) { nav in
                    switch nav {
                    case .bookDetail(let book):
                        BookDetailView(
                            book: book,
                            onChapterSelected: { chapter in
                                navigationPath.append(BookNavigation.reader(chapter))
                            },
                            showToast: showToast
                        )
                    case .reader(let chapter):
                        ReaderView(
                            chapter: chapter,
                            showToast: showToast
                        )
                    }
                }
            }
            .tint(Theme.accent)

            // Persistent Audio Player
            VStack {
                Spacer()
                PersistentAudioPlayer()
            }
            .ignoresSafeArea(.keyboard)

            // Toast overlay
            if let message = toastMessage {
                VStack {
                    Spacer()
                    ToastView(message: message, type: toastType)
                        .padding(.bottom, AudioPlayerService.shared.isVisible ? 80 : 16)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.3), value: toastMessage)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(showToast: showToast)
        }
        .sheet(isPresented: $showImporter) {
            BookImportView(showToast: showToast)
        }
    }

    private func showToast(_ message: String, _ type: ToastType = .success) {
        withAnimation {
            toastMessage = message
            toastType = type
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                if toastMessage == message {
                    toastMessage = nil
                }
            }
        }
    }
}

// MARK: - Navigation Types
enum BookNavigation: Hashable {
    case bookDetail(Book)
    case reader(Chapter)
}
