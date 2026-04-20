import SwiftUI
import SwiftData

struct AlarmDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    let alarm: Alarm?

    @State private var hour: Int
    @State private var minute: Int
    @State private var repeatDays: Set<Int>
    @State private var soundName: AppConstants.AlarmSound
    @State private var label: String
    @State private var isEnabled: Bool
    @State private var previewingSound: AppConstants.AlarmSound?
    @State private var previewStopTask: Task<Void, Never>?

    init(alarm: Alarm?) {
        self.alarm = alarm
        _hour = State(initialValue: alarm?.hour ?? 6)
        _minute = State(initialValue: alarm?.minute ?? 30)
        _repeatDays = State(initialValue: Set(alarm?.repeatDays ?? []))
        _soundName = State(initialValue: AppConstants.AlarmSound(rawValue: alarm?.soundName ?? "alarm_gentle") ?? .gentle)
        _label = State(initialValue: alarm?.label ?? "Morning Affirmations")
        _isEnabled = State(initialValue: alarm?.isEnabled ?? true)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground(style: .sunrise, withBlobs: false)

                ScrollView {
                    VStack(spacing: AppTheme.spacingXxl) {
                        DatePicker(
                            "Time",
                            selection: Binding(
                                get: { Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date() },
                                set: { date in
                                    hour = Calendar.current.component(.hour, from: date)
                                    minute = Calendar.current.component(.minute, from: date)
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(height: 140)

                        VStack(spacing: AppTheme.spacingSm) {
                            Text("Repeat")
                                .font(AppTheme.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                            DayOfWeekSelector(selectedDays: $repeatDays)
                        }

                        TextField("Label", text: $label)
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(AppTheme.spacingLg)
                            .background(AppTheme.inputBackground)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                            .dismissKeyboardOnSubmit()

                        VStack(spacing: AppTheme.spacingSm) {
                            Text("Sound")
                                .font(AppTheme.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)

                            VStack(spacing: 0) {
                                ForEach(AppConstants.AlarmSound.allCases, id: \.self) { sound in
                                    HStack(spacing: AppTheme.spacingMd) {
                                        Button {
                                            HapticService.selection()
                                            soundName = sound
                                        } label: {
                                            HStack {
                                                Text(sound.displayName)
                                                    .font(AppTheme.bodyFont)
                                                    .foregroundStyle(AppTheme.textPrimary)
                                                Spacer()
                                                if soundName == sound {
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

                        if alarm != nil {
                            Button(role: .destructive) {
                                if let alarm {
                                    AlarmKitScheduler.shared.cancelAlarm(alarm)
                                    MorningAudioRenderer.shared.removeFiles(for: alarm)
                                    modelContext.delete(alarm)
                                }
                                dismiss()
                            } label: {
                                Text("Delete Alarm")
                                    .font(AppTheme.headline)
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(AppTheme.spacingLg)
                                    .background(Color.red.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                            }
                        }
                    }
                    .padding(AppTheme.spacingXl)
                }
            }
            .navigationTitle(alarm == nil ? "New Alarm" : "Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear { stopPreview() }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .foregroundStyle(AppTheme.gold)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        let targetAlarm: Alarm
        if let alarm {
            alarm.hour = hour
            alarm.minute = minute
            alarm.repeatDays = Array(repeatDays)
            alarm.soundName = soundName.rawValue
            alarm.label = label
            alarm.isEnabled = isEnabled
            targetAlarm = alarm
        } else {
            let newAlarm = Alarm(
                hour: hour,
                minute: minute,
                repeatDays: Array(repeatDays),
                soundName: soundName.rawValue,
                label: label
            )
            modelContext.insert(newAlarm)
            targetAlarm = newAlarm
        }
        try? modelContext.save()

        if targetAlarm.isEnabled {
            // Re-render the personalized morning audio for this alarm
            // before rescheduling, then schedule so AlarmKit picks up the
            // fresh file. Fire-and-forget Task — dismiss the sheet
            // immediately so the UI doesn't hang on the TTS call.
            if let profile = profiles.first {
                let context = modelContext
                Task { @MainActor in
                    _ = await MorningAudioRenderer.shared.refresh(
                        for: targetAlarm,
                        profile: profile,
                        modelContext: context
                    )
                    AlarmKitScheduler.shared.scheduleAlarm(targetAlarm)
                }
            } else {
                AlarmKitScheduler.shared.scheduleAlarm(targetAlarm)
            }
        } else {
            AlarmKitScheduler.shared.cancelAlarm(targetAlarm)
        }
        dismiss()
    }

    /// Play the chosen alarm sound through the real ringing audio path so
    /// users can hear it the same way it'll sound at 6 AM. Capped at 5s so
    /// a forgotten preview doesn't run forever.
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
