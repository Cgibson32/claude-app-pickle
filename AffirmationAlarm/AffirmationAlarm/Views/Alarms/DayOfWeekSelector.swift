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
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 38, height: 38)
                        .background(
                            Circle()
                                .fill(selectedDays.contains(day.weekday)
                                      ? Color.white
                                      : Color.white.opacity(0.2))
                        )
                        .foregroundColor(selectedDays.contains(day.weekday) ? .black : .white)
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
