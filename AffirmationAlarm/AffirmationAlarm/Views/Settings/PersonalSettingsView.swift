import SwiftUI
import SwiftData

/// One screen for every personal knob that drives morning generation:
/// name, goals, focus areas, how many affirmations, and their length.
/// Replaces the previous Profile + Alarm Preferences split — they all
/// answer "what does my morning sound like?" so a single screen saves
/// the user a tap and a context switch.
///
/// Goal/focus changes invalidate today's cached affirmations and rendered
/// MP3s so the next render rebuilds with the new inputs instead of
/// waiting until tomorrow.
struct PersonalSettingsView: View {
    @Query private var profiles: [UserProfile]
    @Query private var alarms: [Alarm]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    private var profile: UserProfile? { profiles.first }

    @State private var name = ""
    @State private var goals = ""
    @State private var showSavedToast = false

    private var hasProfanity: Bool {
        ProfanityFilter.containsProfanity(goals)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !hasProfanity
    }

    var body: some View {
        ZStack {
            GradientBackground(style: .sunrise, withBlobs: false)

            ScrollView {
                VStack(spacing: AppTheme.spacingXxl) {
                    nameField
                    goalsField

                    if let profile {
                        countPicker(profile: profile)
                    }
                }
                .padding(AppTheme.spacingXl)
            }
        }
        .navigationTitle("Personal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { save() }
                    .foregroundStyle(canSave ? AppTheme.gold : AppTheme.textTertiary)
                    .disabled(!canSave)
            }
        }
        .overlay(alignment: .top) {
            ToastView(message: "Saved", isPresented: $showSavedToast)
        }
        .onAppear {
            if let profile {
                name = profile.name
                goals = profile.freeformGoals
            }
        }
    }

    // MARK: - Fields

    private var nameField: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            Text("Name")
                .font(AppTheme.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            TextField("Your name", text: $name)
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textPrimary)
                .padding(AppTheme.spacingLg)
                .background(AppTheme.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                .dismissKeyboardOnSubmit()
        }
    }

    private var goalsField: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
            Text("Goals")
                .font(AppTheme.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            TextEditor(text: $goals)
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(AppTheme.spacingMd)
                .frame(minHeight: 100)
                .background(AppTheme.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))

            if hasProfanity {
                Text("Please remove inappropriate language from your goals.")
                    .font(AppTheme.caption)
                    .foregroundStyle(.red.opacity(0.9))
            }
        }
    }

    private func countPicker(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            Text("Daily Affirmations")
                .font(AppTheme.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Text("How many affirmations you hear each morning.")
                .font(AppTheme.caption)
                .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: AppTheme.spacingMd) {
                ForEach(1...5, id: \.self) { count in
                    Button("\(count)") {
                        HapticService.selection()
                        profile.affirmationCount = count
                        invalidateAndRerender()
                    }
                    .font(AppTheme.headline)
                    .foregroundStyle(count == profile.affirmationCount ? AppTheme.charcoalBlue : AppTheme.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(count == profile.affirmationCount ? AppTheme.gold : AppTheme.cardBackground)
                    .clipShape(Circle())
                    .buttonStyle(.bounce)
                }
            }
        }
        .padding(AppTheme.spacingLg)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
    }

    /// Drop the cached MP3 for this alarm and kick off a fresh render so
    /// the user-selected count takes effect on the next fire instead of
    /// waiting for natural staleness. Used by the count picker.
    private func invalidateAndRerender() {
        guard let profile else { return }
        // Affirmation count change invalidates the pool — all pre-rendered
        // files have the old count. Pool signature includes affirmationCount.
        AffirmationPool.shared.invalidateAll()
        Task { @MainActor [profile, modelContext] in
            await AffirmationPool.shared.refresh(profile: profile, modelContext: modelContext)
        }
    }

    // MARK: - Save

    private func save() {
        guard let profile else {
            dismiss()
            return
        }

        let newGoals = goals
        let goalsChanged = profile.freeformGoals != newGoals

        profile.name = name.trimmingCharacters(in: .whitespaces)
        profile.freeformGoals = newGoals

        // Goals drive affirmation generation. When they change, drop
        // today's cached affirmations + MP3s so the next render rebuilds
        // with the new goals — otherwise the user waits until tomorrow.
        if goalsChanged {
            purgeAllGeneratedAffirmations()
            // Goals are baked into every pool file. Invalidate all and
            // regenerate with the new goals.
            AffirmationPool.shared.invalidateAll()
            Task { @MainActor [profile, modelContext] in
                await AffirmationPool.shared.refresh(profile: profile, modelContext: modelContext)
            }
        }

        HapticService.success()
        withAnimation(.easeIn(duration: 0.2)) {
            showSavedToast = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            dismiss()
        }
    }

    /// Drop every generated (non-favorite, non-custom) Affirmation row and
    /// every closing message so the Affirmations tab shows its empty state
    /// during the brief regeneration window — no flash of yesterday's
    /// stale lines while the new ones synthesize.
    private func purgeAllGeneratedAffirmations() {
        let affDescriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate {
                $0.isCustom == false && $0.favoriteType == 0
            }
        )
        if let rows = try? modelContext.fetch(affDescriptor) {
            for a in rows { modelContext.delete(a) }
        }

        let closingDescriptor = FetchDescriptor<DailyClosingMessage>()
        if let closings = try? modelContext.fetch(closingDescriptor) {
            for c in closings { modelContext.delete(c) }
        }
        try? modelContext.save()
    }
}
