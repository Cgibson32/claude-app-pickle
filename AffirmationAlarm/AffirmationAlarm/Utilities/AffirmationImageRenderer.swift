import SwiftUI

@MainActor
enum AffirmationImageRenderer {
    static func renderImage(text: String) -> UIImage? {
        let view = ShareableAffirmationCard(text: text)
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
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
