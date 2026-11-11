import SwiftUI

struct CalendarView: View {
    @State private var viewModel = CalendarViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.months) { month in
                    MonthSection(month: month, weekdaySymbols: viewModel.weekdaySymbols)
                }
            }
            .padding(.horizontal, 16)
        }
        .background(Color(.systemBackground))
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MonthSection: View {
    let month: CalendarViewModel.Month
    let weekdaySymbols: [String]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(month.title)
                .font(.subheadline.weight(.semibold))

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                ForEach(0..<month.leadingBlanks, id: \.self) { _ in
                    Color.clear.frame(height: 36)
                }

                ForEach(1...month.dayCount, id: \.self) { day in
                    DayCircle(number: day,
                              status: month.statuses[day],
                              isToday: day == month.todayNumber)
                }
            }
        }
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) { Divider() }
    }
}

#Preview {
    NavigationStack {
        CalendarView()
    }
}
