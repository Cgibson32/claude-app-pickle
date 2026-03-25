import SwiftUI
import SwiftData

struct AlarmListView: View {
    @Query(sort: \Alarm.hour) private var alarms: [Alarm]
    @Environment(\.modelContext) private var modelContext
    @State private var showingNewAlarm = false

    var body: some View {
        ZStack {
            GradientBackground(style: .sunrise, withBlobs: false)

            if alarms.isEmpty {
                VStack(spacing: AppTheme.spacingLg) {
                    Image(systemName: "alarm")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.textTertiary)
                    Text("No alarms yet")
                        .font(AppTheme.title3)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("Tap + to add your first alarm")
                        .font(AppTheme.bodyFont)
                        .foregroundStyle(AppTheme.textTertiary)
                    Button("Add Alarm") {
                        showingNewAlarm = true
                    }
                    .buttonStyle(PillButtonStyle())
                }
                .padding(AppTheme.spacingXxl)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppTheme.spacingMd) {
                        ForEach(alarms) { alarm in
                            AlarmRow(alarm: alarm)
                        }
                    }
                    .padding(AppTheme.spacingXl)
                }
            }
        }
        .navigationTitle("Alarms")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNewAlarm = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(AppTheme.gold)
                }
            }
        }
        .sheet(isPresented: $showingNewAlarm) {
            AlarmDetailView(alarm: nil)
        }
    }
}

struct AlarmRow: View {
    let alarm: Alarm
    @Environment(\.modelContext) private var modelContext
    @State private var showingEdit = false

    var body: some View {
        Button {
            showingEdit = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(alarm.timeString)
                        .font(AppTheme.title2)
                        .foregroundStyle(alarm.isEnabled ? AppTheme.textPrimary : AppTheme.textTertiary)
                    Text(alarm.repeatDaysString)
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                    if !alarm.label.isEmpty {
                        Text(alarm.label)
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { alarm.isEnabled },
                    set: { newValue in
                        alarm.isEnabled = newValue
                        AlarmSchedulingService.shared.scheduleAlarm(alarm)
                    }
                ))
                .tint(AppTheme.sunsetOrange)
                .labelsHidden()
            }
            .padding(AppTheme.spacingLg)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        }
        .buttonStyle(.bounce)
        .sheet(isPresented: $showingEdit) {
            AlarmDetailView(alarm: alarm)
        }
    }
}
