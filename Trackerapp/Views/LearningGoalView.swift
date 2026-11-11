import SwiftUI

struct LearningGoalView: View {
    @State private var viewModel: LearningGoalViewModel

    init(mode: LearningGoalViewModel.Mode = .onboarding) {
        _viewModel = State(initialValue: LearningGoalViewModel(mode: mode))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.showsWelcomeHeader {
                welcomeHeader
            }

            goalForm

            Spacer()

            if viewModel.showsStartButton {
                startFooter
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemBackground))
        .navigationTitle(viewModel.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.mode == .edit {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Update", systemImage: "checkmark") {
                        viewModel.checkmarkTapped()
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderedProminent)
                    .tint(Color.appOrange)
                }
            }
        }
        .alert("Update goal", isPresented: $viewModel.isShowingUpdateAlert) {
            Button("Dismiss", role: .cancel) { }
            Button("Update") { viewModel.updateGoal() }
        } message: {
            Text("If you update now, your streak will start over.")
        }
    }

    // MARK: - Pieces of the screen

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.appOrange)
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
                .padding(.bottom, 56)

            Text("Hello ").font(.system(size: 30, weight: .light))
                + Text("Learner").font(.system(size: 30, weight: .bold))

            Text("This app will help you learn everyday!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var goalForm: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("I want to learn")
                .font(.subheadline)

            TextField("Swift", text: $viewModel.topic)
                .font(.subheadline)
                .padding(.top, 16)

            Divider()
                .padding(.top, 12)

            Text("I want to learn it in a")
                .font(.subheadline)
                .padding(.top, 28)

            DurationPicker(selection: $viewModel.duration)
                .padding(.top, 16)
        }
        .padding(.top, 36)
    }

    private var startFooter: some View {
        VStack(spacing: 10) {
            Button {
                viewModel.startLearning()
            } label: {
                Text("Start Learning")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color.appOrange, in: .capsule)
            }
            .buttonStyle(.plain)

            Text("You can edit your desire later")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Week / Month / Year pills

private struct DurationPicker: View {
    @Binding var selection: LearningDuration

    var body: some View {
        HStack(spacing: 12) {
            ForEach(LearningDuration.allCases, id: \.self) { duration in
                let isSelected = duration == selection

                Button {
                    selection = duration
                } label: {
                    Text(duration.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(isSelected ? Color.white : Color.secondary)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 11)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(Color.appOrange.gradient)
                            } else {
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .overlay {
                                        Capsule()
                                            .strokeBorder(
                                                .primary.opacity(0.10),
                                                lineWidth: 1
                                            )
                                    }
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview("Onboarding") {
    LearningGoalView(mode: .onboarding)
}

#Preview("Edit") {
    NavigationStack {
        LearningGoalView(mode: .edit)
    }
}
