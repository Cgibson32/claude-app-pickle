import SwiftUI

struct PPCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(PickleProColors.cardBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct PPAccentCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(PickleProColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(PickleProColors.accent.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: PickleProColors.accent.opacity(0.1), radius: 12, x: 0, y: 4)
    }
}
