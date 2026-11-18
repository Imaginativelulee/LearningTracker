import Foundation
import Observation
import SwiftData

@Observable
final class ActivityViewModel {

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

    /// "The current moment". Changing it makes SwiftUI redraw the screen.
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

    var goalState: LearningRules.GoalState { rules.goalState(now: now) }

    var dateTitle: String { now.formatted(.dateTime.weekday(.wide).day().month(.wide)) }

    /// Today's temporary selection (nil if the user hasn't chosen yet).
    private var todayStatus: DayStatus? { rules.recordedStatus(on: now) }

    // Shown numbers = finalized days + today's selection (matches the design).
    // The rules themselves (allowance, streak, completion) use finalized days only.
    private var shownLearned: Int { rules.learnedCount(now: now) + (todayStatus == .learned ? 1 : 0) }
    private var shownFreezed: Int { rules.freezesUsed(now: now) + (todayStatus == .freezed ? 1 : 0) }

    var learnedText: String { daysText(shownLearned) }
    var freezedText: String { daysText(shownFreezed) }
    var freezeUsageText: String {
        "\(shownFreezed) out of \(goal.duration.freezeAllowance) Freezes used"
    }

    var logButtonTitle: String { todayStatus == .learned ? "Logged as Learned" : "Log as Learned" }
    var freezeButtonTitle: String { todayStatus == .freezed ? "Freezed for a day" : "Freeze for a day" }
    var isLogDisabled: Bool { rules.blocker(for: .learned, now: now) != nil }
    var isFreezeDisabled: Bool { rules.blocker(for: .freezed, now: now) != nil }

    var endedTitle: String {
        goalState == .completed ? "Well done!" : "You didn't reach your goal this time."
    }
    var endedSubtitle: String {
        goalState == .completed ? "Ready for your next goal?" : "Want to set another goal?"
    }

    /// The calendar week around today, using the real saved records.
    var weekDays: [StripDay] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return [] }
        let statuses = LearningRules.latestStatuses(from: context.allDayRecords(), calendar: calendar)
        let letters = calendar.orderedSymbols(calendar.veryShortWeekdaySymbols)

        return (0..<7).compactMap { offset -> StripDay? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: week.start) else { return nil }
            return StripDay(id: date,
                            letter: letters[offset],
                            number: calendar.component(.day, from: date),
                            status: statuses[date],
                            isToday: calendar.isDate(date, inSameDayAs: now))
        }
    }

    // MARK: - Actions

    func logAsLearned() { select(.learned) }
    func freezeToday() { select(.freezed) }

    /// Called when the app returns to the foreground.
    func refresh() { now = .now }

    /// Wakes up at every midnight so yesterday's selection locks and the new day starts clean.
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

    /// Sets today's selection. Changes the existing record instead of adding a second one.
    private func select(_ status: DayStatus) {
        let moment = Date.now
        defer { now = .now }   // refresh the screen when we leave, whether we saved or were blocked

        guard rules.blocker(for: status, now: moment) == nil else { return }

        if let draft = goal.records.first(where: { calendar.isDate($0.calendarDay, inSameDayAs: moment) }) {
            draft.status = status
            draft.recordedAt = moment
        } else {
            context.insert(ActivityRecord(calendarDay: calendar.startOfDay(for: moment),
                                          recordedAt: moment,
                                          status: status,
                                          goal: goal))
        }
        do { try context.save() } catch { print("Saving the selection failed: \(error)") }
    }

    private func daysText(_ count: Int) -> String { count == 1 ? "1 day" : "\(count) days" }
}
