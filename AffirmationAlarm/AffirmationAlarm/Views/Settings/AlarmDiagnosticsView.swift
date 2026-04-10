import ActivityKit
@preconcurrency import AlarmKit
import AppIntents
import AVFoundation
import SwiftUI
import UIKit
import UserNotifications

/// Diagnostic screen for isolating sound playback paths on iOS 26.1.
struct AlarmDiagnosticsView: View {
    @State private var log = DiagnosticLog.shared
    @State private var copiedBanner = false

    var body: some View {
        ZStack {
            GradientBackground(style: .sunrise, withBlobs: false)

            ScrollView {
                VStack(spacing: AppTheme.spacingLg) {
                    // Header
                    VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                        Text("Alarm Sound Diagnostics")
                            .font(AppTheme.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Each button fires a test in 10 seconds. Note which ones play audio, then tap \"Copy Log\" and share the result.")
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppTheme.spacingLg)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))

                    // Test buttons
                    testButton(
                        label: "Test 1: Default Sound",
                        icon: "speaker.wave.3.fill",
                        color: .green
                    ) { await runTest1_default() }

                    testButton(
                        label: "Test 2: Bundled CAF",
                        icon: "doc.fill",
                        color: .blue
                    ) { await runTest2_bundled() }

                    testButton(
                        label: "Test 3: Library/Sounds CAF",
                        icon: "folder.fill",
                        color: .orange
                    ) { await runTest3_librarySounds() }

                    testButton(
                        label: "Test 4: Notification Sound",
                        icon: "bell.badge.fill",
                        color: .purple
                    ) { await runTest4_notificationSound() }

                    testButton(
                        label: "Test 5: AVAudioPlayer",
                        icon: "play.circle.fill",
                        color: .red
                    ) { await runTest5_avAudioPlayer() }

                    // Log output
                    VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                        HStack {
                            Text("Log")
                                .font(AppTheme.headline)
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            Button("Clear") { log.clear() }
                                .font(AppTheme.caption)
                            Button(copiedBanner ? "Copied!" : "Copy Log") {
                                UIPasteboard.general.string = log.text
                                copiedBanner = true
                                Task {
                                    try? await Task.sleep(for: .seconds(2))
                                    copiedBanner = false
                                }
                            }
                            .font(AppTheme.caption)
                        }

                        if log.entries.isEmpty {
                            Text("No log entries yet. Tap a test button above.")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textTertiary)
                                .padding(.vertical, AppTheme.spacingMd)
                        } else {
                            Text(log.text)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(AppTheme.textSecondary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(AppTheme.spacingLg)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
                }
                .padding(AppTheme.spacingXl)
            }
        }
        .navigationTitle("Alarm Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Test button component

    @ViewBuilder
    private func testButton(
        label: String,
        icon: String,
        color: Color,
        action: @escaping () async -> Void
    ) -> some View {
        Button {
            Task { await action() }
        } label: {
            HStack(spacing: AppTheme.spacingMd) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text(label)
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                Text("10s")
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textTertiary)
            }
            .padding(AppTheme.spacingLg)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Test 1: AlarmKit .default

    private func runTest1_default() async {
        log.log("--- TEST 1: Default Sound ---")

        let authOK = await AlarmKitScheduler.shared.requestPermission()
        log.log("  Authorization: \(authOK ? "granted" : "DENIED")")
        guard authOK else { return }

        let id = UUID()
        let fireDate = Date().addingTimeInterval(10)
        log.log("  Alarm ID: \(id.uuidString.prefix(8))")

        do {
            let config = makeTestConfig(
                title: "Diag: Default",
                schedule: .fixed(fireDate),
                sound: .default
            )
            _ = try await AlarmManager.shared.schedule(id: id, configuration: config)
            log.log("  Scheduled with sound: .default ✓")
        } catch {
            log.log("  SCHEDULE FAILED: \(error.localizedDescription)")
        }
    }

    // MARK: - Test 2: AlarmKit .named (bundled)

    private func runTest2_bundled() async {
        log.log("--- TEST 2: Bundled CAF ---")

        let authOK = await AlarmKitScheduler.shared.requestPermission()
        log.log("  Authorization: \(authOK ? "granted" : "DENIED")")
        guard authOK else { return }

        let bundledURL = Bundle.main.url(forResource: "alarm_gentle", withExtension: "caf")
        if let url = bundledURL {
            let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
            log.log("  alarm_gentle.caf in bundle: YES (\(size) bytes)")
        } else {
            log.log("  alarm_gentle.caf in bundle: NO — MISSING")
        }

        let id = UUID()
        do {
            let config = makeTestConfig(
                title: "Diag: Bundled",
                schedule: .fixed(Date().addingTimeInterval(10)),
                sound: .named("alarm_gentle.caf")
            )
            _ = try await AlarmManager.shared.schedule(id: id, configuration: config)
            log.log("  Scheduled with sound: .named(\"alarm_gentle.caf\") ✓")
        } catch {
            log.log("  SCHEDULE FAILED: \(error.localizedDescription)")
        }
    }

    // MARK: - Test 3: AlarmKit .named (Library/Sounds)

    private func runTest3_librarySounds() async {
        log.log("--- TEST 3: Library/Sounds CAF ---")

        let authOK = await AlarmKitScheduler.shared.requestPermission()
        log.log("  Authorization: \(authOK ? "granted" : "DENIED")")
        guard authOK else { return }

        let soundsDir = MorningAudioRenderer.soundsDirectory()
        let destURL = soundsDir.appendingPathComponent("diagnostic_test.caf")

        do {
            try FileManager.default.createDirectory(at: soundsDir, withIntermediateDirectories: true)
        } catch {
            log.log("  Library/Sounds/ dir FAILED: \(error.localizedDescription)")
            return
        }

        guard let sourceURL = Bundle.main.url(forResource: "alarm_gentle", withExtension: "caf") else {
            log.log("  Source missing from bundle")
            return
        }

        do {
            try? FileManager.default.removeItem(at: destURL)
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
            let size = (try? FileManager.default.attributesOfItem(atPath: destURL.path)[.size] as? Int) ?? 0
            log.log("  Copied to Library/Sounds/diagnostic_test.caf (\(size) bytes)")
        } catch {
            log.log("  COPY FAILED: \(error.localizedDescription)")
            return
        }

        let id = UUID()
        do {
            let config = makeTestConfig(
                title: "Diag: Lib/Sounds",
                schedule: .fixed(Date().addingTimeInterval(10)),
                sound: .named("diagnostic_test.caf")
            )
            _ = try await AlarmManager.shared.schedule(id: id, configuration: config)
            log.log("  Scheduled with sound: .named(\"diagnostic_test.caf\") ✓")
        } catch {
            log.log("  SCHEDULE FAILED: \(error.localizedDescription)")
        }
    }

    // MARK: - Test 4: UNUserNotification with custom sound

    /// Tests whether UNNotificationSound(named:) works on this device.
    /// This is a DIFFERENT API from AlarmKit's .named() — it might work
    /// even though AlarmKit's version is broken on iOS 26.1.
    /// If this plays audio, we can use a local notification alongside
    /// the AlarmKit alarm to deliver the affirmation audio automatically.
    private func runTest4_notificationSound() async {
        log.log("--- TEST 4: Notification Sound ---")

        // Request notification permission
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            log.log("  Notification auth: \(granted ? "granted" : "DENIED")")
            guard granted else { return }
        } catch {
            log.log("  Notification auth FAILED: \(error.localizedDescription)")
            return
        }

        // Copy bundled alarm_gentle.caf to Library/Sounds/ (where
        // UNNotificationSound looks for named files)
        let soundsDir = MorningAudioRenderer.soundsDirectory()
        let destURL = soundsDir.appendingPathComponent("notif_test.caf")

        do {
            try FileManager.default.createDirectory(at: soundsDir, withIntermediateDirectories: true)
        } catch {
            log.log("  Library/Sounds/ dir FAILED: \(error.localizedDescription)")
            return
        }

        guard let sourceURL = Bundle.main.url(forResource: "alarm_gentle", withExtension: "caf") else {
            log.log("  Source missing from bundle")
            return
        }

        do {
            try? FileManager.default.removeItem(at: destURL)
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
            let size = (try? FileManager.default.attributesOfItem(atPath: destURL.path)[.size] as? Int) ?? 0
            log.log("  Copied notif_test.caf (\(size) bytes)")
        } catch {
            log.log("  COPY FAILED: \(error.localizedDescription)")
            return
        }

        // Schedule notification in 10 seconds with custom sound
        let content = UNMutableNotificationContent()
        content.title = "Diag: Notification Sound"
        content.body = "This notification should play alarm_gentle.caf audio."
        content.sound = UNNotificationSound(named: UNNotificationSoundName("notif_test.caf"))

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(
            identifier: "diag-notif-sound-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            log.log("  Notification scheduled, fires in 10s ✓")
            log.log("  sound = UNNotificationSound(named: \"notif_test.caf\")")
            log.log("  IMPORTANT: Lock your phone or leave this app to hear it")
            log.log("  (notifications don't play sound while the app is in foreground by default)")
        } catch {
            log.log("  NOTIFICATION SCHEDULE FAILED: \(error.localizedDescription)")
        }
    }

    // MARK: - Test 5: Direct AVAudioPlayer playback

    /// Tests whether AVAudioPlayer can play audio from the app process
    /// right now, independent of AlarmKit. This confirms the audio file
    /// is valid and the audio session works.
    private func runTest5_avAudioPlayer() async {
        log.log("--- TEST 5: AVAudioPlayer ---")

        guard let sourceURL = Bundle.main.url(forResource: "alarm_gentle", withExtension: "caf") else {
            log.log("  alarm_gentle.caf missing from bundle")
            return
        }

        let size = (try? FileManager.default.attributesOfItem(atPath: sourceURL.path)[.size] as? Int) ?? 0
        log.log("  File: alarm_gentle.caf (\(size) bytes)")

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true, options: [])
            try session.overrideOutputAudioPort(.speaker)
            log.log("  Audio session: active, routed to speaker")
            log.log("  Output volume: \(session.outputVolume)")
        } catch {
            log.log("  Audio session FAILED: \(error.localizedDescription)")
            return
        }

        let player: AVAudioPlayer
        do {
            player = try AVAudioPlayer(contentsOf: sourceURL)
            log.log("  Player created, duration=\(String(format: "%.1f", player.duration))s")
        } catch {
            log.log("  AVAudioPlayer init FAILED: \(error.localizedDescription)")
            return
        }

        player.volume = 1.0
        player.prepareToPlay()
        let started = player.play()
        log.log("  play() returned \(started)")

        if started {
            log.log("  Playing now (should hear audio immediately)...")
            try? await Task.sleep(for: .seconds(player.duration + 0.3))
            withExtendedLifetime(player) {}
            log.log("  Playback complete")
        } else {
            log.log("  play() returned false — NO AUDIO")
        }

        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    // MARK: - Helpers

    private func makeTestConfig(
        title: String,
        schedule: AlarmKit.Alarm.Schedule,
        sound: AlertConfiguration.AlertSound
    ) -> AlarmManager.AlarmConfiguration<AffirmationAlarmMetadata> {
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: title)
        )
        let presentation = AlarmPresentation(alert: alert)
        let attributes = AlarmAttributes(
            presentation: presentation,
            metadata: AffirmationAlarmMetadata(alarmID: UUID(), label: title),
            tintColor: Color.orange
        )

        return .alarm(
            schedule: schedule,
            attributes: attributes,
            stopIntent: nil,
            secondaryIntent: nil,
            sound: sound
        )
    }
}
