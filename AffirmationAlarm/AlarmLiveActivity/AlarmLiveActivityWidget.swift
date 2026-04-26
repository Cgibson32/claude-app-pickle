import ActivityKit
import AlarmKit
import SwiftUI
import WidgetKit

/// Live Activity that renders alongside AlarmKit's system alarm alert
/// when an alarm fires. Shows the custom gold-on-dark Resonance UI on
/// the lock screen (full banner) and Dynamic Island, while the system
/// alert provides the actual Stop/Snooze buttons via the
/// `AlarmConfiguration`'s `stopIntent` / `secondaryIntent`.
struct AlarmLiveActivityWidget: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<AffirmationAlarmMetadata>.self) { context in
            // Lock-screen full-width banner.
            LockScreenView(
                label: context.attributes.metadata.label,
                state: context.state
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
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.metadata.label)
                        .font(.subheadline)
                        .foregroundStyle(Self.cream.opacity(0.8))
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

private struct LockScreenView: View {
    let label: String
    let state: AlarmAttributes<AffirmationAlarmMetadata>.ContentState

    @State private var pulsing = false

    var body: some View {
        ZStack {
            // Warm gold radial glow on near-black, matching the in-app
            // ringing screen so the lock-screen presentation reads as the
            // same surface.
            RadialGradient(
                colors: [
                    Color(red: 0.16, green: 0.12, blue: 0.07),
                    Color(red: 0.05, green: 0.04, blue: 0.03)
                ],
                center: .center,
                startRadius: 0,
                endRadius: 240
            )

            HStack(spacing: 16) {
                Image(systemName: "alarm.waves.left.and.right.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(AlarmLiveActivityWidget.gold)
                    .scaleEffect(pulsing ? 1.10 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                        value: pulsing
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(timeString)
                        .font(.system(size: 32, weight: .thin, design: .rounded))
                        .foregroundStyle(AlarmLiveActivityWidget.cream)
                        .monospacedDigit()
                    if !label.isEmpty {
                        Text(label)
                            .font(.subheadline)
                            .foregroundStyle(AlarmLiveActivityWidget.cream.opacity(0.7))
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .onAppear { pulsing = true }
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: Date())
    }
}
