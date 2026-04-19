import SwiftUI
import SwiftData

struct ProfileEditView: View {
    @Query private var profiles: [UserProfile]
    @Query private var alarms: [Alarm]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    private var profile: UserProfile? { profiles.first }

    @State private var name = ""
    @State private var goals = ""
    @State private var selectedCategories: Set<GoalCategory> = []

    var body: some View {
        ZStack {
            GradientBackground(style: .sunrise, withBlobs: false)

            ScrollView {
                VStack(spacing: AppTheme.spacingXxl) {
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

                    VStack(alignment: .leading, spacing: AppTheme.spacingSm) {
                        Text("Focus Areas")
                            .font(AppTheme.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                        FlowLayout(spacing: AppTheme.spacingSm) {
                            ForEach(GoalCategory.allCases, id: \.self) { category in
                                CategoryChip(
                                    category: category,
                                    isSelected: selectedCategories.contains(category)
                                ) {
                                    if selectedCategories.contains(category) {
                                        selectedCategories.remove(category)
                                    } else {
                                        selectedCategories.insert(category)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(AppTheme.spacingXl)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    if let profile {
                        let newGoals = goals
                        let newCategories = selectedCategories.map(\.rawValue).sorted()
                        let goalsChanged = profile.freeformGoals != newGoals
                            || profile.selectedCategories.sorted() != newCategories

                        profile.name = name.trimmingCharacters(in: .whitespaces)
                        profile.freeformGoals = newGoals
                        profile.selectedCategories = selectedCategories.map(\.rawValue)

                        // Goals drive affirmation generation. When they
                        // change, invalidate today's cached affirmations
                        // and rendered MP3s so the next render rebuilds
                        // with the new goals — otherwise the user waits
                        // until tomorrow to hear the update.
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
                    }
                    dismiss()
                }
                .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty ? AppTheme.textTertiary : AppTheme.gold)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            if let profile {
                name = profile.name
                goals = profile.freeformGoals
                selectedCategories = Set(
                    profile.selectedCategories.compactMap { GoalCategory(rawValue: $0) }
                )
            }
        }
    }

    /// Delete today's generated affirmations + closing so the next
    /// `AffirmationCacheService.fetchOrGenerate` call treats it as a
    /// cache miss and regenerates against the new goals. Favorites
    /// (`favoriteType != 0`) and user-typed custom affirmations are
    /// preserved.
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
