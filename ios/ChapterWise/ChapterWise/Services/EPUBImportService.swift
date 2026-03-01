import Foundation
import UIKit

actor EPUBImportService {
    static let shared = EPUBImportService()

    struct EPUBImportResult {
        let text: String
        let title: String
        let author: String?
        let coverImage: Data?
        let chapters: [(title: String, content: String)]?
    }

    /// Import and parse an EPUB file
    func importEPUB(from url: URL) async throws -> EPUBImportResult {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        // Create temp directory for extraction
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Unzip EPUB
        try await unzipFile(at: url, to: tempDir)

        // Parse container.xml to find content.opf
        let containerURL = tempDir.appendingPathComponent("META-INF/container.xml")
        let contentOPFPath = try parseContainerXML(at: containerURL)

        let opfURL = tempDir.appendingPathComponent(contentOPFPath)
        let opfDir = opfURL.deletingLastPathComponent()

        // Parse content.opf for metadata, manifest, and spine
        let opfResult = try parseOPF(at: opfURL)

        // Extract cover image
        var coverData: Data?
        if let coverHref = opfResult.coverHref {
            let coverURL = opfDir.appendingPathComponent(coverHref)
            coverData = try? Data(contentsOf: coverURL)
        }

        // Read spine items in order
        var allText = ""
        var chapters: [(title: String, content: String)] = []

        for spineItem in opfResult.spineItems {
            guard let href = opfResult.manifest[spineItem] else { continue }
            let itemURL = opfDir.appendingPathComponent(href)

            guard let htmlData = try? Data(contentsOf: itemURL),
                  let htmlString = String(data: htmlData, encoding: .utf8) else { continue }

            let text = stripHTML(htmlString)
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.count > 50 {
                // Try to extract a title from the HTML
                let title = extractTitle(from: htmlString) ?? "Section \(chapters.count + 1)"
                chapters.append((title: title, content: trimmed))
                allText += trimmed + "\n\n"
            }
        }

        guard !allText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ImportError.noContent
        }

        return EPUBImportResult(
            text: allText.trimmingCharacters(in: .whitespacesAndNewlines),
            title: opfResult.title ?? url.deletingPathExtension().lastPathComponent,
            author: opfResult.author,
            coverImage: coverData,
            chapters: chapters.count > 1 ? chapters : nil
        )
    }

    // MARK: - ZIP Extraction
    private func unzipFile(at sourceURL: URL, to destinationURL: URL) async throws {
        // Use Process or built-in unzip via FileManager
        // For iOS, we'll use a simple ZIP reader
        let data = try Data(contentsOf: sourceURL)
        try await extractZIP(data: data, to: destinationURL)
    }

    private func extractZIP(data: Data, to destination: URL) async throws {
        // Use Archive from Apple's compression support
        // We'll use a minimal ZIP parser
        let tempZipURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).zip")
        try data.write(to: tempZipURL)
        defer { try? FileManager.default.removeItem(at: tempZipURL) }

        // Use built-in unzip command via Process isn't available on iOS
        // Instead, use a simple approach: read the EPUB as a ZIP using Foundation
        guard let archive = ZIPArchive(data: data) else {
            throw ImportError.invalidEPUB
        }

        for entry in archive.entries {
            let entryURL = destination.appendingPathComponent(entry.path)
            let entryDir = entryURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: entryDir, withIntermediateDirectories: true)

            if !entry.path.hasSuffix("/") {
                try entry.data.write(to: entryURL)
            }
        }
    }

    // MARK: - Container.xml Parser
    private func parseContainerXML(at url: URL) throws -> String {
        guard let data = try? Data(contentsOf: url) else {
            throw ImportError.invalidEPUB
        }

        let parser = ContainerXMLParser(data: data)
        guard let rootfile = parser.parse() else {
            throw ImportError.invalidEPUB
        }

        return rootfile
    }

    // MARK: - OPF Parser
    struct OPFResult {
        var title: String?
        var author: String?
        var coverHref: String?
        var manifest: [String: String] = [:]  // id -> href
        var spineItems: [String] = []           // ordered item ids
    }

    private func parseOPF(at url: URL) throws -> OPFResult {
        guard let data = try? Data(contentsOf: url) else {
            throw ImportError.invalidEPUB
        }

        let parser = OPFParser(data: data)
        return parser.parse()
    }

    // MARK: - HTML Stripping
    private func stripHTML(_ html: String) -> String {
        // Remove script and style tags and their content
        var text = html
        let patterns = [
            "<script[^>]*>[\\s\\S]*?</script>",
            "<style[^>]*>[\\s\\S]*?</style>",
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                text = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "")
            }
        }

        // Replace block-level elements with newlines
        let blockElements = ["</p>", "</div>", "</h1>", "</h2>", "</h3>", "</h4>", "</h5>", "</h6>", "<br>", "<br/>", "<br />", "</li>", "</tr>"]
        for element in blockElements {
            text = text.replacingOccurrences(of: element, with: "\n", options: .caseInsensitive)
        }

        // Remove all remaining HTML tags
        if let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: []) {
            text = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "")
        }

        // Decode HTML entities
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&#39;", with: "'")
        text = text.replacingOccurrences(of: "&apos;", with: "'")
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        text = text.replacingOccurrences(of: "&#160;", with: " ")

        // Clean up whitespace
        if let regex = try? NSRegularExpression(pattern: "\\n{3,}", options: []) {
            text = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "\n\n")
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractTitle(from html: String) -> String? {
        // Try h1, h2, h3, title tags
        let patterns = [
            "<h1[^>]*>(.*?)</h1>",
            "<h2[^>]*>(.*?)</h2>",
            "<h3[^>]*>(.*?)</h3>",
            "<title[^>]*>(.*?)</title>"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               match.numberOfRanges >= 2 {
                let titleRange = match.range(at: 1)
                if let range = Range(titleRange, in: html) {
                    let title = stripHTML(String(html[range])).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !title.isEmpty && title.count < 200 {
                        return title
                    }
                }
            }
        }

        return nil
    }
}

