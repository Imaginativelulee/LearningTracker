import SwiftUI

@main
struct LearningTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            LearningGoalView(mode: .onboarding)
        }
    }
}
