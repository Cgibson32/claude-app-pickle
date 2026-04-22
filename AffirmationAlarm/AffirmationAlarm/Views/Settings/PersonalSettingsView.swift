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

    var body: some View {
        ZStack {
            GradientBackground(style: .sunrise, withBlobs: false)

            ScrollView {
                VStack(spacing: AppTheme.spacingXxl) {
                    nameField
                    goalsField

                    if let profile {
                        countPicker(profile: profile)
                        lengthPicker(profile: profile)
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
                    .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty ? AppTheme.textTertiary : AppTheme.gold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
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

    private func lengthPicker(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMd) {
            Text("Length")
                .font(AppTheme.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Text(profile.budget.caption)
                .font(AppTheme.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .animation(.easeInOut(duration: 0.15), value: profile.budget)

            HStack(spacing: AppTheme.spacingMd) {
                ForEach(AffirmationBudget.allCases, id: \.self) { option in
                    Button(option.label) {
                        HapticService.selection()
                        profile.budget = option
                        MorningAudioRenderer.shared.invalidateAll()
                    }
                    .font(AppTheme.headline)
                    .foregroundStyle(option == profile.budget ? AppTheme.charcoalBlue : AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(option == profile.budget ? AppTheme.gold : AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
                    .buttonStyle(.bounce)
                }
            }
        }
        .padding(AppTheme.spacingLg)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLg))
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
            invalidateTodaysAffirmations()
            MorningAudioRenderer.shared.invalidateAll()
            Task { @MainActor [alarms, profile, modelContext] in
                await MorningAudioRenderer.shared.refreshAll(
                    alarms: alarms,
                    profile: profile,
                    modelContext: modelContext
                )
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

    private func invalidateTodaysAffirmations() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today

        let affDescriptor = FetchDescriptor<Affirmation>(
            predicate: #Predicate {
                $0.generatedFor >= today
                    && $0.generatedFor < tomorrow
                    && $0.isCustom == false
                    && $0.favoriteType == 0
            }
        )
        if let todays = try? modelContext.fetch(affDescriptor) {
            for a in todays { modelContext.delete(a) }
        }

        let closingDescriptor = FetchDescriptor<DailyClosingMessage>(
            predicate: #Predicate { $0.generatedFor >= today && $0.generatedFor < tomorrow }
        )
        if let closings = try? modelContext.fetch(closingDescriptor) {
            for c in closings { modelContext.delete(c) }
        }
    }
}
