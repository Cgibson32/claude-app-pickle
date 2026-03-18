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
                        .foregroundColor(.white.opacity(0.9))

                    Text("Set Your First Alarm")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Choose when you'd like to start\nyour mornings with affirmations.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
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
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))

                    DayOfWeekSelector(selectedDays: $selectedDays)
                }
                .padding(.horizontal)

                // Sound picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Alarm Sound")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))

                    AlarmSoundPicker(selectedSound: $selectedSound)
                }
                .padding(.horizontal)

                Button(action: onComplete) {
                    Text("Set Alarm & Start")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(.white))
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
