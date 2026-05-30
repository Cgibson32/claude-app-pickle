import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// Manual Live Activity started by the main app when affirmations are
/// playing. The AlarmKit-managed Live Activity dies the moment
/// `handleFire` cancels the system alarm — this one persists until
/// playback finishes or the user taps Stop/Snooze.
struct RingingLiveActivityWidget: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RingingAttributes.self) { context in
            RingingLockScreenView(
                alarmID: context.attributes.alarmID,
                label: context.attributes.label,
                isRinging: context.state.isRinging
            )
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "alarm.waves.left.and.right.fill")
                        .foregroundStyle(Self.gold)
                        .font(.title2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timeString)
                        .font(.system(size: 26, weight: .thin, design: .rounded))
                        .foregroundStyle(Self.cream)
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.label)
                        .font(.subheadline)
                        .foregroundStyle(Self.cream.opacity(0.8))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        Button(intent: SnoozeFromLockScreen(alarmID: context.attributes.alarmID)) {
                            Text("Snooze")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Self.cream.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)

                        Button(intent: StopFromLockScreen(alarmID: context.attributes.alarmID)) {
                            Text("Stop")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Self.gold)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            } compactLeading: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(Self.gold)
            } compactTrailing: {
                Text(timeString)
                    .foregroundStyle(Self.cream)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(Self.gold)
            }
        }
    }

    // MARK: - Brand colors

    static let gold = Color(red: 0.831, green: 0.722, blue: 0.471)
    static let cream = Color(red: 0.961, green: 0.933, blue: 0.855)

    // MARK: - Helpers

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: Date())
    }
}

// MARK: - Lock screen view

private struct RingingLockScreenView: View {
    let alarmID: UUID
    let label: String
    let isRinging: Bool

    @State private var pulsing = false

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    Color(red: 0.16, green: 0.12, blue: 0.07),
                    Color(red: 0.05, green: 0.04, blue: 0.03)
                ],
                center: .center,
                startRadius: 0,
                endRadius: 280
            )

            VStack(spacing: 16) {
                Image(systemName: "alarm.waves.left.and.right.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(RingingLiveActivityWidget.gold)
                    .scaleEffect(pulsing ? 1.10 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                        value: pulsing
                    )

                Text(timeString)
                    .font(.system(size: 36, weight: .thin, design: .rounded))
                    .foregroundStyle(RingingLiveActivityWidget.cream)
                    .monospacedDigit()

                if !label.isEmpty {
                    Text(label)
                        .font(.subheadline)
                        .foregroundStyle(RingingLiveActivityWidget.cream.opacity(0.7))
                }

                if isRinging {
                    Button(intent: StopFromLockScreen(alarmID: alarmID)) {
                        Text("Stop")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RingingLiveActivityWidget.gold)
                            .clipShape(Capsule())
                            .shadow(color: RingingLiveActivityWidget.gold.opacity(0.4), radius: 12, y: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)

                    Button(intent: SnoozeFromLockScreen(alarmID: alarmID)) {
                        HStack(spacing: 6) {
                            Image(systemName: "zzz")
                            Text("Snooze · 9 min")
                        }
                        .font(.subheadline)
                        .foregroundStyle(RingingLiveActivityWidget.cream.opacity(0.7))
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Alarm set")
                        .font(.subheadline)
                        .foregroundStyle(RingingLiveActivityWidget.cream.opacity(0.5))
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .onAppear { pulsing = true }
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: Date())
    }
}
