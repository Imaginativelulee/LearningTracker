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

    /// Ends the current goal (history is kept) and starts a new one today.
    private func saveNewGoal() {
        guard canSubmit else { return }
        let now = Date.now

        let activeGoals = (try? context.fetch(
            FetchDescriptor<LearningGoal>(predicate: #Predicate { $0.endedAt == nil })
        )) ?? []
        for goal in activeGoals { goal.endedAt = now }

        context.insert(LearningGoal(topic: trimmedTopic,
                                    duration: duration,
                                    startDate: Calendar.current.startOfDay(for: now)))
        do { try context.save() } catch { print("Saving the goal failed: \(error)") }
    }
}
