import SwiftUI

struct FirstAlarmSetupView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingXxl) {
                Spacer()
                    .frame(height: AppTheme.spacingXl)

                VStack(spacing: AppTheme.spacingLg) {
                    Image(systemName: "alarm.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.sunsetOrange)

                    Text("Set Your Alarm")
                        .font(AppTheme.title)
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("When do you want your affirmations?")
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                // Time picker
                DatePicker(
                    "Alarm time",
                    selection: Binding(
                        get: {
                            Calendar.current.date(
                                from: DateComponents(hour: viewModel.alarmHour, minute: viewModel.alarmMinute)
                            ) ?? Date()
                        },
                        set: { date in
                            viewModel.alarmHour = Calendar.current.component(.hour, from: date)
                            viewModel.alarmMinute = Calendar.current.component(.minute, from: date)
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 140)

                // Day selector
                VStack(spacing: AppTheme.spacingSm) {
                    Text("Repeat")
                        .font(AppTheme.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)

                    DayOfWeekSelector(selectedDays: $viewModel.alarmRepeatDays)
                }

                // Sound picker
                VStack(spacing: AppTheme.spacingSm) {
                    Text("Alarm Sound")
                        .font(AppTheme.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)

                    VStack(spacing: 0) {
                        ForEach(AppConstants.AlarmSound.allCases, id: \.self) { sound in
                            Button {
                                HapticService.selection()
                                viewModel.alarmSound = sound
                            } label: {
                                HStack {
                                    Text(sound.displayName)
                                        .font(AppTheme.bodyFont)
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Spacer()
                                    if viewModel.alarmSound == sound {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(AppTheme.gold)
                                    }
                                }
                                .padding(.horizontal, AppTheme.spacingLg)
                                .padding(.vertical, AppTheme.spacingMd)
                            }
                            .buttonStyle(.bounce)

                            if sound != AppConstants.AlarmSound.allCases.last {
                                Divider().background(AppTheme.strokeLight)
                            }
                        }
                    }
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                }

                Button("Start My Journey") {
                    HapticService.success()
                    onComplete()
                }
                .buttonStyle(PillButtonStyle(background: AppTheme.gold, foreground: AppTheme.charcoalBlue))

                Spacer()
                    .frame(height: AppTheme.spacing3xl)
            }
            .padding(.horizontal, AppTheme.spacingXxl)
        }
    }
}

// MARK: - Day of Week Selector

struct DayOfWeekSelector: View {
    @Binding var selectedDays: Set<Int>
    private let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        HStack(spacing: AppTheme.spacingSm) {
            ForEach(1...7, id: \.self) { day in
                let isSelected = selectedDays.contains(day)
                Button {
                    HapticService.selection()
                    if isSelected {
                        selectedDays.remove(day)
                    } else {
                        selectedDays.insert(day)
                    }
                } label: {
                    Text(dayLabels[day - 1])
                        .font(AppTheme.subheadline)
                        .foregroundStyle(isSelected ? AppTheme.charcoalBlue : AppTheme.textSecondary)
                        .frame(width: 40, height: 40)
                        .background(isSelected ? AppTheme.gold : AppTheme.cardBackground)
                        .clipShape(Circle())
                }
                .buttonStyle(.bounce)
            }
        }
    }
}
