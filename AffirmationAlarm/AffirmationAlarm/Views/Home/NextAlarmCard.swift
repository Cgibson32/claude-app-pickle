import SwiftUI
import SwiftData

struct NextAlarmCard: View {
    let alarm: Alarm?

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "alarm.fill")
                    .foregroundColor(.white.opacity(0.7))
                Text("Next Alarm")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
            }

            if let alarm, alarm.isEnabled, let nextFire = alarm.nextFireDate {
                VStack(spacing: 4) {
                    Text(alarm.timeString)
                        .font(.system(size: 48, weight: .light, design: .rounded))
                        .foregroundColor(.white)

                    Text(DateFormatters.relativeAlarmTime(nextFire))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))

                    Text(alarm.repeatDaysString)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.title)
                        .foregroundColor(.white.opacity(0.4))
                    Text("No alarm set")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.vertical, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.15))
        )
    }
}

#Preview {
    ZStack {
        GradientBackground()
        NextAlarmCard(alarm: nil)
            .padding()
    }
}
