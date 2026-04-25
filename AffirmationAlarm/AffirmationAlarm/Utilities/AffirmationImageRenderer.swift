import SwiftUI

@MainActor
enum AffirmationImageRenderer {
    static func renderImage(text: String) -> UIImage? {
        let view = ShareableAffirmationCard(text: text)
        let renderer = ImageRenderer(content: view)
        // Card is 540×675 pt. Scale 2 → 1080×1350 px, the Instagram feed
        // 4:5 ratio. Fixed (not UIScreen.main.scale) so shares look identical
        // from every device — no surprise downscale on older hardware.
        renderer.scale = 2.0
        return renderer.uiImage
    }

    static func share(text: String, from viewController: UIViewController? = nil) {
        guard let image = renderImage(text: text) else { return }
        let activityVC = UIActivityViewController(activityItems: [image, text], applicationActivities: nil)

        if let vc = viewController ?? UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController {
            vc.present(activityVC, animated: true)
        }
    }
}
