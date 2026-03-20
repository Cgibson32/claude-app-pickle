import SwiftUI

struct PaywallView: View {
    var subscriptionManager = SubscriptionManager.shared
    @State private var appeared = false

    var body: some View {
        ZStack {
            GradientBackground(style: .sunrise)

            ScrollView {
                VStack(spacing: AppTheme.spacingXxl) {
                    Spacer()
                        .frame(height: AppTheme.spacing3xl)

                    // Sunrise icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [AppTheme.gold, AppTheme.sunsetOrange, .clear],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 100, height: 100)

                        Image(systemName: "sunrise.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(AppTheme.warmWhite)
                    }
                    .scaleEffect(appeared ? 1.0 : 0.6)
                    .opacity(appeared ? 1.0 : 0.0)

                    // Title & subtitle
                    VStack(spacing: AppTheme.spacingSm) {
                        Text("Unlock Your\nMorning Ritual")
                            .font(AppTheme.largeTitle)
                            .foregroundStyle(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Start your 7-day free trial")
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    // Benefits
                    VStack(spacing: AppTheme.spacingSm) {
                        BenefitRow(icon: "sparkles", text: "Personalized daily affirmations")
                        BenefitRow(icon: "alarm.fill", text: "Guided morning routines")
                        BenefitRow(icon: "moon.stars.fill", text: "Evening reflection journals")
                        BenefitRow(icon: "chart.line.uptrend.xyaxis", text: "Track your growth journey")
                    }

                    // Price card
                    VStack(spacing: AppTheme.spacingSm) {
                        Text("7 days free")
                            .font(AppTheme.title3)
                            .foregroundStyle(AppTheme.gold)

                        Text("then \(subscriptionManager.priceText)/month")
                            .font(AppTheme.bodyFont)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.spacingXl)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))

                    // Error message
                    if let error = subscriptionManager.purchaseError {
                        Text(error)
                            .font(AppTheme.caption)
                            .foregroundStyle(AppTheme.sunsetRed)
                            .multilineTextAlignment(.center)
                    }

                    // CTA button
                    Button {
                        HapticService.success()
                        Task { await subscriptionManager.purchase() }
                    } label: {
                        if subscriptionManager.isLoading {
                            ProgressView()
                                .tint(AppTheme.charcoalBlue)
                        } else {
                            Text("Start Free Trial")
                        }
                    }
                    .buttonStyle(PillButtonStyle(background: AppTheme.gold, foreground: AppTheme.charcoalBlue))
                    .disabled(subscriptionManager.isLoading)

                    // Restore purchases
                    Button {
                        Task { await subscriptionManager.restorePurchases() }
                    } label: {
                        Text("Restore Purchases")
                            .font(AppTheme.subheadline)
                            .foregroundStyle(AppTheme.textTertiary)
                    }

                    // Legal
                    Text("Cancel anytime. Subscription auto-renews.")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                        .multilineTextAlignment(.center)

                    Spacer()
                        .frame(height: AppTheme.spacingXl)
                }
                .padding(.horizontal, AppTheme.spacingXxl)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(AppTheme.bouncy) {
                appeared = true
            }
        }
    }
}

// MARK: - Benefit Row

private struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: AppTheme.spacingMd) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.gold)
                .frame(width: 28, height: 28)

            Text(text)
                .font(AppTheme.bodyFont)
                .foregroundStyle(AppTheme.textPrimary)

            Spacer()
        }
        .padding(AppTheme.spacingLg)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMd))
    }
}
