import Foundation
import SwiftData

@Model
final class ActivityRecord {
    var calendarDay: Date     // midnight of the day this record belongs to
    var recordedAt: Date      // exact moment the button was last tapped
    var status: DayStatus
    var goal: LearningGoal?

    init(calendarDay: Date, recordedAt: Date, status: DayStatus, goal: LearningGoal) {
        self.calendarDay = calendarDay
        self.recordedAt = recordedAt
        self.status = status
        self.goal = goal
    }
}

extension DayRecord {
    /// Copies a stored record into the plain value the rules use.
    init(_ record: ActivityRecord) {
        self.init(day: record.calendarDay, recordedAt: record.recordedAt, status: record.status)
    }
}

extension ModelContext {
    /// Every saved record from every goal, as plain values the rules can use.
    func allDayRecords() -> [DayRecord] {
        let records = (try? fetch(FetchDescriptor<ActivityRecord>())) ?? []
        return records.map { DayRecord($0) }
    }
}
