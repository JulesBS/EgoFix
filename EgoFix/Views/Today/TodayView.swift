import SwiftUI

struct TodayView: View {
    @StateObject private var viewModel: TodayViewModel

    init(viewModel: TodayViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch viewModel.state {
            case .loading:
                ProgressView()
                    .tint(.green)

            case .noFix:
                NoFixView()

            case .fixAvailable(let completion, let fix):
                FixCardView(
                    fix: fix,
                    interactionManager: viewModel.interactionManager,
                    onApplied: { Task { await viewModel.markOutcome(.applied) } },
                    onSkipped: { Task { await viewModel.markOutcome(.skipped) } },
                    onFailed: { Task { await viewModel.markOutcome(.failed) } }
                )

            case .completed(let outcome, let tidbit):
                CompletionView(outcome: outcome, educationTidbit: tidbit)

            case .pattern(let pattern):
                PatternAlertView(
                    pattern: pattern,
                    onAcknowledge: { Task { await viewModel.acknowledgePattern(pattern.id) } },
                    onDismiss: { Task { await viewModel.dismissPattern(pattern.id) } }
                )
            }
        }
        .task {
            await viewModel.loadTodaysFix()
        }
    }
}
