import SwiftUI
import SwiftData

@main
struct LearningTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [LearningGoal.self, ActivityRecord.self])
    }
}
