import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userService: UserService
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var showPaywall = false
    @State private var showSavedLessons = false

    var body: some View {
        NavigationStack {
            ZStack {
                PickleProColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Header
                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(PickleProColors.accent.opacity(0.15))
                                    .frame(width: 90, height: 90)

                                Text(initials)
                                    .font(PickleProTypography.title)
                                    .foregroundColor(PickleProColors.accent)
                            }

                            Text(userService.profile.name.isEmpty ? "Player" : userService.profile.name)
                                .font(PickleProTypography.title2)
                                .foregroundColor(.white)

                            Text(userService.profile.experienceLevel.rawValue)
                                .font(PickleProTypography.subheadline)
                                .foregroundColor(PickleProColors.accent)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(PickleProColors.accent.opacity(0.15))
                                .cornerRadius(10)

                            if subscriptionService.isPremium {
                                Label("Premium Member", systemImage: "crown.fill")
                                    .font(PickleProTypography.captionBold)
                                    .foregroundColor(PickleProColors.gold)
                            }
                        }
                        .padding(.top, 16)

                        // Stats
                        HStack(spacing: 12) {
                            ProfileStatCard(
                                value: "\(userService.profile.streakDays)",
                                label: "Streak",
                                icon: "flame.fill"
                            )
                            ProfileStatCard(
                                value: "\(userService.profile.totalSessions)",
                                label: "Sessions",
                                icon: "figure.pickleball"
                            )
                            ProfileStatCard(
                                value: userService.profile.playFrequency.rawValue.components(separatedBy: " ").first ?? "",
                                label: "Per Week",
                                icon: "calendar"
                            )
                        }
                        .padding(.horizontal, 24)

                        // Goals
                        if !userService.profile.goals.isEmpty {
                            PPCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Label("My Goals", systemImage: "flag.fill")
                                        .font(PickleProTypography.headline)
                                        .foregroundColor(PickleProColors.accent)

                                    ForEach(userService.profile.goals, id: \.self) { goal in
                                        HStack(spacing: 10) {
                                            Image(systemName: "checkmark.circle")
                                                .foregroundColor(PickleProColors.accent)
                                                .font(.system(size: 14))
                                            Text(goal.rawValue)
                                                .font(PickleProTypography.callout)
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 24)
                        }

                        // Menu Items
                        VStack(spacing: 2) {
                            ProfileMenuItem(icon: "bookmark.fill", title: "Saved Lessons", color: PickleProColors.accent) {
                                showSavedLessons = true
                            }
                            ProfileMenuItem(icon: "gearshape.fill", title: "Preferences", color: PickleProColors.textSecondary) {}
                            ProfileMenuItem(icon: "bell.fill", title: "Notifications", color: PickleProColors.info) {}

                            if !subscriptionService.isPremium {
                                ProfileMenuItem(icon: "crown.fill", title: "Upgrade to Premium", color: PickleProColors.gold) {
                                    showPaywall = true
                                }
                            }

                            ProfileMenuItem(icon: "arrow.clockwise", title: "Restore Purchases", color: PickleProColors.teal) {
                                subscriptionService.restorePurchases()
                            }
                            ProfileMenuItem(icon: "questionmark.circle.fill", title: "Help & Support", color: PickleProColors.textSecondary) {}
                        }
                        .padding(.horizontal, 24)

                        // App Info
                        VStack(spacing: 8) {
                            HStack(spacing: 0) {
                                Text("Pickle")
                                    .font(PickleProTypography.headline)
                                    .foregroundColor(.white)
                                Text("Pro")
                                    .font(PickleProTypography.headline)
                                    .foregroundColor(PickleProColors.accent)
                            }
                            Text("Version 1.0.0")
                                .font(PickleProTypography.caption)
                                .foregroundColor(PickleProColors.textTertiary)
                        }
                        .padding(.top, 20)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var initials: String {
        let name = userService.profile.name
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

struct ProfileStatCard: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(PickleProColors.accent)

            Text(value)
                .font(PickleProTypography.title3)
                .foregroundColor(.white)

            Text(label)
                .font(PickleProTypography.caption)
                .foregroundColor(PickleProColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(PickleProColors.cardBackground)
        .cornerRadius(14)
    }
}

struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                    .frame(width: 28)

                Text(title)
                    .font(PickleProTypography.callout)
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(PickleProColors.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(PickleProColors.cardBackground)
            .cornerRadius(12)
        }
    }
}
