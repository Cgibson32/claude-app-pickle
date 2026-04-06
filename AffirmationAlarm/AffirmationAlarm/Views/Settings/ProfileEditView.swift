import SwiftUI
import SwiftData

struct ProfileEditView: View {
    @Query private var profiles: [UserProfile]
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
                        profile.name = name.trimmingCharacters(in: .whitespaces)
                        profile.freeformGoals = goals
                        profile.selectedCategories = selectedCategories.map(\.rawValue)
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
}
