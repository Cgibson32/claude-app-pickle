import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var selectedPlan: SubscriptionPlan = .annual
    @State private var animate = false

    var body: some View {
        ZStack {
            PickleProColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Close Button
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(PickleProColors.textTertiary)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(PickleProColors.accent.opacity(0.1))
                                .frame(width: 120, height: 120)
                                .scaleEffect(animate ? 1.1 : 1)

                            Circle()
                                .fill(PickleProColors.accent.opacity(0.2))
                                .frame(width: 80, height: 80)

                            Image(systemName: "crown.fill")
                                .font(.system(size: 36))
                                .foregroundColor(PickleProColors.gold)
                        }
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animate)

                        HStack(spacing: 0) {
                            Text("Pickle")
                                .font(PickleProTypography.title)
                                .foregroundColor(.white)
                            Text("Pro")
                                .font(PickleProTypography.title)
                                .foregroundColor(PickleProColors.accent)
                            Text(" Premium")
                                .font(PickleProTypography.title)
                                .foregroundColor(PickleProColors.gold)
                        }

                        Text("Unlock your full potential")
                            .font(PickleProTypography.body)
                            .foregroundColor(PickleProColors.textSecondary)
                    }

                    // Features
                    VStack(spacing: 14) {
                        PremiumFeatureRow(icon: "sparkles", title: "Full AI Coaching", description: "Personalized daily insights and coaching")
                        PremiumFeatureRow(icon: "target", title: "Personalized Intentions", description: "AI-generated daily focus based on your game")
                        PremiumFeatureRow(icon: "books.vertical.fill", title: "Full Skill Library", description: "All skills and mental game lessons")
                        PremiumFeatureRow(icon: "brain.head.profile", title: "Mental Performance", description: "Complete mental game training")
                        PremiumFeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Advanced Analytics", description: "Deep progress tracking and trends")
                        PremiumFeatureRow(icon: "book.fill", title: "Unlimited Journaling", description: "Full reflection and journaling tools")
                    }
                    .padding(.horizontal, 24)

                    // Plans
                    VStack(spacing: 12) {
                        ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                            PlanCard(
                                plan: plan,
                                isSelected: selectedPlan == plan
                            ) {
                                selectedPlan = plan
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Subscribe Button
                    VStack(spacing: 12) {
                        PPButton(title: "Start Free Trial", style: .teal) {
                            subscriptionService.purchase(plan: selectedPlan)
                            dismiss()
                        }

                        Text("7-day free trial, then \(selectedPlan.price)")
                            .font(PickleProTypography.caption)
                            .foregroundColor(PickleProColors.textTertiary)

                        Text("Cancel anytime. No commitment.")
                            .font(PickleProTypography.caption)
                            .foregroundColor(PickleProColors.textTertiary)
                    }
                    .padding(.horizontal, 24)

                    // Legal
                    HStack(spacing: 16) {
                        Button("Terms") {}
                            .font(PickleProTypography.caption)
                            .foregroundColor(PickleProColors.textTertiary)
                        Button("Privacy") {}
                            .font(PickleProTypography.caption)
                            .foregroundColor(PickleProColors.textTertiary)
                        Button("Restore") {
                            subscriptionService.restorePurchases()
                        }
                        .font(PickleProTypography.caption)
                        .foregroundColor(PickleProColors.textTertiary)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear { animate = true }
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(PickleProColors.accent)
                .frame(width: 36, height: 36)
                .background(PickleProColors.accent.opacity(0.15))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(PickleProTypography.headline)
                    .foregroundColor(.white)
                Text(description)
                    .font(PickleProTypography.caption)
                    .foregroundColor(PickleProColors.textSecondary)
            }

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(PickleProColors.accent)
        }
    }
}

struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.rawValue)
                            .font(PickleProTypography.headline)
                            .foregroundColor(.white)

                        if let savings = plan.savings {
                            Text(savings)
                                .font(PickleProTypography.captionBold)
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(PickleProColors.accent)
                                .cornerRadius(6)
                        }
                    }
                    Text(plan.description)
                        .font(PickleProTypography.caption)
                        .foregroundColor(PickleProColors.textSecondary)
                }

                Spacer()

                Text(plan.price)
                    .font(PickleProTypography.headline)
                    .foregroundColor(isSelected ? PickleProColors.accent : .white)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? PickleProColors.accent : PickleProColors.textTertiary)
            }
            .padding(18)
            .background(
                isSelected ? PickleProColors.accent.opacity(0.1) : PickleProColors.cardBackground
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? PickleProColors.accent : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
