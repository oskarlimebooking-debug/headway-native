import SwiftUI

struct BookCardView: View {
    let book: Book
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Cover
                ZStack {
                    if let coverData = book.coverImageData,
                       let uiImage = UIImage(data: coverData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(3/4, contentMode: .fill)
                            .clipped()
                            .cornerRadius(Theme.radiusSm)
                    } else {
                        RoundedRectangle(cornerRadius: Theme.radiusSm)
                            .fill(
                                LinearGradient(
                                    colors: [Theme.bgElevated, Theme.bgSurface],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .aspectRatio(3/4, contentMode: .fit)
                            .overlay(
                                Text(book.emoji)
                                    .font(.system(size: 40))
                            )
                    }
                }

                // Title
                Text(book.title)
                    .font(.system(size: 14, design: .serif))
                    .fontWeight(.medium)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(2)

                // Tags
                if !book.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(book.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.accentSoft)
                                .foregroundColor(Theme.accent)
                                .cornerRadius(10)
                        }
                    }
                }

                // Progress
                Text("\(book.completedChapters)/\(book.totalChapters) chapters")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textMuted)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.bgElevated)
                            .frame(height: 3)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.accent)
                            .frame(width: geo.size.width * book.progress, height: 3)
                    }
                }
                .frame(height: 3)
            }
            .padding(16)
            .background(Theme.bgCard)
            .cornerRadius(Theme.radiusMd)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusMd)
                    .stroke(Theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
