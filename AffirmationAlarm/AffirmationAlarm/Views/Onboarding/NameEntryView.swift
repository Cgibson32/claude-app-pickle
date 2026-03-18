import SwiftUI

struct NameEntryView: View {
    @Binding var name: String
    let onContinue: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.9))

                Text("What should we call you?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("We'll use your name to make your\nmorning affirmations feel personal.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }

            TextField("Your name", text: $name)
                .font(.title3)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.2))
                )
                .foregroundColor(.white)
                .tint(.white)
                .focused($isFocused)
                .submitLabel(.continue)
                .onSubmit {
                    if !name.trimmingCharacters(in: .whitespaces).isEmpty {
                        onContinue()
                    }
                }

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(name.trimmingCharacters(in: .whitespaces).isEmpty ? .white.opacity(0.4) : .white)
                    )
            }
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.horizontal, 40)

            Spacer()
                .frame(height: 60)
        }
        .padding()
        .onAppear {
            isFocused = true
        }
    }
}

#Preview {
    ZStack {
        GradientBackground()
        NameEntryView(name: .constant("Corey"), onContinue: {})
    }
}
