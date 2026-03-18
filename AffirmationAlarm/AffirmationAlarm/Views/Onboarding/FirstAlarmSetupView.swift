import SwiftUI

struct FirstAlarmSetupView: View {
    @Binding var alarmTime: Date
    @Binding var selectedDays: Set<Int>
    @Binding var selectedSound: String
    let onComplete: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer()
                    .frame(height: 20)

                VStack(spacing: 12) {
                    Image(systemName: "alarm.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.textSecondary)

                    Text("Set Your First Alarm")
                        .font(AppTheme.title2)
                        .foregroundColor(AppTheme.textPrimary)

                    Text("Choose when you'd like to start\nyour mornings with affirmations.")
                        .font(AppTheme.bodyFont)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                // Time picker
                DatePicker("Alarm Time", selection: $alarmTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .padding(.horizontal, 20)

                // Day selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Repeat")
                        .font(AppTheme.subheadline)
                        .foregroundColor(AppTheme.textSecondary)

                    DayOfWeekSelector(selectedDays: $selectedDays)
                }
                .padding(.horizontal)

                // Sound picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Alarm Sound")
                        .font(AppTheme.subheadline)
                        .foregroundColor(AppTheme.textSecondary)

                    AlarmSoundPicker(selectedSound: $selectedSound)
                }
                .padding(.horizontal)

                Button(action: onComplete) {
                    Text("Set Alarm & Start")
                        .font(AppTheme.headline)
                        .foregroundColor(AppTheme.accentText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(AppTheme.buttonBackground))
                }
                .padding(.horizontal, 40)

                Spacer()
                    .frame(height: 40)
            }
            .padding()
        }
    }
}

#Preview {
    ZStack {
        GradientBackground()
        FirstAlarmSetupView(
            alarmTime: .constant(Date()),
            selectedDays: .constant([2, 3, 4, 5, 6]),
            selectedSound: .constant("alarm_gentle"),
            onComplete: {}
        )
    }
}
