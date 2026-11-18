import Foundation
import Observation
import SwiftData

@Observable
final class LearningGoalViewModel {

    enum Mode { case onboarding, edit }

    let mode: Mode
    var topic = ""
    var duration: LearningDuration = .week
    var isShowingUpdateAlert = false

    private let context: ModelContext

    init(mode: Mode, context: ModelContext) {
        self.mode = mode
        self.context = context
    }

    // MARK: - Presentation logic

    var isOnboarding: Bool { mode == .onboarding }

    private var trimmedTopic: String { topic.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// A goal needs at least one real character (spaces and new lines don't count).
    var canSubmit: Bool { !trimmedTopic.isEmpty }

    // MARK: - Actions

    func checkmarkTapped() {
        guard canSubmit else { return }
        isShowingUpdateAlert = true
    }

    /// Ends the current goal (its history is kept) and starts a new goal today.
    func saveGoal() {
        guard canSubmit else { return }
        let now = Date.now

        endActiveGoals(at: now)
        context.insert(LearningGoal(topic: trimmedTopic,
                                    duration: duration,
                                    startDate: Calendar.current.startOfDay(for: now)))
        do { try context.save() } catch { print("Saving the goal failed: \(error)") }
    }

    // MARK: - Private

    /// Marks every current goal as ended and discards its unfinished selection for today.
    private func endActiveGoals(at now: Date) {
        let today = Calendar.current.startOfDay(for: now)
        let activeGoals = (try? context.fetch(
            FetchDescriptor<LearningGoal>(predicate: #Predicate { $0.endedAt == nil })
        )) ?? []

        for goal in activeGoals {
            for draft in goal.records where draft.calendarDay >= today {
                context.delete(draft)
            }
            goal.endedAt = now
        }
    }
}
