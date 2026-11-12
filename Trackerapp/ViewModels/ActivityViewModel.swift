import Foundation
import Observation

@Observable
final class ActivityViewModel {

    enum ScreenState {
        case active
        case goalCompleted
        case goalNotMet
    }

    struct WeekDay: Identifiable {
        let id: Int
        let letter: String
        let number: Int
        let status: DayStatus?
        let isToday: Bool
    }

    // MARK: - State (mock values for the UI phase)
    var screenState: ScreenState
    var todayStatus: DayStatus?
    var learnedCount: Int
    var freezedCount: Int
    let freezeLimit: Int
    private let earlierStatuses: [DayStatus?]

    let dateTitle = "Friday, 25 October"   // mock; Phase 4 uses a real Date

    init(
        screenState: ScreenState = .active,
        todayStatus: DayStatus? = nil,
        learnedCount: Int = 4,
        freezedCount: Int = 0,
        freezeLimit: Int = 2,
        earlierStatuses: [DayStatus?] = [.learned, .learned, .learned, .learned]
    ) {
        self.screenState = screenState
        self.todayStatus = todayStatus
        self.learnedCount = learnedCount
        self.freezedCount = freezedCount
        self.freezeLimit = freezeLimit
        self.earlierStatuses = earlierStatuses
    }

    // MARK: - Presentation logic
    var weekDays: [WeekDay] {
        let letters = ["S", "M", "T", "W", "T", "F", "S"]
        let todayIndex = earlierStatuses.count

        return letters.indices.map { index -> WeekDay in
            let status: DayStatus?
            if index < todayIndex {
                status = earlierStatuses[index]
            } else if index == todayIndex {
                status = todayStatus
            } else {
                status = nil
            }
            return WeekDay(id: index, letter: letters[index], number: 20 + index,
                           status: status, isToday: index == todayIndex)
        }
    }

    var learnedText: String { daysText(learnedCount) }
    var freezedText: String { daysText(freezedCount) }
    var freezeUsageText: String { "\(freezedCount) out of \(freezeLimit) Freezes used" }

    var logButtonTitle: String { todayStatus == .learned ? "Logged as Learned" : "Log as Learned" }
    var isLogDisabled: Bool { todayStatus == .learned }

    var freezeButtonTitle: String { todayStatus == .freezed ? "Freezed for a day" : "Freeze for a day" }
    var isFreezeDisabled: Bool { todayStatus == .freezed || freezedCount >= freezeLimit }

    var endedTitle: String {
        screenState == .goalCompleted ? "Well done!" : "You didn't reach your goal this time."
    }
    var endedSubtitle: String {
        screenState == .goalCompleted ? "Ready for your next goal?" : "Want to set another goal?"
    }

    private func daysText(_ count: Int) -> String {
        count == 1 ? "1 day" : "\(count) days"
    }

    // MARK: - Actions
    func logAsLearned() { todayStatus = .learned }   // mock: Phase 4 adds the real rules
    func freezeToday() { todayStatus = .freezed }    // mock: Phase 4 adds the real rules
    func calendarTapped() { }                        // Phase 2: navigate
    func editGoalTapped() { }                        // Phase 2: navigate
    func setNewGoalTapped() { }                      // Phase 2: navigate
}
