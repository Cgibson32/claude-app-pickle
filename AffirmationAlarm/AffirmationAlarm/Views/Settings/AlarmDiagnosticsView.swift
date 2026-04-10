import ActivityKit
@preconcurrency import AlarmKit
import AppIntents
import SwiftUI
import UIKit

/// Temporary diagnostic screen for isolating why AlarmKit plays no audio.
/// Three test buttons each schedule a 10-second alarm with a DIFFERENT
/// sound source so we can pin down which playback path is broken on the
/// user's specific iOS version / device.
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
                        Text("Each button schedules a real alarm that fires in 10 seconds. Test each one and note which play audio. Then tap \"Copy Log\" and share the result.")
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

    // MARK: - Test implementations

    /// Test 1: `.default` sound. If this plays audio, AlarmKit can produce
    /// sound on this device and the issue is specifically with `.named(_:)`.
    private func runTest1_default() async {
        log.log("--- TEST 1: Default Sound ---")

        let authOK = await AlarmKitScheduler.shared.requestPermission()
        log.log("  Authorization: \(authOK ? "granted" : "DENIED")")
        guard authOK else { return }

        let id = UUID()
        let fireDate = Date().addingTimeInterval(10)
        log.log("  Alarm ID: \(id.uuidString.prefix(8))")
        log.log("  Fire date: \(fireDate)")

        do {
            let config = makeTestConfig(
                title: "Diag: Default",
                schedule: .fixed(fireDate),
                sound: .default
            )
            _ = try await AlarmManager.shared.schedule(id: id, configuration: config)
            log.log("  Scheduled with sound: .default ✓")
            log.log("  Alarm should fire in ~10 seconds")
        } catch {
            log.log("  SCHEDULE FAILED: \(error.localizedDescription)")
        }
    }

    /// Test 2: `.named("alarm_gentle.caf")` — a bundled file in the main
    /// bundle. If this plays but Test 3 doesn't, Library/Sounds is broken.
    private func runTest2_bundled() async {
        log.log("--- TEST 2: Bundled CAF ---")

        let authOK = await AlarmKitScheduler.shared.requestPermission()
        log.log("  Authorization: \(authOK ? "granted" : "DENIED")")
        guard authOK else { return }

        // Verify the bundled file exists
        let bundledURL = Bundle.main.url(forResource: "alarm_gentle", withExtension: "caf")
        if let url = bundledURL {
            let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
            log.log("  alarm_gentle.caf in bundle: YES (\(size) bytes)")
        } else {
            log.log("  alarm_gentle.caf in bundle: NO — FILE MISSING")
        }

        let id = UUID()
        let fireDate = Date().addingTimeInterval(10)
        log.log("  Alarm ID: \(id.uuidString.prefix(8))")

        do {
            let config = makeTestConfig(
                title: "Diag: Bundled",
                schedule: .fixed(fireDate),
                sound: .named("alarm_gentle.caf")
            )
            _ = try await AlarmManager.shared.schedule(id: id, configuration: config)
            log.log("  Scheduled with sound: .named(\"alarm_gentle.caf\") ✓")
            log.log("  Alarm should fire in ~10 seconds")
        } catch {
            log.log("  SCHEDULE FAILED: \(error.localizedDescription)")
        }
    }

    /// Test 3: Copy a known-good CAF into Library/Sounds/ at runtime, then
    /// schedule with that path. If this is silent but Test 2 plays, the
    /// Library/Sounds lookup is broken on this iOS version (FB19779004).
    private func runTest3_librarySounds() async {
        log.log("--- TEST 3: Library/Sounds CAF ---")

        let authOK = await AlarmKitScheduler.shared.requestPermission()
        log.log("  Authorization: \(authOK ? "granted" : "DENIED")")
        guard authOK else { return }

        // Copy alarm_gentle.caf from bundle → Library/Sounds/
        let soundsDir = MorningAudioRenderer.soundsDirectory()
        let destURL = soundsDir.appendingPathComponent("diagnostic_test.caf")

        do {
            try FileManager.default.createDirectory(at: soundsDir, withIntermediateDirectories: true)
            log.log("  Library/Sounds/ directory: OK")
        } catch {
            log.log("  Library/Sounds/ directory FAILED: \(error.localizedDescription)")
            return
        }

        guard let sourceURL = Bundle.main.url(forResource: "alarm_gentle", withExtension: "caf") else {
            log.log("  Source file missing from bundle")
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
        let fireDate = Date().addingTimeInterval(10)
        log.log("  Alarm ID: \(id.uuidString.prefix(8))")

        do {
            let config = makeTestConfig(
                title: "Diag: Lib/Sounds",
                schedule: .fixed(fireDate),
                sound: .named("diagnostic_test.caf")
            )
            _ = try await AlarmManager.shared.schedule(id: id, configuration: config)
            log.log("  Scheduled with sound: .named(\"diagnostic_test.caf\") ✓")
            log.log("  Alarm should fire in ~10 seconds")
        } catch {
            log.log("  SCHEDULE FAILED: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    /// Minimal AlarmKit configuration for a diagnostic test alarm.
    /// No stop/snooze intents — just a simple alarm with a title and sound.
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
