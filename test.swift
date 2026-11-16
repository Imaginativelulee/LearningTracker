import Testing
import Foundation
@testable import Trackerapp

struct LearningRulesTests {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    private func date(_ day: Int, _ hour: Int = 0, _ minute: Int = 0, month: Int = 3) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
    }

    private func record(_ day: Int, _ status: DayStatus = .learned) -> DayRecord {
        DayRecord(day: date(day), recordedAt: date(day, 9), status: status)
    }

    private func rules(_ duration: LearningDuration = .week, start: Date, records: [DayRecord] = []) -> LearningRules {
        LearningRules(duration: duration, startDate: start, records: records, calendar: calendar)
    }

    @Test func monthGoalStartedMidMonthEndsOneMonthLater() {
        let r = rules(.month, start: date(15, month: 11))
        #expect(r.endDay == date(15, month: 12))
        #expect(r.totalDays == 30)
    }

    @Test func thirdFreezeIsBlockedOnceAllowanceIsUsed() {
        let r = rules(start: date(4), records: [record(4, .freezed), record(5, .freezed)])
        #expect(r.blocker(for: .freezed, now: date(6, 9)) == .allowanceExhausted)
        #expect(r.blocker(for: .learned, now: date(6, 9)) == nil)
    }

    @Test func midnightUnlocksNewDayWithoutResettingStreak() {
        let late = DayRecord(day: date(4), recordedAt: date(4, 23), status: .learned)
        let r = rules(start: date(4), records: [late])
        #expect(r.blocker(for: .freezed, now: date(4, 23, 30)) == .alreadyRecorded)
        #expect(r.blocker(for: .freezed, now: date(5, 0, 5)) == nil)
        #expect(r.streak(now: date(5, 0, 5)) == 1)
    }

    @Test func streakSurvivesExactly32HoursButNotOneMinuteMore() {
        let r = rules(start: date(4), records: [DayRecord(day: date(4), recordedAt: date(4, 8), status: .learned)])
        #expect(r.streak(now: date(5, 16)) == 1)
        #expect(r.streak(now: date(5, 16, 1)) == 0)
    }

    @Test func resultIsHiddenUntilTheDurationEnds() {
        let r = rules(start: date(4), records: (4...9).map { record($0) })
        #expect(r.goalState(now: date(10)) == .active)
    }

    @Test func oneMissedDayMeansNotMet() {
        let r = rules(start: date(4), records: (4...9).map { record($0) })   // day 10 missing
        #expect(r.goalState(now: date(11)) == .notMet)
    }

    @Test func everyDayRecordedMeansCompleted() {
        let records = [record(4), record(5), record(6, .freezed), record(7), record(8), record(9, .freezed), record(10)]
        #expect(rules(start: date(4), records: records).goalState(now: date(11)) == .completed)
    }
}
