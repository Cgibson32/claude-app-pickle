import SwiftUI

// MARK: - Welcome Step
struct OnboardingWelcomeStep: View {
    @State private var animate = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(PickleProColors.accent.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .scaleEffect(animate ? 1.1 : 1.0)

                Circle()
                    .fill(PickleProColors.accent.opacity(0.2))
                    .frame(width: 140, height: 140)

                Image(systemName: "figure.pickleball")
                    .font(.system(size: 60))
                    .foregroundColor(PickleProColors.accent)
            }
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animate)

            VStack(spacing: 12) {
                HStack(spacing: 0) {
                    Text("Pickle")
                        .font(PickleProTypography.largeTitle)
                        .foregroundColor(.white)
                    Text("Pro")
                        .font(PickleProTypography.largeTitle)
                        .foregroundColor(PickleProColors.accent)
                }

                Text("Your daily pickleball performance companion")
                    .font(PickleProTypography.body)
                    .foregroundColor(PickleProColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear { animate = true }
    }
}

// MARK: - Mission Step
struct OnboardingMissionStep: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "target")
                    .font(.system(size: 50))
                    .foregroundColor(PickleProColors.accent)

                Text("Our Mission")
                    .font(PickleProTypography.title)
                    .foregroundColor(.white)

                Text("PicklePro helps you shift from being results-oriented to process-oriented. Focus less on winning and losing — and more on growth, patience, and enjoying the journey.")
                    .font(PickleProTypography.body)
                    .foregroundColor(PickleProColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }

            VStack(spacing: 16) {
                MissionRow(icon: "arrow.up.right", text: "Consistent skill development")
                MissionRow(icon: "brain.head.profile", text: "Mental performance training")
                MissionRow(icon: "heart.fill", text: "Love of the game")
                MissionRow(icon: "chart.line.uptrend.xyaxis", text: "Process-oriented growth")
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct MissionRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(PickleProColors.accent)
                .frame(width: 32, height: 32)
                .background(PickleProColors.accent.opacity(0.15))
                .cornerRadius(8)

            Text(text)
                .font(PickleProTypography.callout)
                .foregroundColor(.white)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(PickleProColors.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Growth Step
struct OnboardingGrowthStep: View {
    @State private var visibleIndex = 0
    let statements = [
        "Improvement can be fun.",
        "The process can be enjoyable.",
        "Discipline and joy can coexist.",
        "Great pickleball is played with freedom.",
        "Loving the game is part of getting better."
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundColor(PickleProColors.gold)

                Text("Believe This")
                    .font(PickleProTypography.title)
                    .foregroundColor(.white)

                VStack(spacing: 16) {
                    ForEach(0..<statements.count, id: \.self) { index in
                        Text(statements[index])
                            .font(PickleProTypography.quoteSmall)
                            .foregroundColor(index <= visibleIndex ? .white : PickleProColors.textTertiary)
                            .italic()
                            .animation(.easeIn(duration: 0.5).delay(Double(index) * 0.4), value: visibleIndex)
                    }
                }
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            visibleIndex = statements.count - 1
        }
    }
}

// MARK: - Name Step
struct OnboardingNameStep: View {
    @Binding var name: String

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(PickleProColors.accent)

                Text("What should we call you?")
                    .font(PickleProTypography.title2)
                    .foregroundColor(.white)

                TextField("Your name", text: $name)
                    .font(PickleProTypography.title3)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(PickleProColors.cardBackground)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(PickleProColors.accent.opacity(0.3), lineWidth: 1)
                    )
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Experience Level Step
struct OnboardingExperienceStep: View {
    @Binding var level: ExperienceLevel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 50))
                    .foregroundColor(PickleProColors.accent)

                Text("What's your skill level?")
                    .font(PickleProTypography.title2)
                    .foregroundColor(.white)

                Text("This helps us personalize your experience")
                    .font(PickleProTypography.subheadline)
                    .foregroundColor(PickleProColors.textSecondary)
            }

            VStack(spacing: 12) {
                ForEach(ExperienceLevel.allCases, id: \.self) { exp in
                    PPSelectionChip(
                        title: exp.rawValue,
                        isSelected: level == exp,
                        action: { level = exp }
                    )
                }
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Frequency Step
struct OnboardingFrequencyStep: View {
    @Binding var frequency: PlayFrequency
    @Binding var preference: PlayPreference

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "calendar")
                        .font(.system(size: 50))
                        .foregroundColor(PickleProColors.accent)

                    Text("How often do you play?")
                        .font(PickleProTypography.title2)
                        .foregroundColor(.white)
                }
                .padding(.top, 40)

                VStack(spacing: 12) {
                    ForEach(PlayFrequency.allCases, id: \.self) { freq in
                        PPSelectionChip(
                            title: freq.rawValue,
                            isSelected: frequency == freq,
                            action: { frequency = freq }
                        )
                    }
                }

                VStack(spacing: 16) {
                    Text("Do you prefer?")
                        .font(PickleProTypography.title3)
                        .foregroundColor(.white)

                    VStack(spacing: 12) {
                        ForEach(PlayPreference.allCases, id: \.self) { pref in
                            PPSelectionChip(
                                title: pref.rawValue,
                                isSelected: preference == pref,
                                action: { preference = pref }
                            )
                        }
                    }
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Struggles Step
struct OnboardingStrugglesStep: View {
    @Binding var selected: Set<Struggle>

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(PickleProColors.warning)

                    Text("What are your biggest struggles?")
                        .font(PickleProTypography.title2)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Select all that apply")
                        .font(PickleProTypography.subheadline)
                        .foregroundColor(PickleProColors.textSecondary)
                }
                .padding(.top, 40)

                VStack(spacing: 10) {
                    ForEach(Struggle.allCases, id: \.self) { struggle in
                        PPSelectionChip(
                            title: struggle.rawValue,
                            isSelected: selected.contains(struggle),
                            action: {
                                if selected.contains(struggle) {
                                    selected.remove(struggle)
                                } else {
                                    selected.insert(struggle)
                                }
                            }
                        )
                    }
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Technical Weaknesses Step
struct OnboardingTechnicalStep: View {
    @Binding var selected: Set<TechnicalSkill>

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 50))
                        .foregroundColor(PickleProColors.info)

                    Text("Which skills need the most work?")
                        .font(PickleProTypography.title2)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Select your top weaknesses")
                        .font(PickleProTypography.subheadline)
                        .foregroundColor(PickleProColors.textSecondary)
                }
                .padding(.top, 40)

                VStack(spacing: 10) {
                    ForEach(TechnicalSkill.allCases, id: \.self) { skill in
                        PPSelectionChip(
                            title: skill.rawValue,
                            isSelected: selected.contains(skill),
                            action: {
                                if selected.contains(skill) {
                                    selected.remove(skill)
                                } else {
                                    selected.insert(skill)
                                }
                            }
                        )
                    }
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Mental Weaknesses Step
struct OnboardingMentalStep: View {
    @Binding var selected: Set<MentalSkill>

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 50))
                        .foregroundColor(PickleProColors.teal)

                    Text("Where does your mental game struggle?")
                        .font(PickleProTypography.title2)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Select all that apply")
                        .font(PickleProTypography.subheadline)
                        .foregroundColor(PickleProColors.textSecondary)
                }
                .padding(.top, 40)

                VStack(spacing: 10) {
                    ForEach(MentalSkill.allCases, id: \.self) { skill in
                        PPSelectionChip(
                            title: skill.rawValue,
                            isSelected: selected.contains(skill),
                            action: {
                                if selected.contains(skill) {
                                    selected.remove(skill)
                                } else {
                                    selected.insert(skill)
                                }
                            }
                        )
                    }
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Goals Step
struct OnboardingGoalsStep: View {
    @Binding var selected: Set<PlayerGoal>

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 50))
                        .foregroundColor(PickleProColors.accent)

                    Text("What are your goals?")
                        .font(PickleProTypography.title2)
                        .foregroundColor(.white)

                    Text("What do you want to achieve?")
                        .font(PickleProTypography.subheadline)
                        .foregroundColor(PickleProColors.textSecondary)
                }
                .padding(.top, 40)

                VStack(spacing: 10) {
                    ForEach(PlayerGoal.allCases, id: \.self) { goal in
                        PPSelectionChip(
                            title: goal.rawValue,
                            isSelected: selected.contains(goal),
                            action: {
                                if selected.contains(goal) {
                                    selected.remove(goal)
                                } else {
                                    selected.insert(goal)
                                }
                            }
                        )
                    }
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Frustrations Step
struct OnboardingFrustrationsStep: View {
    @Binding var selected: Set<MatchFrustration>

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "cloud.bolt.fill")
                        .font(.system(size: 50))
                        .foregroundColor(PickleProColors.error)

                    Text("What frustrates you during matches?")
                        .font(PickleProTypography.title2)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("We'll help you work through these")
                        .font(PickleProTypography.subheadline)
                        .foregroundColor(PickleProColors.textSecondary)
                }
                .padding(.top, 40)

                VStack(spacing: 10) {
                    ForEach(MatchFrustration.allCases, id: \.self) { frustration in
                        PPSelectionChip(
                            title: frustration.rawValue,
                            isSelected: selected.contains(frustration),
                            action: {
                                if selected.contains(frustration) {
                                    selected.remove(frustration)
                                } else {
                                    selected.insert(frustration)
                                }
                            }
                        )
                    }
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Summary Step
struct OnboardingSummaryStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var animate = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(PickleProColors.accent.opacity(0.15))
                            .frame(width: 100, height: 100)
                            .scaleEffect(animate ? 1.1 : 1)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(PickleProColors.accent)
                    }
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animate)

                    Text("Your PicklePro journey\nbegins now.")
                        .font(PickleProTypography.title)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    if !viewModel.name.isEmpty {
                        Text("Welcome, \(viewModel.name)")
                            .font(PickleProTypography.headline)
                            .foregroundColor(PickleProColors.accent)
                    }
                }
                .padding(.top, 40)

                // Focus Skills
                if !viewModel.selectedTechnicalWeaknesses.isEmpty {
                    PPCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Top Focus Skills", systemImage: "target")
                                .font(PickleProTypography.headline)
                                .foregroundColor(PickleProColors.accent)

                            ForEach(Array(viewModel.selectedTechnicalWeaknesses).prefix(3), id: \.self) { skill in
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(PickleProColors.accent)
                                        .frame(width: 6, height: 6)
                                    Text(skill.rawValue)
                                        .font(PickleProTypography.callout)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // Mindset Priorities
                if !viewModel.selectedMentalWeaknesses.isEmpty {
                    PPCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Mindset Priorities", systemImage: "brain.head.profile")
                                .font(PickleProTypography.headline)
                                .foregroundColor(PickleProColors.teal)

                            ForEach(Array(viewModel.selectedMentalWeaknesses).prefix(3), id: \.self) { skill in
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(PickleProColors.teal)
                                        .frame(width: 6, height: 6)
                                    Text(skill.rawValue)
                                        .font(PickleProTypography.callout)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // Encouragement
                PPQuoteCard(
                    quote: "The journey of a thousand games begins with a single intention.",
                    attribution: "PicklePro"
                )

                Spacer(minLength: 100)
            }
            .padding(.horizontal, 24)
        }
        .onAppear { animate = true }
    }
}
