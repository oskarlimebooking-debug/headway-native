import SwiftUI
import SwiftData

@main
struct ChapterWiseApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [
            Book.self,
            Chapter.self,
            GeneratedContent.self,
            ReadingProgress.self,
            AppSettings.self
        ])
    }
}
