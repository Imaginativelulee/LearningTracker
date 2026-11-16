import SwiftUI

struct CalendarView: View {
    @State private var viewModel: CalendarViewModel

    init(viewModel: CalendarViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.months) { month in
                        MonthSection(month: month, weekdaySymbols: viewModel.weekdaySymbols)
                            .id(month.id)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onAppear {
                if let id = viewModel.currentMonthID { proxy.scrollTo(id, anchor: .top) }
            }
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
            Text(month.title).font(.subheadline.weight(.semibold))

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                ForEach(0..<month.leadingBlanks, id: \.self) { _ in
                    Color.clear.frame(height: 36)
                }
                ForEach(month.days) { day in
                    DayCircle(number: day.number, status: day.status, isToday: day.isToday)
                }
            }
        }
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) { Divider() }
    }
}
