import SwiftUI

struct DayOfWeekSelector: View {
    @Binding var selectedDays: Set<Int>

    private let days: [(symbol: String, weekday: Int)] = [
        ("S", 1), ("M", 2), ("T", 3), ("W", 4), ("T", 5), ("F", 6), ("S", 7)
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(days, id: \.weekday) { day in
                Button {
                    if selectedDays.contains(day.weekday) {
                        selectedDays.remove(day.weekday)
                    } else {
                        selectedDays.insert(day.weekday)
                    }
                } label: {
                    Text(day.symbol)
                        .font(AppTheme.subheadline)
                        .frame(width: 38, height: 38)
                        .background(
                            Circle()
                                .fill(selectedDays.contains(day.weekday)
                                      ? AppTheme.chipSelected
                                      : AppTheme.chipUnselected)
                        )
                        .foregroundColor(selectedDays.contains(day.weekday) ? AppTheme.chipTextSelected : AppTheme.chipTextUnselected)
                }
                .animation(.easeInOut(duration: 0.15), value: selectedDays.contains(day.weekday))
            }
        }
    }
}

#Preview {
    ZStack {
        GradientBackground()
        DayOfWeekSelector(selectedDays: .constant([2, 3, 4, 5, 6]))
    }
}
