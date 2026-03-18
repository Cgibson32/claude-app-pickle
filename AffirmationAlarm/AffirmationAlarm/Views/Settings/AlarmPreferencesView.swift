import SwiftUI
import SwiftData

struct AlarmPreferencesView: View {
    @Bindable var profile: UserProfile

    var body: some View {
        ZStack {
            GradientBackground(style: .calm)

            ScrollView {
                VStack(spacing: 24) {
                    // Alarm Sound Duration
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Alarm Sound Duration")
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(Int(profile.alarmSoundDuration))s")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                        }

                        Text("How long the alarm sound plays before your affirmations begin.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))

                        Slider(value: $profile.alarmSoundDuration, in: 3...15, step: 1)
                            .tint(.orange)

                        HStack {
                            Text("3s")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.4))
                            Spacer()
                            Text("15s")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.1))
                    )

                    // Affirmation Count
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily Affirmations")
                            .foregroundColor(.white)

                        Text("How many affirmations are generated for each morning.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))

                        HStack(spacing: 10) {
                            ForEach(1...5, id: \.self) { count in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        profile.affirmationCount = count
                                    }
                                } label: {
                                    Text("\(count)")
                                        .font(.headline)
                                        .frame(width: 48, height: 48)
                                        .background(
                                            Circle()
                                                .fill(profile.affirmationCount == count
                                                      ? Color.white
                                                      : Color.white.opacity(0.2))
                                        )
                                        .foregroundColor(profile.affirmationCount == count ? .black : .white)
                                }
                            }
                        }

                        Text("Changes apply to your next alarm. Favorited affirmations are included in this count.")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.1))
                    )
                }
                .padding()
            }
        }
        .navigationTitle("Alarm Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
