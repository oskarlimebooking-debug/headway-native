import SwiftUI

struct ImportProgressView: View {
    let message: String
    var progress: Double?

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(Theme.accent)
                .scaleEffect(1.5)

            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)

            if let progress = progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.bgElevated)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.accent)
                            .frame(width: geo.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)
                .padding(.horizontal, 40)

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textMuted)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgSurface.opacity(0.95))
    }
}
