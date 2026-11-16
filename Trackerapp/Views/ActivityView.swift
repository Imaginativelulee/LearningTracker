import SwiftUI

struct ActivityView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: ActivityViewModel

    let onOpenCalendar: () -> Void
    let onEditGoal: () -> Void

    init(viewModel: ActivityViewModel,
         onOpenCalendar: @escaping () -> Void,
         onEditGoal: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onOpenCalendar = onOpenCalendar
        self.onEditGoal = onEditGoal
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            weekStrip
            statCards

            switch viewModel.screenState {
            case .active: activeContent
            case .goalCompleted, .goalNotMet: endedContent
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .toolbarVisibility(.hidden, for: .navigationBar)
        .task { await viewModel.keepDayCurrent() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { viewModel.refresh() }
        }
    }

    // MARK: - Pieces

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Activity").font(.largeTitle.bold())
                Text(viewModel.dateTitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 12) {
                    CircleIconButton(title: "Calendar", systemImage: "calendar", action: onOpenCalendar)
                    CircleIconButton(title: "Edit goal", systemImage: "pencil.circle", action: onEditGoal)
                }
            }
        }
        .padding(.top, 8)
    }

    private var weekStrip: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.weekDays) { day in
                VStack(spacing: 8) {
                    Text(day.letter).font(.caption2.weight(.semibold))
                    DayCircle(number: day.number, status: day.status, isToday: day.isToday)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 20)
    }

    private var statCards: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(systemImage: "flame.fill", color: Color("AppOrange"),
                         value: viewModel.learnedText, label: "Learned")
                StatCard(systemImage: "snowflake", color: Color("AppCyan"),
                         value: viewModel.freezedText, label: "Freezed")
            }
        }
        .padding(.top, 20)
    }

    private var activeContent: some View {
        VStack(spacing: 0) {
            Spacer()

            Button {
                viewModel.logAsLearned()
            } label: {
                Text(viewModel.logButtonTitle)
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 250, height: 250)
            }
            .buttonStyle(.borderedProminent)       // solid fill, not glass
            .buttonBorderShape(.circle)
            .tint(Color("AppOrange"))
            .disabled(viewModel.isLogDisabled)

            Spacer()

            VStack(spacing: 10) {
                Button {
                    viewModel.freezeToday()
                } label: {
                    Text(viewModel.freezeButtonTitle)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)   // solid fill, not glass
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .tint(Color("AppCyan"))
                .disabled(viewModel.isFreezeDisabled)
                .frame(width: 270)

                Text(viewModel.freezeUsageText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 24)
        }
    }

    private var endedContent: some View {
        VStack(spacing: 8) {
            Spacer()

            Image(systemName: viewModel.screenState == .goalCompleted ? "hands.clap.fill" : "xmark.seal")
                .font(.system(size: 40))
                .foregroundStyle(Color("AppOrange"))
                .padding(.bottom, 8)

            Text(viewModel.endedTitle).font(.subheadline.weight(.semibold))
            Text(viewModel.endedSubtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Set a goal", systemImage: "pencil.circle", action: onEditGoal)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(Color("AppOrange"))
                .padding(.top, 16)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Small pieces used only by this screen

private struct CircleIconButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(title, systemImage: systemImage, action: action)
            .labelStyle(.iconOnly)
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
    }
}

private struct StatCard: View {
    let systemImage: String
    let color: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage).foregroundStyle(color)
            Text(value).font(.subheadline.weight(.semibold))
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
    }
}
