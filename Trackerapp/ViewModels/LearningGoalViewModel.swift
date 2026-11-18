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
    var showsWelcomeHeader: Bool { mode == .onboarding }
    var showsStartButton: Bool { mode == .onboarding }
    var navigationTitle: String { "Learning Goal" }

    var trimmedTopic: String { topic.trimmingCharacters(in: .whitespacesAndNewlines) }
    var canSubmit: Bool { !trimmedTopic.isEmpty }

    // MARK: - Actions
    func startLearning() { saveNewGoal() }

    func checkmarkTapped() {
        guard canSubmit else { return }
        isShowingUpdateAlert = true
    }

    func updateGoal() { saveNewGoal() }

    /// Ends the current goal (history is kept), discards its draft for today,
    /// and starts a new goal today.
    private func saveNewGoal() {
        guard canSubmit else { return }
        let now = Date.now
        let today = Calendar.current.startOfDay(for: now)

        let activeGoals = (try? context.fetch(
            FetchDescriptor<LearningGoal>(predicate: #Predicate { $0.endedAt == nil })
        )) ?? []

        for goal in activeGoals {
            let drafts = goal.records.filter { $0.calendarDay >= today }   // today's unfinished selection
            for draft in drafts { context.delete(draft) }
            goal.endedAt = now
        }

        context.insert(LearningGoal(topic: trimmedTopic,
                                    duration: duration,
                                    startDate: today))
        do { try context.save() } catch { print("Saving the goal failed: \(error)") }
    }
}
