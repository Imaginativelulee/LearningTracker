import Foundation
import Observation

@Observable
final class LearningGoalViewModel {

    enum Mode {
        case onboarding
        case edit
    }

    // MARK: - State (the View reads and writes these)
    let mode: Mode
    var topic: String
    var duration: LearningDuration
    var isShowingUpdateAlert = false

    // MARK: - Presentation logic (decisions the View asks about)
    var showsWelcomeHeader: Bool { mode == .onboarding }
    var showsStartButton: Bool { mode == .onboarding }
    var navigationTitle: String { "Learning Goal" }

    // MARK: - Init
    init(mode: Mode, goal: LearningGoal = LearningGoal(topic: "", duration: .week)) {
        self.mode = mode
        self.topic = goal.topic
        self.duration = goal.duration
    }

    // MARK: - Actions (the View calls these)
    func startLearning() {
        // Phase 2 will navigate to Activity. Phase 3 will save the goal.
    }

    func checkmarkTapped() {
        isShowingUpdateAlert = true
    }

    func updateGoal() {
        // Phase 4 will reset the streak and save the new goal.
    }
}
