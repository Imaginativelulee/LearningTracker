import SwiftUI
import SwiftData

enum Route: Hashable {
    case calendar
    case editGoal
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<LearningGoal> { $0.endedAt == nil },
           sort: \LearningGoal.startDate, order: .reverse)
    private var activeGoals: [LearningGoal]

    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let goal = activeGoals.first {
                    ActivityView(
                        viewModel: ActivityViewModel(goal: goal, context: modelContext),
                        onOpenCalendar: { path.append(.calendar) },
                        onEditGoal: { path.append(.editGoal) }
                    )
                    .id(goal.persistentModelID)   // a new goal gets a fresh screen
                } else {
                    LearningGoalView(viewModel: LearningGoalViewModel(mode: .onboarding, context: modelContext))
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .calendar:
                    CalendarView(viewModel: CalendarViewModel(context: modelContext))
                case .editGoal:
                    LearningGoalView(viewModel: LearningGoalViewModel(mode: .edit, context: modelContext))
                }
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [LearningGoal.self, ActivityRecord.self], inMemory: true)
}
