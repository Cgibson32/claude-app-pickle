import SwiftUI

struct BeforePlayView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPerformance: IntentionOption?
    @State private var selectedMental: IntentionOption?
    @State private var selectedJoy: IntentionOption?
    @State private var currentStep = 0

    var body: some View {
        NavigationStack {
            ZStack {
                PickleProColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 40))
                                .foregroundColor(PickleProColors.gold)

                            Text("Before You Play")
                                .font(PickleProTypography.title)
                                .foregroundColor(.white)

                            Text("Set your intention for today's session")
                                .font(PickleProTypography.subheadline)
                                .foregroundColor(PickleProColors.textSecondary)
                        }
                        .padding(.top, 20)

                        // Performance Intention
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Performance Focus", systemImage: "target")
                                .font(PickleProTypography.headline)
                                .foregroundColor(PickleProColors.accent)

                            ForEach(performanceIntentions, id: \.id) { option in
                                IntentionOptionRow(
                                    option: option,
                                    isSelected: selectedPerformance?.id == option.id,
                                    color: PickleProColors.accent
                                ) {
                                    selectedPerformance = option
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        // Mental Intention
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Mental Cue", systemImage: "brain.head.profile")
                                .font(PickleProTypography.headline)
                                .foregroundColor(PickleProColors.teal)

                            ForEach(mentalIntentions, id: \.id) { option in
                                IntentionOptionRow(
                                    option: option,
                                    isSelected: selectedMental?.id == option.id,
                                    color: PickleProColors.teal
                                ) {
                                    selectedMental = option
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        // Joy Intention
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Joy Intention", systemImage: "sun.max.fill")
                                .font(PickleProTypography.headline)
                                .foregroundColor(PickleProColors.gold)

                            ForEach(joyIntentions, id: \.id) { option in
                                IntentionOptionRow(
                                    option: option,
                                    isSelected: selectedJoy?.id == option.id,
                                    color: PickleProColors.gold
                                ) {
                                    selectedJoy = option
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        // Set Intention Button
                        PPButton(title: "Set My Intention", style: .primary) {
                            dismiss()
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(PickleProColors.accent)
                }
            }
        }
    }
}

struct IntentionOptionRow: View {
    let option: IntentionOption
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: option.icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .black : color)
                    .frame(width: 32, height: 32)
                    .background(isSelected ? color : color.opacity(0.15))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(option.category)
                        .font(PickleProTypography.captionBold)
                        .foregroundColor(isSelected ? color : PickleProColors.textTertiary)
                    Text(option.text)
                        .font(PickleProTypography.callout)
                        .foregroundColor(.white)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(color)
                }
            }
            .padding(14)
            .background(
                isSelected
                    ? color.opacity(0.1)
                    : PickleProColors.cardBackground
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
