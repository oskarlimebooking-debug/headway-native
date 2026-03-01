import SwiftUI

// MARK: - String Extensions
extension String {
    /// Truncate string to a maximum length with ellipsis
    func truncated(to length: Int) -> String {
        if self.count <= length { return self }
        return String(self.prefix(length)) + "..."
    }

    /// Count words in the string
    var wordCount: Int {
        let words = self.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return words.count
    }

    /// Estimated reading time in minutes
    func readingTime(wordsPerMinute: Int = 200) -> Int {
        max(1, wordCount / wordsPerMinute)
    }

    /// Strip HTML tags from string
    var strippedHTML: String {
        guard let data = self.data(using: .utf8) else { return self }
        if let attributed = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html,
                      .characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil
        ) {
            return attributed.string
        }
        // Fallback: regex-based stripping
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    /// Extract JSON from a string that might contain markdown code blocks
    var extractedJSON: String {
        var text = self.trimmingCharacters(in: .whitespacesAndNewlines)
        // Remove markdown code blocks
        if text.hasPrefix("```json") {
            text = String(text.dropFirst(7))
        } else if text.hasPrefix("```") {
            text = String(text.dropFirst(3))
        }
        if text.hasSuffix("```") {
            text = String(text.dropLast(3))
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Date Extensions
extension Date {
    /// Format as "Today", "Yesterday", or "MMM d, yyyy"
    var relativeDisplay: String {
        if Calendar.current.isDateInToday(self) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(self) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: self)
        }
    }

    /// Format as "yyyy-MM-dd" for storage keys
    var dateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}

// MARK: - View Extensions
extension View {
    /// Apply card styling matching PWA .book-card
    func cardStyle() -> some View {
        self
            .background(Theme.bgCard)
            .cornerRadius(Theme.radiusMd)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusMd)
                    .stroke(Theme.border, lineWidth: 1)
            )
    }

    /// Apply elevated card styling
    func elevatedCardStyle() -> some View {
        self
            .background(Theme.bgElevated)
            .cornerRadius(Theme.radiusMd)
            .shadow(color: Theme.shadow, radius: 12, x: 0, y: 4)
    }
}

// MARK: - Data Extensions
extension Data {
    /// Convert data to hex string
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Array Extensions
extension Array {
    /// Safe subscript that returns nil for out-of-bounds indices
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
