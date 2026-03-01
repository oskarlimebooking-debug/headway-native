import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BookImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = LibraryViewModel()
    @State private var showFilePicker = false
    @State private var isScannedPDF = false
    @State private var scannedPDFURL: URL?
    let showToast: (String, ToastType) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgSurface.ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // Icon
                    VStack(spacing: 16) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.accent)

                        Text("Add a Book")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Theme.textPrimary)

                        Text("Import a PDF or EPUB file.\nThe AI will split it into chapters automatically.")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    // Import button
                    Button(action: { showFilePicker = true }) {
                        HStack {
                            Image(systemName: "folder")
                            Text("Choose File")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accentGradient)
                        .cornerRadius(Theme.radiusMd)
                    }
                    .padding(.horizontal, 40)

                    Text("Supported: PDF, EPUB (up to 15MB)")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textMuted)

                    Spacer()
                }

                // Processing overlay
                if viewModel.isImporting {
                    ImportProgressView(message: viewModel.importProgress ?? "Processing...")
                }

                // Scanned PDF alert overlay
                if isScannedPDF {
                    VStack(spacing: 16) {
                        Text("Scanned PDF Detected")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Theme.textPrimary)

                        Text("This PDF appears to contain scanned images instead of text. Would you like to use AI OCR to extract the text?")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 12) {
                            Button("Cancel") {
                                isScannedPDF = false
                                scannedPDFURL = nil
                            }
                            .foregroundColor(Theme.textSecondary)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Theme.bgElevated)
                            .cornerRadius(Theme.radiusSm)

                            Button("Use AI OCR") {
                                if let url = scannedPDFURL {
                                    isScannedPDF = false
                                    Task {
                                        await performOCRImport(url: url)
                                    }
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Theme.accentGradient)
                            .cornerRadius(Theme.radiusSm)
                        }
                    }
                    .padding(24)
                    .background(Theme.bgCard)
                    .cornerRadius(Theme.radiusMd)
                    .padding(32)
                    .shadow(color: .black.opacity(0.4), radius: 20)
                }
            }
            .navigationTitle("Import Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [
                    UTType(filenameExtension: "pdf") ?? .pdf,
                    UTType(filenameExtension: "epub") ?? .data
                ],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    Task {
                        do {
                            try await viewModel.importFile(url: url, context: modelContext)
                            showToast("Book imported successfully!", .success)
                            dismiss()
                        } catch let error as ImportError where error == .scannedPDF {
                            scannedPDFURL = url
                            isScannedPDF = true
                        } catch {
                            showToast("Import failed: \(error.localizedDescription)", .error)
                        }
                    }
                case .failure(let error):
                    showToast("File selection failed: \(error.localizedDescription)", .error)
                }
            }
        }
    }

    private func performOCRImport(url: URL) async {
        viewModel.isImporting = true
        viewModel.importProgress = "Running AI OCR..."

        do {
            let apiKeyDescriptor = FetchDescriptor<AppSettings>(
                predicate: #Predicate { $0.key == "geminiApiKey" }
            )
            guard let apiKey = try? modelContext.fetch(apiKeyDescriptor).first?.value, !apiKey.isEmpty else {
                showToast("No API key configured. Add your Gemini API key in Settings.", .error)
                viewModel.isImporting = false
                return
            }

            let result = try await PDFImportService.shared.ocrPDF(from: url, apiKey: apiKey) { current, total in
                Task { @MainActor in
                    viewModel.importProgress = "OCR: Page \(current)/\(total)"
                }
            }

            viewModel.importProgress = "Splitting into chapters..."

            let chapters = try await GeminiService.shared.splitIntoChapters(
                text: result.text,
                bookTitle: result.title ?? "Untitled",
                apiKey: apiKey
            )

            await MainActor.run {
                let book = Book(title: result.title ?? "Untitled", totalChapters: chapters.count)
                book.originalPDFData = result.pdfData
                modelContext.insert(book)

                for (index, chapterData) in chapters.enumerated() {
                    let chapter = Chapter(
                        bookId: book.id,
                        title: chapterData.title,
                        content: chapterData.content,
                        order: index
                    )
                    chapter.book = book
                    modelContext.insert(chapter)
                }

                try? modelContext.save()
            }

            showToast("Book imported with OCR!", .success)
            dismiss()
        } catch {
            showToast("OCR failed: \(error.localizedDescription)", .error)
        }

        viewModel.isImporting = false
        viewModel.importProgress = nil
    }
}

// Make ImportError equatable for pattern matching
extension ImportError: Equatable {
    static func == (lhs: ImportError, rhs: ImportError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidPDF, .invalidPDF): return true
        case (.scannedPDF, .scannedPDF): return true
        case (.invalidEPUB, .invalidEPUB): return true
        case (.noContent, .noContent): return true
        case (.fileAccessDenied, .fileAccessDenied): return true
        default: return false
        }
    }
}
