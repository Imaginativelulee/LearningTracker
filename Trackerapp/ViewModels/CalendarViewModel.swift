import Foundation
import SwiftData

struct CalendarViewModel {

    struct Day: Identifiable {
        let id: Date
        let number: Int
        let status: DayStatus?
        let isToday: Bool
    }

    struct Month: Identifiable {
        let id: Date                 // the first day of the month: stable and unique
        let title: String
        let leadingBlanks: Int       // empty cells before day 1
        let days: [Day]
    }

    let title = "Activities"
    let weekdaySymbols: [String]
    let months: [Month]
    let currentMonthID: Date?

    init(context: ModelContext, now: Date = .now) {
        let calendar = Calendar.current
        let goals = (try? context.fetch(FetchDescriptor<LearningGoal>())) ?? []
        let statuses = LearningRules.latestStatuses(from: context.allDayRecords(), calendar: calendar)

        let months = Self.makeMonths(goals: goals, statuses: statuses, now: now, calendar: calendar)

        self.weekdaySymbols = calendar.orderedSymbols(calendar.shortWeekdaySymbols).map { $0.uppercased() }
        self.months = months
        self.currentMonthID = months.first { calendar.isDate($0.id, equalTo: now, toGranularity: .month) }?.id
    }

    // MARK: - Building the months

    /// Every month from the earliest goal's start to the latest goal's last day (or today).
    private static func makeMonths(goals: [LearningGoal], statuses: [Date: DayStatus],
                                   now: Date, calendar: Calendar) -> [Month] {
        guard let earliest = goals.map(\.startDate).min() else { return [] }

        let lastGoalDays = goals.compactMap { lastDay(of: $0, calendar: calendar) }
        let last = max(lastGoalDays.max() ?? now, now)

        guard var cursor = calendar.dateInterval(of: .month, for: earliest)?.start,
              let lastMonth = calendar.dateInterval(of: .month, for: last)?.start else { return [] }

        var months: [Month] = []
        while cursor <= lastMonth {
            guard let month = makeMonth(startingAt: cursor, statuses: statuses, now: now, calendar: calendar)
            else { break }
            months.append(month)

            guard let next = calendar.date(byAdding: .month, value: 1, to: cursor) else { break }
            cursor = next
        }
        return months
    }

    /// One month: its title, how many blank cells come first, and its days.
    private static func makeMonth(startingAt first: Date, statuses: [Date: DayStatus],
                                  now: Date, calendar: Calendar) -> Month? {
        guard let dayNumbers = calendar.range(of: .day, in: .month, for: first) else { return nil }

        let days = dayNumbers.compactMap { number -> Day? in
            guard let date = calendar.date(byAdding: .day, value: number - 1, to: first) else { return nil }
            return Day(id: date,
                       number: number,
                       status: statuses[date],
                       isToday: calendar.isDate(date, inSameDayAs: now))
        }
        let blanks = (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7

        return Month(id: first,
                     title: first.formatted(.dateTime.month(.wide).year()),
                     leadingBlanks: blanks,
                     days: days)
    }

    /// The last day a goal covers (the day before its exclusive end day).
    private static func lastDay(of goal: LearningGoal, calendar: Calendar) -> Date? {
        let firstDay = calendar.startOfDay(for: goal.startDate)
        let endDay = goal.duration.endDay(from: firstDay, calendar: calendar)
        return calendar.date(byAdding: .day, value: -1, to: endDay)
    }
}
