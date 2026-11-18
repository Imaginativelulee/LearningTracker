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
            header.padding(.horizontal, 14)
            weekStrip.padding(.horizontal, 6)
            statCards.padding(.horizontal, 14)

            switch viewModel.goalState {
            case .active: activeContent
            case .completed, .notMet: endedContent
            }
        }
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
            VStack(alignment: .leading, spacing: 4) {
                Text("Activity").font(.largeTitle.bold())
                Text(viewModel.dateTitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 14) {
                    CircleIconButton(title: "Calendar", systemImage: "calendar", action: onOpenCalendar)
                    CircleIconButton(title: "Edit goal", systemImage: "pencil.circle", action: onEditGoal)
                }
            }
        }
        .padding(.top, 5)
    }

    private var weekStrip: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.weekDays) { day in
                VStack(spacing: 8) {
                    Text(day.letter).font(.caption2.weight(.semibold))
                    DayCircle(number: day.number, status: day.status, isToday: day.isToday,
                              size: 39, font: .body)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 20)
    }

    private var statCards: some View {
        GlassEffectContainer(spacing: 14) {
            HStack(spacing: 14) {
                StatCard(systemImage: "flame.fill", color: .brandOrange,
                         value: viewModel.learnedText, label: "Learned")
                StatCard(systemImage: "snowflake", color: .brandCyan,
                         value: viewModel.freezedText, label: "Freezed")
            }
        }
        .padding(.top, 16)
    }

    private var activeContent: some View {
        VStack(spacing: 0) {
            Spacer()

            SolidActionButton(title: viewModel.logButtonTitle,
                              tint: .brandOrange,
                              isDisabled: viewModel.isLogDisabled,
                              shape: AnyShape(.circle),
                              size: CGSize(width: 272, height: 272),
                              action: viewModel.logAsLearned)

            Spacer()

            VStack(spacing: 12) {
                SolidActionButton(title: viewModel.freezeButtonTitle,
                                  tint: .brandCyan,
                                  isDisabled: viewModel.isFreezeDisabled,
                                  shape: AnyShape(.capsule),
                                  size: CGSize(width: 272, height: 46),
                                  action: viewModel.freezeToday)

                Text(viewModel.freezeUsageText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 46)
        }
    }

    private var endedContent: some View {
        VStack(spacing: 0) {
            Image(systemName: viewModel.goalState == .completed ? "hands.clap.fill" : "xmark.seal")
                .font(.system(size: 40))
                .foregroundStyle(Color.brandOrange)
                .padding(.top, 70)

            Text(viewModel.endedTitle)
                .font(.subheadline.weight(.semibold))
                .padding(.top, 27)

            Text(viewModel.endedSubtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 9)

            Button("Set a goal", systemImage: "pencil.circle", action: onEditGoal)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .tint(.brandOrange)
                .padding(.top, 75)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Small pieces used only by this screen

/// A solid-filled button (not glass). Dimmed gray when it can't be tapped.
private struct SolidActionButton: View {
    let title: String
    let tint: Color
    let isDisabled: Bool
    let shape: AnyShape
    let size: CGSize
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isDisabled ? Color.secondary : Color.white)
                .frame(width: size.width, height: size.height)
                .background(isDisabled ? Color(.systemGray6) : tint, in: shape)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!isDisabled)
    }
}

private struct CircleIconButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17))
                .foregroundStyle(.primary)
                .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(title)
    }
}

private struct StatCard: View {
    let systemImage: String
    let color: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(color)

            VStack(spacing: 3) {
                Text(value).font(.footnote.weight(.semibold))
                Text(label).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }
}
