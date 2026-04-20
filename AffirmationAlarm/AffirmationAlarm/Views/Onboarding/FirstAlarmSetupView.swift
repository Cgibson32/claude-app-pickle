import SwiftUI

struct FirstAlarmSetupView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    @State private var previewingSound: AppConstants.AlarmSound?
    @State private var previewStopTask: Task<Void, Never>?

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
                            HStack(spacing: AppTheme.spacingMd) {
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
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                Button {
                                    togglePreview(sound)
                                } label: {
                                    Image(systemName: previewingSound == sound ? "stop.circle.fill" : "play.circle")
                                        .font(.title2)
                                        .foregroundStyle(previewingSound == sound ? AppTheme.gold : AppTheme.textSecondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, AppTheme.spacingLg)
                            .padding(.vertical, AppTheme.spacingMd)

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
        .onDisappear { stopPreview() }
    }

    /// Preview the alarm sound through the same audio path used at 6 AM,
    /// capped at 5s so a forgotten tap doesn't run forever. Mirrors
    /// `AlarmDetailView.togglePreview` — onboarding and alarm-edit share
    /// the identical real audio path.
    private func togglePreview(_ sound: AppConstants.AlarmSound) {
        HapticService.selection()
        if previewingSound == sound {
            stopPreview()
            return
        }
        stopPreview()
        previewingSound = sound
        previewStopTask = Task { @MainActor in
            await AlarmAudioPlayer.shared.startAlarmLoop(soundName: sound.rawValue)
            try? await Task.sleep(for: .seconds(5))
            if Task.isCancelled { return }
            await AlarmAudioPlayer.shared.stopAlarmLoop()
            if previewingSound == sound { previewingSound = nil }
        }
    }

    private func stopPreview() {
        previewStopTask?.cancel()
        previewStopTask = nil
        previewingSound = nil
        Task { @MainActor in await AlarmAudioPlayer.shared.stopAlarmLoop() }
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
