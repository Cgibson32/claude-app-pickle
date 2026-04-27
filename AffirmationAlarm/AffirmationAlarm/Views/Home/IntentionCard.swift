import SwiftUI
import SwiftData

/// Home tile that lets the user set a single sentence the night before.
/// `AffirmationCacheService` reads the most-recent intention (within 24
/// hours) and `ClaudeAPIService` is told to call it back in the morning's
/// first affirmation. The card itself stays subtle — the ritual happens
/// in the sheet, not in the inline real estate.
struct IntentionCard: View {
    @Query(sort: \EveningIntention.createdAt, order: .reverse)
    private var intentions: [EveningIntention]

    @State private var showSheet = false

    private var freshIntentionText: String? {
        guard let latest = intentions.first, !latest.consumed else { return nil }
        let trimmed = latest.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let age = Date().timeIntervalSince(latest.createdAt)
        guard age >= 0, age < 24 * 60 * 60 else { return nil }
        return trimmed
    }

    var body: some View {
        Button {
            showSheet = true
        } label: {
            HStack(alignment: .top, spacing: AppTheme.spacingMd) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.warmAmber)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Tonight's intention")
                        .font(AppTheme.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    if let intention = freshIntentionText {
                        Text(intention)
                            .font(.system(size: 15, design: .serif))
                            .italic()
                            .foregroundStyle(AppTheme.gold.opacity(0.85))
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("What do you want to wake up to?")
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary)
                    .padding(.top, 4)
            }
            .padding(AppTheme.spacingLg)
            .background(AppTheme.warmAmber.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusLg)
                    .strokeBorder(AppTheme.warmAmber.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.bounce)
        .sheet(isPresented: $showSheet) {
            IntentionSheet(initialText: freshIntentionText ?? "")
        }
    }
}

/// Single-sentence input. Saving inserts a new `EveningIntention` row and
/// invalidates the rendered audio so the next pre-render picks up the
/// new intention before the morning alarm fires.
struct IntentionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    @State private var text: String
    @State private var showSavedToast = false
    @FocusState private var focused: Bool

    init(initialText: String = "") {
        _text = State(initialValue: initialText)
    }

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground(style: .sunrise, withBlobs: false)

                VStack(alignment: .leading, spacing: AppTheme.spacingLg) {
                    Text("One sentence about what matters tomorrow. Your morning will speak to it directly.")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    TextField(
                        "I want to wake up feeling…",
                        text: $text,
                        axis: .vertical
                    )
                    .font(AppTheme.bodyFont)
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2...6)
                    .padding(AppTheme.spacingLg)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                    .focused($focused)

                    Spacer()
                }
                .padding(AppTheme.spacingXl)
            }
            .navigationTitle("Tonight's Intention")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .foregroundStyle(AppTheme.gold)
                        .fontWeight(.semibold)
                }
            }
            .onAppear { focused = true }
            .overlay(alignment: .top) {
                ToastView(message: "Saved for tomorrow", isPresented: $showSavedToast)
            }
        }
    }

    private func save() {
        if trimmed.isEmpty {
            consumeAllFreshIntentions()
        } else {
            let intent = EveningIntention(text: trimmed)
            modelContext.insert(intent)
        }
        try? modelContext.save()
        HapticService.success()

        MorningAudioRenderer.shared.invalidateAll()

        if let profile = profiles.first {
            let alarms = (try? modelContext.fetch(FetchDescriptor<Alarm>())) ?? []
            let context = modelContext
            Task { @MainActor in
                await MorningAudioRenderer.shared.refreshAll(
                    alarms: alarms,
                    profile: profile,
                    modelContext: context
                )
            }
        }

        focused = false
        withAnimation(.easeIn(duration: 0.2)) {
            showSavedToast = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            dismiss()
        }
    }

    private func consumeAllFreshIntentions() {
        let descriptor = FetchDescriptor<EveningIntention>(
            predicate: #Predicate { $0.consumed == false }
        )
        guard let rows = try? modelContext.fetch(descriptor) else { return }
        for row in rows { row.consumed = true }
    }
}