// MARK: - Minimal ZIP Archive Reader
class ZIPArchive {
    struct Entry {
        let path: String
        let data: Data
    }

    let entries: [Entry]

    init?(data: Data) {
        guard data.count > 22 else { return nil }

        var entries: [Entry] = []
        var offset = 0
        let bytes = [UInt8](data)

        while offset < bytes.count - 4 {
            // Look for local file header signature: PK\x03\x04
            guard bytes[offset] == 0x50,
                  bytes[offset + 1] == 0x4B,
                  bytes[offset + 2] == 0x03,
                  bytes[offset + 3] == 0x04 else {
                // Check for central directory or end
                if bytes[offset] == 0x50 && bytes[offset + 1] == 0x4B {
                    break  // Reached central directory
                }
                offset += 1
                continue
            }

            guard offset + 30 <= bytes.count else { break }

            let compressionMethod = UInt16(bytes[offset + 8]) | (UInt16(bytes[offset + 9]) << 8)
            let compressedSize = Int(UInt32(bytes[offset + 18]) | (UInt32(bytes[offset + 19]) << 8) | (UInt32(bytes[offset + 20]) << 16) | (UInt32(bytes[offset + 21]) << 24))
            let uncompressedSize = Int(UInt32(bytes[offset + 22]) | (UInt32(bytes[offset + 23]) << 8) | (UInt32(bytes[offset + 24]) << 16) | (UInt32(bytes[offset + 25]) << 24))
            let fileNameLength = Int(UInt16(bytes[offset + 26]) | (UInt16(bytes[offset + 27]) << 8))
            let extraFieldLength = Int(UInt16(bytes[offset + 28]) | (UInt16(bytes[offset + 29]) << 8))

            let headerEnd = offset + 30
            guard headerEnd + fileNameLength <= bytes.count else { break }

            let fileNameBytes = Array(bytes[headerEnd..<(headerEnd + fileNameLength)])
            guard let fileName = String(bytes: fileNameBytes, encoding: .utf8) else {
                offset = headerEnd + fileNameLength + extraFieldLength + compressedSize
                continue
            }

            let dataStart = headerEnd + fileNameLength + extraFieldLength

            if compressedSize > 0 && dataStart + compressedSize <= bytes.count {
                let fileData: Data

                if compressionMethod == 0 {
                    // Stored (no compression)
                    fileData = Data(bytes[dataStart..<(dataStart + compressedSize)])
                } else if compressionMethod == 8 {
                    // Deflate
                    let compressed = Data(bytes[dataStart..<(dataStart + compressedSize)])
                    if let decompressed = compressed.decompress(size: uncompressedSize) {
                        fileData = decompressed
                    } else {
                        fileData = compressed  // Fallback: use raw data
                    }
                } else {
                    fileData = Data(bytes[dataStart..<(dataStart + compressedSize)])
                }

                entries.append(Entry(path: fileName, data: fileData))
            } else if !fileName.hasSuffix("/") {
                entries.append(Entry(path: fileName, data: Data()))
            }

            offset = dataStart + compressedSize
        }

        guard !entries.isEmpty else { return nil }
        self.entries = entries
    }
}

