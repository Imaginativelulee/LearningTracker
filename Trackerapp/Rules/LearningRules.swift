import Foundation

/// A plain copy of one stored record, so the rules never touch SwiftData.
struct DayRecord: Equatable {
    let day: Date
    let recordedAt: Date
    let status: DayStatus
}

struct LearningRules {
    static let streakWindow: TimeInterval = 32 * 60 * 60

    enum Blocker { case notStarted, goalFinished, alreadyRecorded, allowanceExhausted }
    enum GoalState { case active, completed, notMet }

    let duration: LearningDuration
    let startDate: Date
    let records: [DayRecord]
    var calendar: Calendar = .current

    // MARK: - Goal period

    var firstDay: Date { calendar.startOfDay(for: startDate) }
    var endDay: Date { duration.endDay(from: firstDay, calendar: calendar) }   // exclusive
    var totalDays: Int {
        calendar.dateComponents([.day], from: firstDay, to: endDay).day ?? 0
    }

    /// Whole calendar days between the start day and `date`.
    func dayOffset(of date: Date) -> Int {
        calendar.dateComponents([.day], from: firstDay, to: calendar.startOfDay(for: date)).day ?? 0
    }

    func isInGoal(_ date: Date) -> Bool {
        let offset = dayOffset(of: date)
        return offset >= 0 && offset < totalDays
    }

    // MARK: - Counters

    var learnedCount: Int { records.filter { $0.status == .learned }.count }
    var freezesUsed: Int { records.filter { $0.status == .freezed }.count }

    func recordedStatus(on date: Date) -> DayStatus? {
        records.first { calendar.isDate($0.day, inSameDayAs: date) }?.status
    }

    // MARK: - Can the user record now?

    /// nil means "allowed". Otherwise it says why not.
    func blocker(for status: DayStatus, now: Date) -> Blocker? {
        let offset = dayOffset(of: now)
        if offset < 0 { return .notStarted }
        if offset >= totalDays { return .goalFinished }
        if recordedStatus(on: now) != nil { return .alreadyRecorded }
        if status == .freezed && freezesUsed >= duration.freezeAllowance { return .allowanceExhausted }
        return nil
    }

    // MARK: - Result (only after the whole duration has ended)

    func goalState(now: Date) -> GoalState {
        guard dayOffset(of: now) >= totalDays else { return .active }
        let recordedDays = Set(records.filter { isInGoal($0.day) }
                                      .map { calendar.startOfDay(for: $0.day) })
        let isComplete = recordedDays.count == totalDays && freezesUsed <= duration.freezeAllowance
        return isComplete ? .completed : .notMet
    }

    // MARK: - Streak (exact 32 hours, based on timestamps, not calendar days)

    func streak(now: Date) -> Int {
        let ordered = records.sorted { $0.recordedAt < $1.recordedAt }
        guard let last = ordered.last,
              now.timeIntervalSince(last.recordedAt) <= Self.streakWindow else { return 0 }

        var count = 0
        var previous: Date?
        for record in ordered {
            if let previous, record.recordedAt.timeIntervalSince(previous) > Self.streakWindow {
                count = 1
            } else {
                count += 1
            }
            previous = record.recordedAt
        }
        return count
    }

    // MARK: - Shared by Activity strip and Calendar

    /// One status per day. If two goals recorded the same day, the latest record wins.
    static func latestStatuses(from records: [DayRecord], calendar: Calendar) -> [Date: DayStatus] {
        var latest: [Date: DayRecord] = [:]
        for record in records {
            let day = calendar.startOfDay(for: record.day)
            if let existing = latest[day], existing.recordedAt >= record.recordedAt { continue }
            latest[day] = record
        }
        return latest.mapValues(\.status)
    }
}

extension Calendar {
    /// Rotates 7 weekday symbols so the first one matches the user's first weekday.
    func orderedSymbols(_ symbols: [String]) -> [String] {
        guard symbols.count == 7 else { return symbols }
        let shift = firstWeekday - 1
        return Array(symbols[shift...] + symbols[..<shift])
    }
}
