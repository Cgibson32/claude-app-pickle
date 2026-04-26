import SwiftUI

/// Fullscreen ringing overlay shown when an alarm fires and the app is
/// foregrounded. Presented as a `.fullScreenCover` from `RootView`.
struct AlarmRingingView: View {
    @State private var scheduler = AlarmKitScheduler.shared
    @State private var currentTime = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            SunriseBackground()

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

// MARK: - Sunrise Background

/// 3-second animated gradient that fades from pure black through deep
/// amber to warm gold — simulating the first light of sunrise. Three
/// radial layers fade in sequentially for a natural build.
private struct SunriseBackground: View {
    @State private var showAmber = false
    @State private var showGold = false
    @State private var showWarm = false

    var body: some View {
        ZStack {
            Color.black

            RadialGradient(
                colors: [
                    Color(red: 0.28, green: 0.16, blue: 0.05).opacity(0.9),
                    Color(red: 0.12, green: 0.07, blue: 0.02).opacity(0.5),
                    .clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 500
            )
            .opacity(showAmber ? 1.0 : 0)

            RadialGradient(
                colors: [
                    Color(red: 0.79, green: 0.66, blue: 0.42).opacity(0.3),
                    .clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 350
            )
            .opacity(showGold ? 1.0 : 0)

            RadialGradient(
                colors: [
                    Color(red: 1.0, green: 0.82, blue: 0.4).opacity(0.12),
                    .clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 220
            )
            .opacity(showWarm ? 1.0 : 0)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeIn(duration: 2.0)) { showAmber = true }

            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.8))
                withAnimation(.easeIn(duration: 1.8)) { showGold = true }
            }

            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.6))
                withAnimation(.easeIn(duration: 1.4)) { showWarm = true }
            }
        }
    }
}

// MARK: - Shared Ringing Content

/// Shared ringing UI content used by `AlarmRingingView`. Kept as a
/// separate struct so the UI can also be embedded inline if needed.
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
                .foregroundStyle(AppTheme.gold)
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
                    .foregroundStyle(AppTheme.charcoalBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.spacingLg)
                    .background(AppTheme.gold)
                    .clipShape(Capsule())
                    .shadow(color: AppTheme.gold.opacity(0.4), radius: 12, y: 6)
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