// MARK: - Data Decompression
extension Data {
    func decompress(size: Int) -> Data? {
        guard !self.isEmpty else { return nil }

        var decompressed = Data(count: size)
        let result = decompressed.withUnsafeMutableBytes { destBuffer in
            self.withUnsafeBytes { sourceBuffer in
                guard let destPtr = destBuffer.baseAddress,
                      let sourcePtr = sourceBuffer.baseAddress else { return -1 }
                return Int(compression_decode_buffer(
                    destPtr.assumingMemoryBound(to: UInt8.self), size,
                    sourcePtr.assumingMemoryBound(to: UInt8.self), self.count,
                    nil,
                    COMPRESSION_ZLIB
                ))
            }
        }

        guard result > 0 else { return nil }
        decompressed.count = result
        return decompressed
    }
}

// MARK: - XML Parsers
class ContainerXMLParser: NSObject, XMLParserDelegate {
    private let data: Data
    private var rootfilePath: String?

    init(data: Data) {
        self.data = data
    }

    func parse() -> String? {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return rootfilePath
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "rootfile" || elementName.hasSuffix(":rootfile") {
            rootfilePath = attributeDict["full-path"]
        }
    }
}

class OPFParser: NSObject, XMLParserDelegate {
    private let data: Data
    private var result = EPUBImportService.OPFResult()
    private var currentElement = ""
    private var currentText = ""
    private var inMetadata = false
    private var coverId: String?

    init(data: Data) {
        self.data = data
    }

    func parse() -> EPUBImportService.OPFResult {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()

        // Resolve cover image
        if let coverId = coverId, let href = result.manifest[coverId] {
            result.coverHref = href
        } else {
            // Try common cover patterns
            for (id, href) in result.manifest {
                let lower = id.lowercased()
                if lower.contains("cover") && (href.hasSuffix(".jpg") || href.hasSuffix(".jpeg") || href.hasSuffix(".png")) {
                    result.coverHref = href
                    break
                }
            }
        }

        return result
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        let localName = elementName.components(separatedBy: ":").last ?? elementName
        currentElement = localName
        currentText = ""

        switch localName {
        case "metadata":
            inMetadata = true
        case "item":
            if let id = attributeDict["id"], let href = attributeDict["href"] {
                result.manifest[id] = href
            }
        case "itemref":
            if let idref = attributeDict["idref"] {
                result.spineItems.append(idref)
            }
        case "meta":
            if attributeDict["name"] == "cover" {
                coverId = attributeDict["content"]
            }
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let localName = elementName.components(separatedBy: ":").last ?? elementName
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        if inMetadata {
            switch localName {
            case "title":
                if !text.isEmpty { result.title = text }
            case "creator":
                if !text.isEmpty { result.author = text }
            case "metadata":
                inMetadata = false
            default:
                break
            }
        }
    }
}
