import Foundation
import Observation

@Observable
final class CalendarViewModel {

    struct Month: Identifiable {
        let id = UUID()
        let title: String
        let leadingBlanks: Int      // empty cells before day 1
        let dayCount: Int
        let statuses: [Int: DayStatus]   // day number -> status
        let todayNumber: Int?
    }

    let title = "Activities"
    let weekdaySymbols = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    let months: [Month]

    init(months: [Month] = CalendarViewModel.mockMonths) {
        self.months = months
    }

    // MARK: - Mock data (Phase 3 replaces this with stored records)
    private static func learned(_ days: ClosedRange<Int>) -> [Int: DayStatus] {
        Dictionary(uniqueKeysWithValues: days.map { ($0, DayStatus.learned) })
    }

    static let mockMonths: [Month] = [
        Month(title: "January 2026", leadingBlanks: 4, dayCount: 31,
              statuses: learned(1...11), todayNumber: nil),
        Month(title: "February 2026", leadingBlanks: 0, dayCount: 28,
              statuses: learned(1...28).merging([20: .freezed, 23: .freezed]) { _, new in new },
              todayNumber: nil),
        Month(title: "March 2026", leadingBlanks: 0, dayCount: 31,
              statuses: learned(1...2).merging([3: .freezed, 7: .freezed, 8: .freezed]) { _, new in new },
              todayNumber: 12)
    ]
}
