import Foundation
import Observation
import SwiftData

@Observable
final class ActivityViewModel {

    enum ScreenState { case active, goalCompleted, goalNotMet }

    struct StripDay: Identifiable {
        let id: Date
        let letter: String
        let number: Int
        let status: DayStatus?
        let isToday: Bool
    }

    private let goal: LearningGoal
    private let context: ModelContext
    private let calendar = Calendar.current

    /// "The current moment". Changing it makes SwiftUI redraw.
    private(set) var now: Date

    init(goal: LearningGoal, context: ModelContext, now: Date = .now) {
        self.goal = goal
        self.context = context
        self.now = now
    }

    private var rules: LearningRules {
        LearningRules(duration: goal.duration,
                      startDate: goal.startDate,
                      records: goal.records.map { DayRecord($0) },
                      calendar: calendar)
    }

    // MARK: - Presentation logic
    var screenState: ScreenState {
        switch rules.goalState(now: now) {
        case .active: .active
        case .completed: .goalCompleted
        case .notMet: .goalNotMet
        }
    }

    var dateTitle: String { now.formatted(.dateTime.weekday(.wide).day().month(.wide)) }

    var learnedText: String { daysText(rules.learnedCount) }
    var freezedText: String { daysText(rules.freezesUsed) }
    var freezeUsageText: String {
        "\(rules.freezesUsed) out of \(goal.duration.freezeAllowance) Freezes used"
    }

    private var todayStatus: DayStatus? { rules.recordedStatus(on: now) }

    var logButtonTitle: String { todayStatus == .learned ? "Logged as Learned" : "Log as Learned" }
    var freezeButtonTitle: String { todayStatus == .freezed ? "Freezed for a day" : "Freeze for a day" }
    var isLogDisabled: Bool { rules.blocker(for: .learned, now: now) != nil }
    var isFreezeDisabled: Bool { rules.blocker(for: .freezed, now: now) != nil }

    var endedTitle: String {
        screenState == .goalCompleted ? "Well done!" : "You didn't reach your goal this time."
    }
    var endedSubtitle: String {
        screenState == .goalCompleted ? "Ready for your next goal?" : "Want to set another goal?"
    }

    /// The calendar week around today, using the real saved records.
    var weekDays: [StripDay] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return [] }
        let records = ((try? context.fetch(FetchDescriptor<ActivityRecord>())) ?? []).map { DayRecord($0) }
        let statuses = LearningRules.latestStatuses(from: records, calendar: calendar)
        let letters = calendar.orderedSymbols(calendar.veryShortWeekdaySymbols)

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: week.start) else { return nil }
            return StripDay(id: date,
                            letter: letters[offset],
                            number: calendar.component(.day, from: date),
                            status: statuses[date],
                            isToday: calendar.isDate(date, inSameDayAs: now))
        }
    }

    // MARK: - Actions
    func logAsLearned() { record(.learned) }
    func freezeToday() { record(.freezed) }

    func refresh() { now = .now }

    /// Wakes up at every midnight so the buttons unlock on the new day.
    func keepDayCurrent() async {
        while !Task.isCancelled {
            now = .now
            guard let midnight = calendar.nextDate(after: now,
                                                   matching: DateComponents(hour: 0, minute: 0),
                                                   matchingPolicy: .nextTime) else { return }
            try? await Task.sleep(for: .seconds(midnight.timeIntervalSince(now) + 1))
        }
    }

    // MARK: - Private
    private func record(_ status: DayStatus) {
        let moment = Date.now
        now = moment
        guard rules.blocker(for: status, now: moment) == nil else { return }

        context.insert(ActivityRecord(calendarDay: calendar.startOfDay(for: moment),
                                      recordedAt: moment,
                                      status: status,
                                      goal: goal))
        do { try context.save() } catch { print("Saving the record failed: \(error)") }
        now = .now   // forces the screen to re-read the new record
    }

    private func daysText(_ count: Int) -> String { count == 1 ? "1 day" : "\(count) days" }
}
