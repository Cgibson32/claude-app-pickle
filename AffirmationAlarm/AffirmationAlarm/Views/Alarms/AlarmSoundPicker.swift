import SwiftUI

struct AlarmSoundPicker: View {
    @Binding var selectedSound: String
    @State private var previewingSound: String?

    var body: some View {
        VStack(spacing: 4) {
            ForEach(AppConstants.AlarmSounds.allCases, id: \.rawValue) { sound in
                Button {
                    selectedSound = sound.rawValue
                    previewSound(sound.rawValue)
                } label: {
                    HStack {
                        Image(systemName: selectedSound == sound.rawValue ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(AppTheme.textPrimary)

                        Text(sound.displayName)
                            .foregroundColor(AppTheme.textPrimary)

                        Spacer()

                        if previewingSound == sound.rawValue {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(AppTheme.textSecondary)
                                .font(.system(size: 12))
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedSound == sound.rawValue
                                  ? AppTheme.chipUnselected
                                  : Color.clear)
                    )
                }
            }
        }
    }

    private func previewSound(_ name: String) {
        previewingSound = name
        AudioService.shared.previewSound(named: name)

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if previewingSound == name {
                previewingSound = nil
            }
        }
    }
}

#Preview {
    ZStack {
        GradientBackground()
        AlarmSoundPicker(selectedSound: .constant("alarm_gentle"))
            .padding()
    }
}
