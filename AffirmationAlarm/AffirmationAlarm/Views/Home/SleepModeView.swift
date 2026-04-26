import SwiftUI
import SwiftData

/// Full-screen bedside clock that keeps the app in the foreground so the
/// `AlarmManager.alarmUpdates` observer in `AlarmKitScheduler` stays alive.
///
/// **Why this is necessary (iOS 26.1):**
/// AlarmKit's `.named()` sound is broken (FB19779004) — only `.default`
/// plays. The `alarmUpdates` async sequence only emits while the app
/// process is active. Silent background audio (`BackgroundKeepAlive`)
/// doesn't reliably keep the process alive when the screen is off.
///
/// By keeping the app in the foreground with `isIdleTimerDisabled = true`,
/// the observer catches `.alerting`, immediately cancels the system alarm
/// (stopping `.default`), and plays the pre-rendered morning affirmation
/// audio via `AlarmAudioPlayer`. The user hears:
///
///     brief .default ring (~0.5s) → "Good morning, [Name]..." → affirmations → closing → silence
///
/// **Battery:** Pure black background on OLED = minimal pixel power. The
/// user's phone is charging on the nightstand overnight anyway.
struct SleepModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Alarm.hour) private var alarms: [Alarm]
    @State private var scheduler = AlarmKitScheduler.shared
    @State private var currentTime = Date()
    @State private var showExitConfirmation = false
    @AppStorage("hasSeenSleepModeTip") private var hasSeenTip = false
    @State private var showBrightnessTip = false

    /// Saved brightness level, restored on exit.
    @State private var previousBrightness: CGFloat = 0.5

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var nextAlarm: Alarm? {
        alarms.filter(\.isEnabled)
            .compactMap { alarm -> (Alarm, Date)? in
                guard let date = alarm.nextFireDate else { return nil }
                return (alarm, date)
            }
            .sorted { $0.1 < $1.1 }
            .first?.0
    }

    var body: some View {
        ZStack {
            // Pure black for OLED power savings.
            Color.black.ignoresSafeArea()

            // Ringing is handled by RootView's fullScreenCover showing
            // `AlarmRingingView` on top of us. We only render the clock
            // and playing states here.
            VStack(spacing: 0) {
                Spacer()

                if scheduler.isPlayingMorningAudio {
                    playingState
                } else {
                    clockState
                }

                Spacer()

                exitButton
                    .padding(.bottom, AppTheme.spacing3xl)
            }
        }
        .overlay {
            if showBrightnessTip {
                VStack(spacing: AppTheme.spacingSm) {
                    Image(systemName: "sun.min.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppTheme.gold.opacity(0.6))
                    Text("Your screen has been dimmed.\nTap Exit to restore brightness.")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.warmWhite.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .padding(AppTheme.spacingXl)
                .background(.ultraThinMaterial.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
                .transition(.opacity)
            }
        }
        .persistentSystemOverlays(.hidden)
        .statusBarHidden()
        .preferredColorScheme(.dark)
        .onAppear {
            previousBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 0.05
            UIApplication.shared.isIdleTimerDisabled = true
            scheduler.isSleepModeActive = true

            if !hasSeenTip {
                showBrightnessTip = true
                hasSeenTip = true
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(4))
                    withAnimation(.easeOut(duration: 0.3)) {
                        showBrightnessTip = false
                    }
                }
            }
        }
        .onDisappear {
            UIScreen.main.brightness = previousBrightness
            UIApplication.shared.isIdleTimerDisabled = false
            scheduler.isSleepModeActive = false
        }
        .onChange(of: scheduler.ringingAlarmID) { oldValue, newValue in
            if oldValue == nil, newValue != nil {
                rampBrightness(to: 1.0, duration: 3.0)
            } else if oldValue != nil, newValue == nil, !scheduler.isPlayingMorningAudio {
                UIScreen.main.brightness = 0.05
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .confirmationDialog(
            "Leave Sleep Mode?",
            isPresented: $showExitConfirmation,
            titleVisibility: .visible
        ) {
            Button("Leave", role: .destructive) { dismiss() }
            Button("Stay", role: .cancel) {}
        } message: {
            Text("Your alarm needs Sleep Mode to play your personalized affirmations when it rings.")
        }
    }

    // MARK: - Clock state (waiting for alarm)

    private var clockState: some View {
        VStack(spacing: AppTheme.spacingXl) {
            // Moon icon
            Image(systemName: "moon.fill")
                .font(.system(size: 32))
                .foregroundStyle(AppTheme.gold.opacity(0.4))
                .padding(.bottom, AppTheme.spacingMd)

            // Current time — large
            Text(timeString(from: currentTime))
                .font(.system(size: 72, weight: .thin, design: .rounded))
                .foregroundStyle(AppTheme.warmWhite.opacity(0.7))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.linear(duration: 0.3), value: currentTime)

            // Next alarm
            if let alarm = nextAlarm {
                HStack(spacing: AppTheme.spacingSm) {
                    Image(systemName: "alarm.fill")
                        .font(.system(size: 14))
                    Text(alarm.timeString)
                        .font(AppTheme.headline)
                }
                .foregroundStyle(AppTheme.gold.opacity(0.6))
            }

            // Subtle reminder
            Text("Sleep Mode active")
                .font(AppTheme.caption)
                .foregroundStyle(AppTheme.warmWhite.opacity(0.2))
                .padding(.top, AppTheme.spacingXl)
        }
    }

    // MARK: - Playing state (affirmations active)

    private var playingState: some View {
        VStack(spacing: AppTheme.spacingXl) {
            // Animated waveform indicator
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { i in
                    WaveBar(index: i)
                }
            }
            .frame(height: 40)
            .padding(.bottom, AppTheme.spacingMd)

            Text("Good morning")
                .font(AppTheme.title)
                .foregroundStyle(AppTheme.gold)

            Text("Your affirmations are playing")
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.warmWhite.opacity(0.6))
        }
    }

    // MARK: - Exit button

    private var exitButton: some View {
        Button {
            if scheduler.isPlayingMorningAudio {
                // Don't interrupt playback.
                dismiss()
            } else {
                showExitConfirmation = true
            }
        } label: {
            Text(scheduler.isPlayingMorningAudio ? "Done" : "Exit Sleep Mode")
                .font(AppTheme.caption)
                .foregroundStyle(AppTheme.warmWhite.opacity(0.25))
                .padding(.horizontal, AppTheme.spacingXl)
                .padding(.vertical, AppTheme.spacingMd)
        }
    }

    // MARK: - Helpers

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: date)
    }

    /// Gradually ramp screen brightness over `duration` seconds — the
    /// physical complement to `SunriseBackground`'s on-screen gradient.
    /// 30 linear steps keeps the ramp smooth without saturating MainActor.
    private func rampBrightness(to target: CGFloat, duration: TimeInterval) {
        let start = UIScreen.main.brightness
        let steps = 30
        let interval = duration / Double(steps)
        Task { @MainActor in
            for step in 1...steps {
                try? await Task.sleep(for: .seconds(interval))
                let t = CGFloat(step) / CGFloat(steps)
                UIScreen.main.brightness = start + (target - start) * t
            }
        }
    }
}

// MARK: - Wave animation bar

private struct WaveBar: View {
    let index: Int
    @State private var animating = false

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(AppTheme.gold)
            .frame(width: 4, height: animating ? 36 : 12)
            .animation(
                .easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.1),
                value: animating
            )
            .onAppear { animating = true }
    }
}
