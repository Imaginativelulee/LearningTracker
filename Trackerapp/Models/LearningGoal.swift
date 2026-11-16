import Foundation
import SwiftData

enum LearningDuration: String, CaseIterable, Codable {
    case week = "Week"
    case month = "Month"
    case year = "Year"

    var freezeAllowance: Int {
        switch self {
        case .week: 2
        case .month: 8
        case .year: 96
        }
    }

    /// The first day AFTER the goal ends, counted from the exact start date.
    func endDay(from start: Date, calendar: Calendar) -> Date {
        let (component, value): (Calendar.Component, Int) = switch self {
        case .week: (.day, 7)
        case .month: (.month, 1)
        case .year: (.year, 1)
        }
        return calendar.date(byAdding: component, value: value, to: start) ?? start
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
