import SwiftUI

enum ToastType {
    case success
    case error
    case warning
    case info

    var color: Color {
        switch self {
        case .success: return Theme.success
        case .error: return Theme.error
        case .warning: return Theme.warning
        case .info: return Theme.accent
        }
    }

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

struct ToastView: View {
    let message: String
    let type: ToastType

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusMd)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusMd)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 20)
    }
}
