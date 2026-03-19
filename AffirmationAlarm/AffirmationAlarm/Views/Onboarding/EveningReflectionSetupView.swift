import SwiftUI

struct EveningReflectionSetupView: View {
    @Binding var eveningReflectionEnabled: Bool
    @Binding var eveningReflectionTime: Date
    var onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 56))
                .foregroundColor(AppTheme.gold)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.5)

            // Title
            VStack(spacing: 8) {
                Text("Evening Reflection")
                    .font(AppTheme.title2)
                    .foregroundColor(AppTheme.textPrimary)

                Text("End your day with gratitude\nand self-reflection")
                    .font(AppTheme.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)

            // Toggle
            Toggle(isOn: $eveningReflectionEnabled) {
                Text("Enable evening reminders")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.textPrimary)
            }
            .tint(AppTheme.accent)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.cardBackground)
            )
            .opacity(appeared ? 1 : 0)

            // Time picker (shown when enabled)
            if eveningReflectionEnabled {
                VStack(spacing: 8) {
                    Text("Reminder Time")
                        .font(AppTheme.subheadline)
                        .foregroundColor(AppTheme.textSecondary)

                    DatePicker("", selection: $eveningReflectionTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .colorScheme(.dark)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer()

            // Continue button
            Button {
                HapticService.medium()
                onContinue()
            } label: {
                Text("Continue")
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.accentText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(AppTheme.buttonBackground))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
            .opacity(appeared ? 1 : 0)
        }
        .animation(.easeInOut(duration: 0.3), value: eveningReflectionEnabled)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }
}

#Preview {
    ZStack {
        GradientBackground()
        EveningReflectionSetupView(
            eveningReflectionEnabled: .constant(true),
            eveningReflectionTime: .constant(Date()),
            onContinue: {}
        )
    }
}
