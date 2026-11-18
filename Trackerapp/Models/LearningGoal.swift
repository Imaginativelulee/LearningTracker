import Foundation
import SwiftData

enum LearningDuration: String, CaseIterable, Codable {
    case week = "Week"
    case month = "Month"
    case year = "Year"

    /// Total Freeze days for the whole goal. It never refills.
    var freezeAllowance: Int {
        switch self {
        case .week: 2
        case .month: 8
        case .year: 96
        }
    }

    /// The first day AFTER the goal ends, counted from the exact start date.
    func endDay(from start: Date, calendar: Calendar) -> Date {
        let end: Date? = switch self {
        case .week: calendar.date(byAdding: .day, value: 7, to: start)
        case .month: calendar.date(byAdding: .month, value: 1, to: start)
        case .year: calendar.date(byAdding: .year, value: 1, to: start)
        }
        return end ?? start
    }
}

@Model
final class LearningGoal {
    var topic: String
    var duration: LearningDuration
    var startDate: Date          // midnight of the day the goal was created
    var endedAt: Date?           // nil = this is the current goal

    @Relationship(inverse: \ActivityRecord.goal)
    var records: [ActivityRecord] = []

    init(topic: String, duration: LearningDuration, startDate: Date) {
        self.topic = topic
        self.duration = duration
        self.startDate = startDate
    }
}
