import SwiftUI
import SwiftData

struct AlarmListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Alarm.hour), SortDescriptor(\Alarm.minute)]) private var alarms: [Alarm]
    @State private var showingAddAlarm = false
    @State private var selectedAlarm: Alarm?

    var body: some View {
        List {
            ForEach(alarms) { alarm in
                AlarmRow(alarm: alarm)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedAlarm = alarm
                    }
                    .listRowBackground(Color.clear)
            }
            .onDelete(perform: deleteAlarms)
        }
        .scrollContentBackground(.hidden)
        .background(GradientBackground(style: .warmEvening))
        .navigationTitle("Alarms")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddAlarm = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
        }
        .sheet(isPresented: $showingAddAlarm) {
            AlarmDetailView()
        }
        .sheet(item: $selectedAlarm) { alarm in
            AlarmDetailView(alarm: alarm)
        }
    }

    private func deleteAlarms(at offsets: IndexSet) {
        for index in offsets {
            let alarm = alarms[index]
            AlarmSchedulingService.shared.removeNotifications(for: alarm)
            modelContext.delete(alarm)
        }
        try? modelContext.save()
    }
}

struct AlarmRow: View {
    @Bindable var alarm: Alarm

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.timeString)
                    .font(AppTheme.heading(36, weight: .light))
                    .foregroundColor(alarm.isEnabled ? AppTheme.textPrimary : AppTheme.textDisabled)

                Text(alarm.repeatDaysString)
                    .font(AppTheme.caption)
                    .foregroundColor(alarm.isEnabled ? AppTheme.textSecondary : AppTheme.textTertiary)

                if !alarm.label.isEmpty {
                    Text(alarm.label)
                        .font(AppTheme.caption2)
                        .foregroundColor(AppTheme.textTertiary)
                }
            }

            Spacer()

            Toggle("", isOn: $alarm.isEnabled)
                .labelsHidden()
                .tint(AppTheme.accent)
                .onChange(of: alarm.isEnabled) { _, newValue in
                    if newValue {
                        AlarmSchedulingService.shared.scheduleAlarm(alarm)
                    } else {
                        AlarmSchedulingService.shared.removeNotifications(for: alarm)
                    }
                }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        AlarmListView()
    }
    .modelContainer(for: [Alarm.self], inMemory: true)
}
