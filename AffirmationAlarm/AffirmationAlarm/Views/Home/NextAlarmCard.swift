import SwiftUI

struct NextAlarmCard: View {
    let alarms: [Alarm]

    private var nextAlarm: Alarm? {
        alarms.filter(\.isEnabled)
            .compactMap { alarm -> (Alarm, Date)? in
                guard let date = alarm.nextFireDate else { return nil }
                return (alarm, date)
            }
            .sorted { $0.1 < $1.1 }
            .first?.0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            HStack {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(AppTheme.sunsetOrange)
                Text("Next Alarm")
                    .font(AppTheme.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
            }

            if let alarm = nextAlarm {
                HStack(alignment: .firstTextBaseline) {
                    Text(alarm.timeString)
                        .font(AppTheme.title)
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    if let date = alarm.nextFireDate {
                        Text(AppDateFormatters.relativeAlarmTime(from: date))
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.gold)
                            .padding(.horizontal, AppTheme.spacingMd)
                            .padding(.vertical, 4)
                            .background(AppTheme.gold.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                Text(alarm.repeatDaysString)
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textTertiary)
            } else {
                Text("No alarm set")
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .padding(AppTheme.spacingXl)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
    }
}
