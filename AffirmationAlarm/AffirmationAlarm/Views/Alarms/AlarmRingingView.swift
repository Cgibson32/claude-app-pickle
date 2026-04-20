import SwiftUI

/// Fullscreen ringing overlay shown when an alarm fires while the app is
/// foregrounded but NOT in Sleep Mode. Presented as a `.fullScreenCover`
/// from `RootView`. The matching in-Sleep-Mode ringing state lives inline
/// in `SleepModeView`.
struct AlarmRingingView: View {
    @State private var scheduler = AlarmKitScheduler.shared
    @State private var currentTime = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                AlarmRingingContent(
                    time: currentTime,
                    label: scheduler.ringingAlarmLabel,
                    onStop: {
                        HapticService.medium()
                        scheduler.userPressedStop()
                    },
                    onSnooze: {
                        HapticService.light()
                        scheduler.userPressedSnooze()
                    }
                )

                Spacer()
            }
        }
        .persistentSystemOverlays(.hidden)
        .statusBarHidden()
        .preferredColorScheme(.dark)
        .onReceive(timer) { _ in currentTime = Date() }
    }
}

/// Shared ringing UI content used by both `AlarmRingingView` (fullscreen
/// cover) and `SleepModeView` (inline state). Keeps the visual design in
/// one place.
struct AlarmRingingContent: View {
    let time: Date
    let label: String
    let onStop: () -> Void
    let onSnooze: () -> Void

    @State private var pulsing = false

    var body: some View {
        VStack(spacing: AppTheme.spacingXl) {
            Image(systemName: "alarm.waves.left.and.right.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.sunsetOrange)
                .scaleEffect(pulsing ? 1.15 : 1.0)
                .animation(
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: pulsing
                )
                .onAppear { pulsing = true }
                .padding(.bottom, AppTheme.spacingMd)

            Text(timeString)
                .font(.system(size: 56, weight: .thin, design: .rounded))
                .foregroundStyle(AppTheme.warmWhite)
                .monospacedDigit()

            if !label.isEmpty {
                Text(label)
                    .font(AppTheme.headline)
                    .foregroundStyle(AppTheme.warmWhite.opacity(0.7))
            }

            Spacer().frame(height: AppTheme.spacingXl)

            Button(action: onStop) {
                Text("Stop")
                    .font(AppTheme.title3)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.spacingLg)
                    .background(AppTheme.sunsetOrange)
                    .clipShape(Capsule())
                    .shadow(color: AppTheme.sunsetOrange.opacity(0.4), radius: 12, y: 6)
            }
            .padding(.horizontal, AppTheme.spacing3xl)

            Button(action: onSnooze) {
                HStack(spacing: AppTheme.spacingSm) {
                    Image(systemName: "zzz")
                    Text("Snooze \u{00B7} \(AppConstants.snoozeDurationMinutes) min")
                }
                .font(AppTheme.headline)
                .foregroundStyle(AppTheme.warmWhite.opacity(0.7))
                .padding(.vertical, AppTheme.spacingMd)
            }
        }
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: time)
    }
}
