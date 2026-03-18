import SwiftUI
import SwiftData

struct NextAlarmCard: View {
    let alarm: Alarm?

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "alarm.fill")
                    .foregroundColor(AppTheme.textSecondary)
                Text("Next Alarm")
                    .font(AppTheme.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                Spacer()
            }

            if let alarm, alarm.isEnabled, let nextFire = alarm.nextFireDate {
                VStack(spacing: 4) {
                    Text(alarm.timeString)
                        .font(.system(size: 48, weight: .light, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)

                    Text(DateFormatters.relativeAlarmTime(nextFire))
                        .font(AppTheme.subheadline)
                        .foregroundColor(AppTheme.textSecondary)

                    Text(alarm.repeatDaysString)
                        .font(AppTheme.caption)
                        .foregroundColor(AppTheme.textTertiary)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppTheme.textTertiary)
                    Text("No alarm set")
                        .font(AppTheme.bodyFont)
                        .foregroundColor(AppTheme.textTertiary)
                }
                .padding(.vertical, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackgroundHover)
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
