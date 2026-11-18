import SwiftUI

struct LearningGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: LearningGoalViewModel

    init(viewModel: LearningGoalViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.isOnboarding { welcomeHeader }
            goalForm
            Spacer()
            if viewModel.isOnboarding { startFooter }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemBackground))
        .tint(.brandOrange)
        .navigationTitle("Learning Goal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(viewModel.isOnboarding ? .hidden : .visible, for: .navigationBar)
        .toolbar {
            if !viewModel.isOnboarding {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Update", systemImage: "checkmark") {
                        viewModel.checkmarkTapped()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.brandOrange)
                    .disabled(!viewModel.canSubmit)
                }
            }
        }
        .alert("Update goal", isPresented: $viewModel.isShowingUpdateAlert) {
            Button("Dismiss", role: .cancel) { }
            Button("Update") {
                viewModel.saveGoal()
                dismiss()
            }
        } message: {
            Text("If you update now, your streak will start over.")
        }
    }

    // MARK: - Pieces of the screen

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: 36))
                .foregroundStyle(.tint)
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
                .padding(.bottom, 56)

            Text("Hello \(Text("Learner").fontWeight(.bold))")
                .font(.system(size: 30, weight: .light))

            Text("This app will help you learn everyday!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var goalForm: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("I want to learn").font(.subheadline)

            TextField("Swift", text: $viewModel.topic)
                .font(.subheadline)
                .padding(.top, 16)

            Divider().padding(.top, 12)

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
            Button("Start Learning") { viewModel.saveGoal() }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .disabled(!viewModel.canSubmit)

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
        GlassEffectContainer(spacing: 12) {
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
                    }
                    .buttonStyle(.plain)
                    .glassEffect(
                        isSelected
                            ? .regular.tint(.brandOrange).interactive()
                            : .regular.interactive(),
                        in: .capsule
                    )
                }
            }
        }
    }
}
