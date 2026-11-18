import Foundation
import SwiftData

/// Today's TEMPORARY choice. Not history. Replaced whenever the user switches.
@Model
final class DailySelection {
    var calendarDay: Date      // midnight at the start of the day this choice belongs to
    var status: DayStatus
    var goal: LearningGoal?

    init(calendarDay: Date, status: DayStatus, goal: LearningGoal) {
        self.calendarDay = calendarDay
        self.status = status
        self.goal = goal
    }
}
