import SwiftUI
import SwiftData

struct EveningReflectionSettingsView: View {
    @Query private var profiles: [UserProfile]
    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            GradientBackground(style: .sunrise, withBlobs: false)

            ScrollView {
                VStack(spacing: AppTheme.spacingXxl) {
                    if let profile {
                        Toggle(isOn: Binding(
                            get: { profile.eveningReflectionEnabled },
                            set: { profile.eveningReflectionEnabled = $0 }
                        )) {
                            Text("Evening Reminders")
                                .font(AppTheme.headline)
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                        .tint(AppTheme.sunsetOrange)
                        .padding(AppTheme.spacingLg)
                        .background(AppTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))

                        if profile.eveningReflectionEnabled {
                            VStack(spacing: AppTheme.spacingMd) {
                                Text("Reminder Time")
                                    .font(AppTheme.headline)
                                    .foregroundStyle(AppTheme.textPrimary)

                                DatePicker(
                                    "Time",
                                    selection: Binding(
                                        get: {
                                            Calendar.current.date(
                                                from: DateComponents(hour: profile.eveningReflectionHour, minute: profile.eveningReflectionMinute)
                                            ) ?? Date()
                                        },
                                        set: { date in
                                            profile.eveningReflectionHour = Calendar.current.component(.hour, from: date)
                                            profile.eveningReflectionMinute = Calendar.current.component(.minute, from: date)
                                        }
                                    ),
                                    displayedComponents: .hourAndMinute
                                )
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .frame(height: 120)
                            }
                            .padding(AppTheme.spacingLg)
                            .background(AppTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }
                .padding(AppTheme.spacingXl)
                .animation(AppTheme.bouncy, value: profile?.eveningReflectionEnabled)
            }
        }
        .navigationTitle("Evening Reflection")
        .navigationBarTitleDisplayMode(.inline)
    }
}
