import Foundation
import PDFKit
import UIKit

actor PDFImportService {
    static let shared = PDFImportService()

    struct PDFImportResult {
        let text: String
        let title: String?
        let pageCount: Int
        let pdfData: Data
    }

    /// Extract text from a PDF file
    func importPDF(from url: URL) async throws -> PDFImportResult {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        let data = try Data(contentsOf: url)
        guard let document = PDFDocument(data: data) else {
            throw ImportError.invalidPDF
        }

        let pageCount = document.pageCount
        var allText = ""
        var hasText = false

        for i in 0..<pageCount {
            guard let page = document.page(at: i) else { continue }
            if let pageText = page.string, !pageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                allText += pageText + "\n\n"
                hasText = true
            }
        }

        if !hasText || allText.trimmingCharacters(in: .whitespacesAndNewlines).count < 100 {
            throw ImportError.scannedPDF
        }

        let title = document.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String
            ?? url.deletingPathExtension().lastPathComponent

        return PDFImportResult(
            text: allText.trimmingCharacters(in: .whitespacesAndNewlines),
            title: title,
            pageCount: pageCount,
            pdfData: data
        )
    }

    /// Render PDF pages to images for OCR (scanned PDFs)
    func renderPagesAsImages(from url: URL, dpi: CGFloat = 200) async throws -> [(pageNum: Int, image: UIImage)] {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        let data = try Data(contentsOf: url)
        guard let document = PDFDocument(data: data) else {
            throw ImportError.invalidPDF
        }

        var images: [(pageNum: Int, image: UIImage)] = []
        let scale = dpi / 72.0

        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }
            let pageRect = page.bounds(for: .mediaBox)
            let scaledSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)

            let renderer = UIGraphicsImageRenderer(size: scaledSize)
            let image = renderer.image { ctx in
                UIColor.white.setFill()
                ctx.fill(CGRect(origin: .zero, size: scaledSize))

                ctx.cgContext.translateBy(x: 0, y: scaledSize.height)
                ctx.cgContext.scaleBy(x: scale, y: -scale)

                page.draw(with: .mediaBox, to: ctx.cgContext)
            }

            images.append((pageNum: i + 1, image: image))
        }

        return images
    }

    /// OCR a scanned PDF using Gemini Vision API
    func ocrPDF(from url: URL, apiKey: String, model: String? = nil, progressHandler: ((Int, Int) -> Void)? = nil) async throws -> PDFImportResult {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        let data = try Data(contentsOf: url)
        let pages = try await renderPagesAsImages(from: url)
        var allText = ""

        for (index, page) in pages.enumerated() {
            progressHandler?(index + 1, pages.count)

            guard let imageData = page.image.jpegData(compressionQuality: 0.8) else { continue }

            let text = try await GeminiService.shared.performOCR(imageData: imageData, apiKey: apiKey, model: model)
            allText += text + "\n\n"

            // Rate limiting
            if index < pages.count - 1 {
                try await Task.sleep(nanoseconds: 300_000_000)
            }
        }

        let title = url.deletingPathExtension().lastPathComponent

        return PDFImportResult(
            text: allText.trimmingCharacters(in: .whitespacesAndNewlines),
            title: title,
            pageCount: pages.count,
            pdfData: data
        )
    }
}

enum ImportError: LocalizedError {
    case invalidPDF
    case scannedPDF
    case invalidEPUB
    case noContent
    case fileAccessDenied

    var errorDescription: String? {
        switch self {
        case .invalidPDF: return "Could not open PDF file"
        case .scannedPDF: return "This PDF appears to be scanned. Use OCR to extract text."
        case .invalidEPUB: return "Could not open EPUB file"
        case .noContent: return "No readable content found"
        case .fileAccessDenied: return "Cannot access the selected file"
        }
    }
}
