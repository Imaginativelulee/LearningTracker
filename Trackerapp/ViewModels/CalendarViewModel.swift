import Foundation
import Observation
import SwiftData

@Observable
final class CalendarViewModel {

    struct Day: Identifiable {
        let id: Date
        let number: Int
        let status: DayStatus?
        let isToday: Bool
    }

    struct Month: Identifiable {
        let id: Date                 // first day of the month, stable
        let title: String
        let leadingBlanks: Int
        let days: [Day]
    }

    let title = "Activities"
    let weekdaySymbols: [String]
    let months: [Month]
    let currentMonthID: Date?

    init(context: ModelContext, now: Date = .now) {
        let calendar = Calendar.current
        let goals = (try? context.fetch(FetchDescriptor<LearningGoal>())) ?? []
        let records = ((try? context.fetch(FetchDescriptor<ActivityRecord>())) ?? []).map { DayRecord($0) }

        weekdaySymbols = calendar.orderedSymbols(calendar.shortWeekdaySymbols).map { $0.uppercased() }
        months = Self.makeMonths(goals: goals, records: records, now: now, calendar: calendar)
        currentMonthID = months.first { calendar.isDate($0.id, equalTo: now, toGranularity: .month) }?.id
    }

    /// Every month from the earliest goal's start to the latest goal's last day.
    private static func makeMonths(goals: [LearningGoal], records: [DayRecord],
                                   now: Date, calendar: Calendar) -> [Month] {
        guard let earliest = goals.map(\.startDate).min() else { return [] }

        let lastDays = goals.compactMap { goal -> Date? in
            let rules = LearningRules(duration: goal.duration, startDate: goal.startDate,
                                      records: [], calendar: calendar)
            return calendar.date(byAdding: .day, value: -1, to: rules.endDay)
        }
        let last = max(lastDays.max() ?? now, now)
        let statuses = LearningRules.latestStatuses(from: records, calendar: calendar)

        guard var cursor = calendar.dateInterval(of: .month, for: earliest)?.start,
              let lastMonth = calendar.dateInterval(of: .month, for: last)?.start else { return [] }

        var months: [Month] = []
        while cursor <= lastMonth {
            guard let range = calendar.range(of: .day, in: .month, for: cursor) else { break }

            let days = range.compactMap { number -> Day? in
                guard let date = calendar.date(byAdding: .day, value: number - 1, to: cursor) else { return nil }
                return Day(id: date, number: number, status: statuses[date],
                           isToday: calendar.isDate(date, inSameDayAs: now))
            }
            let blanks = (calendar.component(.weekday, from: cursor) - calendar.firstWeekday + 7) % 7
            months.append(Month(id: cursor,
                                title: cursor.formatted(.dateTime.month(.wide).year()),
                                leadingBlanks: blanks,
                                days: days))

            guard let next = calendar.date(byAdding: .month, value: 1, to: cursor) else { break }
            cursor = next
        }
        return months
    }
}
