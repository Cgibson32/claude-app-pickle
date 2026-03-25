import SwiftUI

struct BreathingPromptView: View {
    @State private var isExpanded = false
    @State private var breathText = "Breathe in..."
    @State private var breathingTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: AppTheme.spacing3xl) {
            Text(breathText)
                .font(AppTheme.title3)
                .foregroundStyle(AppTheme.textSecondary)
                .animation(.easeInOut, value: breathText)

            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppTheme.gold.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: isExpanded ? 100 : 50
                        )
                    )
                    .frame(width: 200, height: 200)

                // Main circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.sunsetOrange, AppTheme.gold],
                            startPoint: isExpanded ? .topLeading : .bottomTrailing,
                            endPoint: isExpanded ? .bottomTrailing : .topLeading
                        )
                    )
                    .frame(width: isExpanded ? 120 : 60, height: isExpanded ? 120 : 60)

                Image(systemName: "heart.fill")
                    .font(.system(size: isExpanded ? 32 : 20))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .animation(.easeInOut(duration: 4), value: isExpanded)
        }
        .onAppear { startBreathingCycle() }
        .onDisappear { breathingTask?.cancel() }
    }

    private func startBreathingCycle() {
        breathingTask = Task { @MainActor in
            // Breathe in (4s)
            breathText = "Breathe in..."
            isExpanded = true
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }

            // Hold (2s)
            breathText = "Hold..."
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }

            // Breathe out (4s)
            breathText = "Breathe out..."
            isExpanded = false
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }

            // Second cycle
            breathText = "Breathe in..."
            isExpanded = true
        }
    }
}
