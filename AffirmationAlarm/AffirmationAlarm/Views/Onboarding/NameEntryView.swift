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
                    .foregroundColor(AppTheme.textSecondary)

                Text("What should we call you?")
                    .font(AppTheme.title2)
                    .foregroundColor(AppTheme.textPrimary)

                Text("We'll use your name to make your\nmorning affirmations feel personal.")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            TextField("Your name", text: $name)
                .font(AppTheme.title3)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.inputBackground)
                )
                .foregroundColor(AppTheme.textPrimary)
                .tint(AppTheme.textPrimary)
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
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.accentText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(name.trimmingCharacters(in: .whitespaces).isEmpty ? AppTheme.buttonDisabled : AppTheme.buttonBackground)
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
