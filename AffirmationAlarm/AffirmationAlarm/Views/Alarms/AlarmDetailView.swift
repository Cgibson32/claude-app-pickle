import SwiftUI
import SwiftData
import ActivityKit

struct AlarmDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    let alarm: Alarm?

    @State private var hour: Int
    @State private var minute: Int
    @State private var repeatDays: Set<Int>
    @State private var label: String
    @State private var isEnabled: Bool
    @State private var showDeleteConfirmation = false
    @State private var showLiveActivityAlert = false

    /// We only nudge the user about Live Activities ONCE — the first time
    /// they save an alarm with Live Activities disabled. After that
    /// (whether they enabled it or chose "Save Anyway") we don't pester
    /// them on every alarm. The persistent home-screen banner still
    /// reminds them if it's ever turned back off.
    @AppStorage("hasPromptedLiveActivities") private var hasPromptedLiveActivities = false

    init(alarm: Alarm?) {
        self.alarm = alarm
        _hour = State(initialValue: alarm?.hour ?? 6)
        _minute = State(initialValue: alarm?.minute ?? 30)
        _repeatDays = State(initialValue: Set(alarm?.repeatDays ?? []))
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

                        if alarm != nil {
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Text("Delete Alarm")
                                    .font(AppTheme.headline)
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(AppTheme.spacingLg)
                                    .background(Color.red.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                            }
                            .confirmationDialog(
                                "Delete this alarm?",
                                isPresented: $showDeleteConfirmation,
                                titleVisibility: .visible
                            ) {
                                Button("Delete", role: .destructive) {
                                    if let alarm {
                                        AlarmKitScheduler.shared.cancelAlarm(alarm)
                                        MorningAudioRenderer.shared.removeFiles(for: alarm)
                                        modelContext.delete(alarm)
                                    }
                                    dismiss()
                                }
                            }
                        }
                    }
                    .padding(AppTheme.spacingXl)
                }
            }
            .navigationTitle(alarm == nil ? "New Alarm" : "Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { attemptSave() }
                        .foregroundStyle(AppTheme.gold)
                        .fontWeight(.semibold)
                }
            }
            .alert("Turn On Live Activities", isPresented: $showLiveActivityAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                    save()
                }
                Button("Save Anyway", role: .cancel) { save() }
            } message: {
                Text("Your alarm needs Live Activities to show Stop and Snooze buttons on the lock screen. Without it, you'll have to open the app to stop the alarm.\n\nEnable it under Settings → Affirmation Alarm → Live Activities.")
            }
        }
    }

    /// Gate the save behind a Live Activities check. If they're off and
    /// the alarm will be enabled, prompt the user to turn them on first
    /// (the lock-screen Stop/Snooze depends on them). They can still
    /// save anyway.
    private func attemptSave() {
        if isEnabled,
           !hasPromptedLiveActivities,
           !ActivityAuthorizationInfo().areActivitiesEnabled {
            hasPromptedLiveActivities = true
            showLiveActivityAlert = true
        } else {
            save()
        }
    }

    private func save() {
        let targetAlarm: Alarm
        if let alarm {
            alarm.hour = hour
            alarm.minute = minute
            alarm.repeatDays = Array(repeatDays)
            alarm.label = label
            alarm.isEnabled = true
            targetAlarm = alarm
        } else {
            let newAlarm = Alarm(
                hour: hour,
                minute: minute,
                repeatDays: Array(repeatDays),
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
                    // Top up the pool if needed, then schedule the alarm
                    // (which assigns a fresh pool file to it).
                    await AffirmationPool.shared.refresh(profile: profile, modelContext: context)
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

}
