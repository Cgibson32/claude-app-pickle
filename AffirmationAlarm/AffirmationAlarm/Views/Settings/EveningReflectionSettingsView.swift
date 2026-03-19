import SwiftUI
import SwiftData

struct EveningReflectionSettingsView: View {
    @Bindable var profile: UserProfile

    private var reflectionTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: DateComponents(hour: profile.eveningReflectionHour, minute: profile.eveningReflectionMinute)) ?? Date()
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                profile.eveningReflectionHour = components.hour ?? 20
                profile.eveningReflectionMinute = components.minute ?? 0
                if profile.eveningReflectionEnabled {
                    EveningReflectionSchedulingService.shared.scheduleEveningNotification(
                        hour: profile.eveningReflectionHour,
                        minute: profile.eveningReflectionMinute
                    )
                }
            }
        )
    }

    var body: some View {
        ZStack {
            GradientBackground()

            ScrollView {
                VStack(spacing: 20) {
                    // Toggle
                    VStack(spacing: 12) {
                        Toggle(isOn: $profile.eveningReflectionEnabled) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Evening Reflection")
                                    .font(AppTheme.headline)
                                    .foregroundColor(AppTheme.textPrimary)
                                Text("Receive a gentle reminder to reflect on your day")
                                    .font(AppTheme.caption)
                                    .foregroundColor(AppTheme.textTertiary)
                            }
                        }
                        .tint(AppTheme.accent)
                        .onChange(of: profile.eveningReflectionEnabled) { _, enabled in
                            if enabled {
                                EveningReflectionSchedulingService.shared.scheduleEveningNotification(
                                    hour: profile.eveningReflectionHour,
                                    minute: profile.eveningReflectionMinute
                                )
                            } else {
                                EveningReflectionSchedulingService.shared.cancelEveningNotification()
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AppTheme.cardBackground)
                    )

                    // Time picker
                    if profile.eveningReflectionEnabled {
                        VStack(spacing: 12) {
                            Text("Reflection Time")
                                .font(AppTheme.headline)
                                .foregroundColor(AppTheme.textPrimary)

                            DatePicker("", selection: reflectionTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .colorScheme(.dark)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(AppTheme.cardBackground)
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding()
                .padding(.top, 20)
            }
        }
        .navigationTitle("Evening Reflection")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.3), value: profile.eveningReflectionEnabled)
    }
}
