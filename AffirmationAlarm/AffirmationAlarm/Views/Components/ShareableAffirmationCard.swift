import SwiftUI

struct ShareableAffirmationCard: View {
    let text: String

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "quote.opening")
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "FFF5EB").opacity(0.6))

            Text(text)
                .font(.custom("Sora-SemiBold", size: 20))
                .foregroundColor(Color(hex: "FFF5EB"))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 32)

            Text("— Affirmation Alarm")
                .font(.custom("DMSans-Regular", size: 12))
                .foregroundColor(Color(hex: "FFF5EB").opacity(0.5))
        }
        .padding(40)
        .frame(width: 400)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "1A1A2E"),
                    Color(hex: "2D1B4E"),
                    Color(hex: "7C3A1C")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

#Preview {
    ShareableAffirmationCard(text: "I am worthy of all the good things coming my way today.")
        .padding()
        .background(Color.black)
}
