import SwiftUI

enum AffirmationImageRenderer {
    @MainActor
    static func renderUIImage(text: String) -> UIImage? {
        let view = ShareableAffirmationCard(text: text)
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    @MainActor
    static func share(text: String) {
        guard let image = renderUIImage(text: text) else { return }
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            activityVC.popoverPresentationController?.sourceView = topVC.view
            topVC.present(activityVC, animated: true)
        }
    }
}
