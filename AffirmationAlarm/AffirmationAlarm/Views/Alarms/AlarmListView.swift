import SwiftUI
import SwiftData
import UIKit

struct AlarmListView: View {
    @Query(sort: \Alarm.hour) private var alarms: [Alarm]
    @Environment(\.modelContext) private var modelContext
    @State private var showingNewAlarm = false
    @State private var scheduler = AlarmKitScheduler.shared

    var body: some View {
        ZStack {
            GradientBackground(style: .sunrise, withBlobs: false)

            VStack(spacing: 0) {
                if scheduler.permissionDenied {
                    permissionBanner
                        .padding(AppTheme.spacingLg)
                }

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
                    .frame(maxHeight: .infinity)
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
                .accessibilityLabel("Add alarm")
            }
        }
        .sheet(isPresented: $showingNewAlarm) {
            AlarmDetailView(alarm: nil)
        }
        .task {
            // Refresh AlarmKit permission status. We do NOT proactively
            // prompt here — the prompt fires on first schedule attempt.
            await scheduler.refreshPermissionStatus()
        }
    }

    private var permissionBanner: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            HStack(spacing: AppTheme.spacingSm) {
                Image(systemName: "bell.slash.fill")
                    .foregroundStyle(.orange)
                Text("Alarms are off")
                    .font(AppTheme.headline)
                    .foregroundStyle(AppTheme.textPrimary)
            }
            Text("Your alarms can't ring until you enable alarm permissions for Affirmation Alarm in Settings.")
                .font(AppTheme.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(AppTheme.headline)
            .foregroundStyle(AppTheme.gold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.spacingLg)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
    }
}

struct AlarmRow: View {
    let alarm: Alarm
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var showingEdit = false
    @State private var showDeleteConfirmation = false

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
                    if alarm.isEnabled, let next = alarm.nextFireDate {
                        Text("Next: \(Self.formatNext(next))")
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.gold)
                    }
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { alarm.isEnabled },
                    set: { newValue in
                        alarm.isEnabled = newValue
                        try? modelContext.save()
                        if newValue {
                            // Re-render the personalized audio before
                            // scheduling so flipping an alarm off then on
                            // doesn't leave the user with stale or missing
                            // voice files. Fire-and-forget Task; the
                            // scheduler falls back to the bundled tone
                            // while the render is in flight.
                            if let profile = profiles.first {
                                let context = modelContext
                                Task { @MainActor in
                                    _ = await MorningAudioRenderer.shared.refresh(
                                        for: alarm,
                                        profile: profile,
                                        modelContext: context
                                    )
                                    AlarmKitScheduler.shared.scheduleAlarm(alarm)
                                }
                            } else {
                                AlarmKitScheduler.shared.scheduleAlarm(alarm)
                            }
                        } else {
                            AlarmKitScheduler.shared.cancelAlarm(alarm)
                        }
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
        .contextMenu {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog("Delete this alarm?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                AlarmKitScheduler.shared.cancelAlarm(alarm)
                MorningAudioRenderer.shared.removeFiles(for: alarm)
                modelContext.delete(alarm)
            }
        }
        .sheet(isPresented: $showingEdit) {
            AlarmDetailView(alarm: alarm)
        }
    }

    private static func formatNext(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "'Today' h:mm a"
        } else if Calendar.current.isDateInTomorrow(date) {
            formatter.dateFormat = "'Tomorrow' h:mm a"
        } else {
            formatter.dateFormat = "EEE h:mm a"
        }
        return formatter.string(from: date)
    }
}
