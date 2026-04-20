import SwiftUI

struct NextAlarmCard: View {
    let alarms: [Alarm]
    /// When `true`, the card replaces its relative-time badge with a small
    /// spinner + "Preparing…" label so the first-morning render window
    /// (~5–10s after onboarding completes) doesn't need a separate
    /// full-width banner cluttering the home screen.
    var isPreparing: Bool = false

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

                    if isPreparing {
                        preparingBadge
                    } else if let date = alarm.nextFireDate {
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
        .animation(AppTheme.gentle, value: isPreparing)
    }

    private var preparingBadge: some View {
        HStack(spacing: 6) {
            ProgressView()
                .controlSize(.mini)
                .tint(AppTheme.gold)
            Text("Preparing…")
                .font(AppTheme.caption)
                .foregroundStyle(AppTheme.gold)
        }
        .padding(.horizontal, AppTheme.spacingMd)
        .padding(.vertical, 4)
        .background(AppTheme.gold.opacity(0.15))
        .clipShape(Capsule())
        .accessibilityLabel("Preparing your first morning ritual")
    }
}
