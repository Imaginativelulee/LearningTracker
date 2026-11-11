import Foundation

enum LearningDuration: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

struct LearningGoal {
    var topic: String
    var duration: LearningDuration
}
