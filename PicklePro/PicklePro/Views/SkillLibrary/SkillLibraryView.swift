import SwiftUI

struct SkillLibraryView: View {
    @State private var selectedCategory: SkillCategory? = nil
    @State private var showMentalGame = false

    var filteredSkills: [Skill] {
        if let category = selectedCategory {
            return MockDataService.skills.filter { $0.category == category }
        }
        return MockDataService.skills
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PickleProColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Segment Control
                        HStack(spacing: 0) {
                            SegmentButton(title: "Skills", isActive: !showMentalGame) {
                                withAnimation { showMentalGame = false }
                            }
                            SegmentButton(title: "Mental Game", isActive: showMentalGame) {
                                withAnimation { showMentalGame = true }
                            }
                        }
                        .background(PickleProColors.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal, 24)

                        if showMentalGame {
                            MentalGameListView()
                        } else {
                            // Category Filter
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    PPChip(title: "All", isSelected: selectedCategory == nil) {
                                        selectedCategory = nil
                                    }
                                    ForEach(SkillCategory.allCases, id: \.self) { category in
                                        PPChip(
                                            title: category.rawValue,
                                            isSelected: selectedCategory == category
                                        ) {
                                            selectedCategory = category
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }

                            // Skills List
                            LazyVStack(spacing: 12) {
                                ForEach(filteredSkills) { skill in
                                    NavigationLink(destination: SkillDetailView(skill: skill)) {
                                        SkillCardView(skill: skill)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct SegmentButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(PickleProTypography.headline)
                .foregroundColor(isActive ? .black : PickleProColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isActive ? PickleProColors.accent : Color.clear)
                .cornerRadius(12)
        }
    }
}

struct SkillCardView: View {
    let skill: Skill

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: skill.icon)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: skill.category.color))
                .frame(width: 50, height: 50)
                .background(Color(hex: skill.category.color).opacity(0.15))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(skill.title)
                    .font(PickleProTypography.headline)
                    .foregroundColor(.white)

                Text(String(skill.explanation.prefix(60)) + "...")
                    .font(PickleProTypography.caption)
                    .foregroundColor(PickleProColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(PickleProColors.textTertiary)
        }
        .padding(16)
        .background(PickleProColors.cardBackground)
        .cornerRadius(14)
    }
}
