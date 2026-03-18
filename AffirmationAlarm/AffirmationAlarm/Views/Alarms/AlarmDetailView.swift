import SwiftUI
import SwiftData

struct AlarmDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let alarm: Alarm?
    var isNew: Bool { alarm == nil }

    @State private var alarmTime: Date
    @State private var selectedDays: Set<Int>
    @State private var selectedSound: String
    @State private var label: String
    @State private var isEnabled: Bool
    @State private var showDeleteConfirmation = false

    init(alarm: Alarm? = nil) {
        self.alarm = alarm
        let calendar = Calendar.current
        if let alarm {
            var components = DateComponents()
            components.hour = alarm.hour
            components.minute = alarm.minute
            _alarmTime = State(initialValue: calendar.date(from: components) ?? Date())
            _selectedDays = State(initialValue: Set(alarm.repeatDays))
            _selectedSound = State(initialValue: alarm.soundName)
            _label = State(initialValue: alarm.label)
            _isEnabled = State(initialValue: alarm.isEnabled)
        } else {
            _alarmTime = State(initialValue: calendar.date(from: DateComponents(hour: 6, minute: 30)) ?? Date())
            _selectedDays = State(initialValue: [2, 3, 4, 5, 6])
            _selectedSound = State(initialValue: "alarm_gentle")
            _label = State(initialValue: "Morning Alarm")
            _isEnabled = State(initialValue: true)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground(style: .warmEvening)

                ScrollView {
                    VStack(spacing: 24) {
                        // Time picker
                        DatePicker("Time", selection: $alarmTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .colorScheme(.dark)

                        // Label
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Label")
                                .font(AppTheme.subheadline)
                                .foregroundColor(AppTheme.textSecondary)

                            TextField("Alarm label", text: $label)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppTheme.chipUnselected)
                                )
                                .foregroundColor(AppTheme.textPrimary)
                                .tint(AppTheme.textPrimary)
                        }

                        // Days
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Repeat")
                                .font(AppTheme.subheadline)
                                .foregroundColor(AppTheme.textSecondary)

                            DayOfWeekSelector(selectedDays: $selectedDays)
                        }

                        // Sound
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sound")
                                .font(AppTheme.subheadline)
                                .foregroundColor(AppTheme.textSecondary)

                            AlarmSoundPicker(selectedSound: $selectedSound)
                        }

                        // Enable/Disable
                        Toggle(isOn: $isEnabled) {
                            Text("Enabled")
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        .tint(AppTheme.accent)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.cardBackground)
                        )

                        // Delete button (for existing alarms)
                        if !isNew {
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Text("Delete Alarm")
                                    .font(AppTheme.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .tint(AppTheme.destructive)
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(isNew ? "New Alarm" : "Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.textPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(AppTheme.subheadline)
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
            .alert("Delete Alarm?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) { deleteAlarm() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func save() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: alarmTime)
        let minute = calendar.component(.minute, from: alarmTime)

        if let alarm {
            alarm.hour = hour
            alarm.minute = minute
            alarm.repeatDays = Array(selectedDays)
            alarm.soundName = selectedSound
            alarm.label = label
            alarm.isEnabled = isEnabled
            AlarmSchedulingService.shared.scheduleAlarm(alarm)
        } else {
            let newAlarm = Alarm(
                hour: hour,
                minute: minute,
                repeatDays: Array(selectedDays),
                isEnabled: isEnabled,
                soundName: selectedSound,
                label: label
            )
            modelContext.insert(newAlarm)
            AlarmSchedulingService.shared.scheduleAlarm(newAlarm)
        }

        try? modelContext.save()
        dismiss()
    }

    private func deleteAlarm() {
        if let alarm {
            AlarmSchedulingService.shared.removeNotifications(for: alarm)
            modelContext.delete(alarm)
            try? modelContext.save()
        }
        dismiss()
    }
}

#Preview {
    AlarmDetailView()
        .modelContainer(for: [Alarm.self], inMemory: true)
}
