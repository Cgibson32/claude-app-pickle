import SwiftUI
import SwiftData

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var profile: UserProfile
    @State private var selectedCategories: Set<GoalCategory> = []

    var body: some View {
        ZStack {
            GradientBackground(style: .energy)

            ScrollView {
                VStack(spacing: 24) {
                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(AppTheme.subheadline)
                            .foregroundColor(AppTheme.textSecondary)

                        TextField("Your name", text: $profile.name)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.inputBackground)
                            )
                            .foregroundColor(AppTheme.textPrimary)
                            .tint(AppTheme.warmWhite)
                    }

                    // Goals
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Goals")
                            .font(AppTheme.subheadline)
                            .foregroundColor(AppTheme.textSecondary)

                        TextEditor(text: $profile.freeformGoals)
                            .frame(minHeight: 120)
                            .padding(8)
                            .scrollContentBackground(.hidden)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.inputBackground)
                            )
                            .foregroundColor(AppTheme.textPrimary)
                            .tint(AppTheme.warmWhite)
                    }

                    // Categories
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Focus Areas")
                            .font(AppTheme.subheadline)
                            .foregroundColor(AppTheme.textSecondary)

                        FlowLayout(spacing: 8) {
                            ForEach(GoalCategory.allCases) { category in
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
                .padding()
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            selectedCategories = Set(
                profile.selectedCategories.compactMap { GoalCategory(rawValue: $0) }
            )
        }
        .onDisappear {
            profile.selectedCategories = selectedCategories.map(\.rawValue)
        }
    }
}
