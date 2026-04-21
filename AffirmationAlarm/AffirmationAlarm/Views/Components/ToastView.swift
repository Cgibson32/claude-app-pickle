import SwiftUI

/// Lightweight animated overlay that shows a brief confirmation after a
/// user action (save, add, etc.) and auto-dismisses after `duration`
/// seconds. Sits at the top of whatever view it's `.overlay`-ed onto.
///
/// Usage:
/// ```
/// .overlay(alignment: .top) {
///     ToastView(message: "Saved", icon: "checkmark.circle.fill", isPresented: $showToast)
/// }
/// ```
struct ToastView: View {
    let message: String
    var icon: String = "checkmark.circle.fill"
    @Binding var isPresented: Bool
    var duration: TimeInterval = 1.8

    var body: some View {
        if isPresented {
            HStack(spacing: AppTheme.spacingSm) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.gold)
                Text(message)
                    .font(AppTheme.subheadline)
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .padding(.horizontal, AppTheme.spacingLg)
            .padding(.vertical, AppTheme.spacingMd)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
            .transition(.move(edge: .top).combined(with: .opacity))
            .padding(.top, AppTheme.spacingLg)
            .onAppear {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(duration))
                    withAnimation(.easeOut(duration: 0.25)) {
                        isPresented = false
                    }
                }
            }
        }
    }
}
