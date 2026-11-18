import Foundation

/// A plain copy of one stored record, so the rules never touch SwiftData.
struct DayRecord: Equatable {
    let day: Date
    let recordedAt: Date
    let status: DayStatus
}

struct LearningRules {
    static let streakWindow: TimeInterval = 32 * 60 * 60

    enum Blocker { case notStarted, goalFinished, alreadySelected, allowanceExhausted }
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

    /// Whole calendar days between the first day and `date`.
    func dayOffset(of date: Date) -> Int {
        calendar.dateComponents([.day], from: firstDay, to: calendar.startOfDay(for: date)).day ?? 0
    }

    func isInGoal(_ date: Date) -> Bool {
        let offset = dayOffset(of: date)
        return offset >= 0 && offset < totalDays
    }

    // MARK: - Draft vs. finalized

    /// Today's record is a draft the user can still change.
    /// Every record from an earlier day is final.
    func finalizedRecords(now: Date) -> [DayRecord] {
        let today = calendar.startOfDay(for: now)
        return records.filter { calendar.startOfDay(for: $0.day) < today }
    }

    /// The status recorded on `date`, if any (for today, this is the draft).
    func recordedStatus(on date: Date) -> DayStatus? {
        records.first { calendar.isDate($0.day, inSameDayAs: date) }?.status
    }

    // MARK: - Counters (finalized only)

    func learnedCount(now: Date) -> Int {
        finalizedRecords(now: now).filter { $0.status == .learned }.count
    }

    func freezesUsed(now: Date) -> Int {
        finalizedRecords(now: now).filter { $0.status == .freezed }.count
    }

    // MARK: - Can the user select this status now?

    /// nil means "allowed". Switching between Learned and Freeze is allowed all day.
    func blocker(for status: DayStatus, now: Date) -> Blocker? {
        let offset = dayOffset(of: now)
        if offset < 0 { return .notStarted }
        if offset >= totalDays { return .goalFinished }
        if recordedStatus(on: now) == status { return .alreadySelected }
        if status == .freezed && freezesUsed(now: now) >= duration.freezeAllowance {
            return .allowanceExhausted
        }
        return nil
    }

    // MARK: - Result (only after the whole duration has ended)

    func goalState(now: Date) -> GoalState {
        guard dayOffset(of: now) >= totalDays else { return .active }

        let recordedDays = Set(finalizedRecords(now: now)
            .filter { isInGoal($0.day) }
            .map { calendar.startOfDay(for: $0.day) })

        let isComplete = recordedDays.count == totalDays
            && freezesUsed(now: now) <= duration.freezeAllowance
        return isComplete ? .completed : .notMet
    }

    // MARK: - Streak (exact 32 hours, finalized records only)

    func streak(now: Date) -> Int {
        let ordered = finalizedRecords(now: now).sorted { $0.recordedAt < $1.recordedAt }
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
