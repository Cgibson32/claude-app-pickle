import AVFoundation
import SwiftData
import SwiftUI
import UIKit

/// On-device diagnostics surface for debugging "why didn't affirmations
/// play this morning?" without needing Console.app on a Mac.
///
/// Shows: configuration (API keys, alarm count, background modes),
/// per-alarm rendered audio state (CAF + MP3s on disk, size, playable?),
/// keep-alive audio session state (running, category, last interruption,
/// last route change), observer state (last update received, last
/// alerting alarm, last handleFire outcome), and the recent event log.
///
/// Reached from Settings → Diagnostics. Refreshes on pull-to-refresh or
/// manual Refresh button.
struct DiagnosticsView: View {

    @Query private var alarms: [Alarm]
    @Query private var profiles: [UserProfile]

    @State private var keepAliveSnapshot: BackgroundKeepAlive.SessionSnapshot = .empty
    @State private var schedulerSnapshot: AlarmKitScheduler.DiagnosticsSnapshot = .empty
    @State private var playerSummary: AlarmAudioPlayer.PlaybackSummary?
    @State private var logEntries: [DiagnosticsLog.Entry] = []

    /// Recent events is the section users actually want when debugging
    /// an overnight failure, so it starts open. Everything else starts
    /// collapsed — expand on demand instead of scrolling past it.
    @State private var expandedSections: Set<String> = ["Recent events"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
                configurationSection
                poolSection
                keepAliveSection
                observerSection
                missedAlarmSection
                playbackSection
                perAlarmSection
                logSection
                resetOnboardingSection
            }
            .padding(AppTheme.spacingLg)
        }
        .background(GradientBackground(style: .sunrise, withBlobs: false))
        .navigationTitle("Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: AppTheme.spacingSm) {
                    Button {
                        toggleAllSections()
                    } label: {
                        Image(systemName: allExpanded ? "chevron.up.chevron.down" : "chevron.down.chevron.up")
                    }
                    .accessibilityLabel(allExpanded ? "Collapse all sections" : "Expand all sections")

                    Button {
                        refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh diagnostics")
                }
            }
        }
        .refreshable { refresh() }
        .task { refresh() }
    }

    // MARK: - Sections

    private var configurationSection: some View {
        card(title: "Configuration") {
            kvRow("OpenAI key", status(for: APIKeyConfiguration.openAIKey))
            kvRow("Claude key", status(for: APIKeyConfiguration.getAPIKey()))
            kvRow("Alarms (enabled / total)", "\(alarms.filter(\.isEnabled).count) / \(alarms.count)")
            kvRow("UIBackgroundModes", backgroundModesString)
            kvRow("Sounds directory", MorningAudioRenderer.soundsDirectory().path)
        }
    }

    private var poolSection: some View {
        let status = AffirmationPool.shared.status()
        return card(title: "Affirmation pool") {
            kvRow("fresh / used / total", "\(status.freshCount) / \(status.usedCount) / \(status.totalCount)")
            kvRow("target", "\(AffirmationPool.targetSize)")
            kvRow("refill threshold", "\(AffirmationPool.refillThreshold)")
            kvRow("needs refill", status.needsRefill ? "yes" : "no")
        }
    }

    private var keepAliveSection: some View {
        card(title: "Keep-alive") {
            kvRow("isRunning", keepAliveSnapshot.isRunning ? "yes" : "NO")
            kvRow("player exists / playing", "\(keepAliveSnapshot.playerExists ? "yes" : "no") / \(keepAliveSnapshot.playerIsPlaying ? "yes" : "no")")
            kvRow("session category", keepAliveSnapshot.sessionCategory)
            kvRow("session mode", keepAliveSnapshot.sessionMode)
            kvRow("session options (raw)", String(keepAliveSnapshot.sessionOptionsRaw))
            kvRow("other audio playing", keepAliveSnapshot.sessionIsOtherAudioPlaying ? "yes" : "no")
            if let inter = keepAliveSnapshot.lastInterruption {
                kvRow("last interruption", "\(formatted(inter.date)) — \(inter.detail)")
            } else {
                kvRow("last interruption", "none this session")
            }
            if let route = keepAliveSnapshot.lastRouteChange {
                kvRow("last route change", "\(formatted(route.date)) — \(route.detail)")
            } else {
                kvRow("last route change", "none this session")
            }
        }
    }

    private var observerSection: some View {
        card(title: "AlarmKit observer") {
            kvRow("permission denied", schedulerSnapshot.permissionDenied ? "YES" : "no")
            kvRow("sleep mode active", schedulerSnapshot.isSleepModeActive ? "yes" : "no")
            kvRow("playing morning audio", schedulerSnapshot.isPlayingMorningAudio ? "yes" : "no")
            if let ringing = schedulerSnapshot.ringingAlarmID {
                let labelSuffix = schedulerSnapshot.ringingAlarmLabel.isEmpty
                    ? ""
                    : " — \(schedulerSnapshot.ringingAlarmLabel)"
                kvRow("ringing alarm", "\(ringing.uuidString.prefix(8))\(labelSuffix)")
            } else {
                kvRow("ringing alarm", "none")
            }
            kvRow("active fire handling", String(schedulerSnapshot.activeFireHandlingCount))
            kvRow("pending follow-up renders", String(schedulerSnapshot.pendingFollowUpRenderCount))
            kvRow("tracked sound names", String(schedulerSnapshot.trackedSoundNameCount))
            if let last = schedulerSnapshot.lastUpdateReceived {
                kvRow("last update received", formatted(last))
            } else {
                kvRow("last update received", "NEVER — observer not firing")
            }
            if let alerting = schedulerSnapshot.lastAlertingAlarm {
                kvRow("last alerting", "\(formatted(alerting.date)) — \(alerting.alarmID.uuidString.prefix(8))")
            } else {
                kvRow("last alerting", "never this session")
            }
            if let fire = schedulerSnapshot.lastHandleFireOutcome {
                kvRow("last handleFire", "\(formatted(fire.date)) — \(fire.outcome)")
            } else {
                kvRow("last handleFire", "never this session")
            }
            kvRow("Stop intent opens app?", "yes (openAppWhenRun=true)")
        }
    }

    private var missedAlarmSection: some View {
        card(title: "Last successful fires") {
            let successes = MissedAlarmDetector.allLastSuccesses()
            if successes.isEmpty {
                Text("No alarms have recorded a successful fire yet.")
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                ForEach(Array(successes.keys.sorted { $0.uuidString < $1.uuidString }), id: \.self) { id in
                    if let date = successes[id] {
                        kvRow(String(id.uuidString.prefix(8)), formatted(date))
                    }
                }
            }
        }
    }

    private var playbackSection: some View {
        card(title: "AlarmAudioPlayer") {
            if let s = playerSummary {
                kvRow("last playback", formatted(s.date))
                kvRow("last outcome", s.outcome)
                kvRow("last alarm", s.alarmID.uuidString.prefix(8).description)
            } else {
                kvRow("last playback", "never this session")
            }
        }
    }

    @ViewBuilder
    private var perAlarmSection: some View {
        let enabled = alarms.filter(\.isEnabled)
        card(title: "Rendered audio") {
            if enabled.isEmpty {
                Text("No enabled alarms.")
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                ForEach(enabled, id: \.id) { alarm in
                    alarmBlock(alarm: alarm)
                    if alarm.id != enabled.last?.id {
                        Divider().background(AppTheme.textTertiary.opacity(0.3))
                    }
                }
            }
        }
    }

    private func alarmBlock(alarm: Alarm) -> some View {
        let shortID = alarm.id.uuidString.prefix(8)
        let dir = MorningAudioRenderer.soundsDirectory()
        let files: [(label: String, filename: String)] = [
            ("morning MP3", "morning-\(alarm.id.uuidString).mp3"),
            ("closing MP3", "closing-\(alarm.id.uuidString).mp3")
        ]

        return VStack(alignment: .leading, spacing: 4) {
            Text("\(alarm.timeString) — sound=\(alarm.soundName) — id=\(shortID)")
                .font(AppTheme.caption)
                .foregroundStyle(AppTheme.textPrimary)
            ForEach(files, id: \.label) { entry in
                let url = dir.appendingPathComponent(entry.filename)
                let info = fileInfo(at: url)
                kvRow(entry.label, info)
            }
            let stem = alarm.soundName
            let bundled = Bundle.main.url(forResource: stem, withExtension: "caf") != nil
            kvRow("bundle .caf (\(stem))", bundled ? "present" : "MISSING")
        }
    }

    private var logSection: some View {
        card(title: "Recent events") {
            if logEntries.isEmpty {
                Text("No events logged yet. Trigger an alarm to see activity.")
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(logEntries.reversed()) { entry in
                        logRow(entry: entry)
                    }
                }
                HStack {
                    Button("Copy all") {
                        UIPasteboard.general.string = DiagnosticsLog.shared.asText()
                    }
                    .font(AppTheme.caption)
                    Spacer()
                    Button("Clear") {
                        DiagnosticsLog.shared.clear()
                        refresh()
                    }
                    .font(AppTheme.caption)
                    .foregroundStyle(.red)
                }
                .padding(.top, AppTheme.spacingSm)
            }
        }
    }

    @State private var showResetConfirmation = false

    private var resetOnboardingSection: some View {
        Button(role: .destructive) {
            showResetConfirmation = true
        } label: {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                Text("Reset Onboarding")
            }
            .font(AppTheme.headline)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(AppTheme.spacingLg)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
        }
        .confirmationDialog("Reset onboarding?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
            Button("Reset", role: .destructive) {
                if let profile = profiles.first {
                    profile.hasCompletedOnboarding = false
                }
            }
        } message: {
            Text("The app will restart at the welcome screen. Your alarms and data are kept.")
        }
    }

    // MARK: - Row helpers

    private func kvRow(_ key: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(key)
                .font(AppTheme.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 140, alignment: .leading)
            Text(value)
                .font(AppTheme.caption.monospaced())
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
    }

    private func logRow(entry: DiagnosticsLog.Entry) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text(formatted(entry.timestamp))
                .font(.system(size: 10).monospaced())
                .foregroundStyle(AppTheme.textTertiary)
            Text("[\(entry.tag)]")
                .font(.system(size: 10).monospaced())
                .foregroundStyle(color(for: entry.tag))
            Text(entry.message)
                .font(.system(size: 10).monospaced())
                .foregroundStyle(AppTheme.textPrimary)
                .textSelection(.enabled)
        }
    }

    // MARK: - Shared card shell

    /// Collapsible diagnostic card. Each section keeps its own expansion
    /// state via `expandedSections` so a closed section stays closed
    /// after a refresh, and the user never sees the whole 7-section
    /// wall of text at once unless they ask for it.
    @ViewBuilder
    private func card<Content: View>(title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        let binding = Binding(
            get: { expandedSections.contains(title) },
            set: { isExpanded in
                if isExpanded {
                    expandedSections.insert(title)
                } else {
                    expandedSections.remove(title)
                }
            }
        )

        DisclosureGroup(isExpanded: binding) {
            VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                content()
            }
            .padding(.top, AppTheme.spacingSm)
        } label: {
            Text(title)
                .font(AppTheme.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .tint(AppTheme.textSecondary)
        .padding(AppTheme.spacingLg)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
    }

    // MARK: - Computed values

    private func status(for key: String?) -> String {
        guard let key, !key.isEmpty else { return "MISSING" }
        return "present (\(key.prefix(7))…\(key.count) chars)"
    }

    private var backgroundModesString: String {
        let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] ?? []
        return modes.isEmpty ? "(none)" : modes.joined(separator: ", ")
    }

    private func fileInfo(at url: URL) -> String {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else { return "MISSING" }
        var parts: [String] = []
        if let attrs = try? fm.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int {
            parts.append("\(size)B")
        }
        if let player = try? AVAudioPlayer(contentsOf: url) {
            parts.append(String(format: "%.1fs playable", player.duration))
        } else {
            parts.append("NOT playable")
        }
        return parts.joined(separator: ", ")
    }

    private func formatted(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        return fmt.string(from: date)
    }

    private func color(for tag: String) -> Color {
        switch tag {
        case "keep-alive": return .cyan
        case "observer": return .orange
        case "player": return .green
        case "intent": return .pink
        case "render": return .yellow
        case "scheduler": return .purple
        case "telemetry": return .mint
        default: return AppTheme.textSecondary
        }
    }

    // MARK: - Expand / collapse

    /// The titles every section is registered under. Duplicated here
    /// because `DisclosureGroup` has no registry we can introspect —
    /// keep in sync with the section builders above.
    private static let sectionTitles: Set<String> = [
        "Configuration",
        "Keep-alive",
        "AlarmKit observer",
        "Last successful fires",
        "AlarmAudioPlayer",
        "Rendered audio",
        "Recent events"
    ]

    private var allExpanded: Bool {
        expandedSections == Self.sectionTitles
    }

    private func toggleAllSections() {
        expandedSections = allExpanded ? [] : Self.sectionTitles
    }

    // MARK: - Refresh

    private func refresh() {
        keepAliveSnapshot = BackgroundKeepAlive.shared.sessionSnapshot()
        schedulerSnapshot = AlarmKitScheduler.shared.diagnosticsSnapshot()
        logEntries = DiagnosticsLog.shared.snapshot()
        Task { @MainActor in
            let summary = await AlarmAudioPlayer.shared.lastPlaybackSummary()
            self.playerSummary = summary
        }
    }
}
