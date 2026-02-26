import SwiftUI

struct TodayView: View {
    @StateObject private var viewModel: TodayViewModel
    @State private var shareContent: ShareContent?
    let makeWeeklyDiagnosticViewModel: (() -> WeeklyDiagnosticViewModel)?

    init(viewModel: TodayViewModel, makeWeeklyDiagnosticViewModel: (() -> WeeklyDiagnosticViewModel)? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makeWeeklyDiagnosticViewModel = makeWeeklyDiagnosticViewModel
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
                    bugTitle: viewModel.currentBugTitle,
                    interactionManager: viewModel.interactionManager,
                    onApplied: { Task { await viewModel.markOutcome(.applied) } },
                    onSkipped: { Task { await viewModel.markOutcome(.skipped) } },
                    onFailed: { Task { await viewModel.markOutcome(.failed) } },
                    onShare: { shareContent = generateShareContent(for: fix) }
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
            await viewModel.checkWeeklyDiagnostic()
            await viewModel.loadTodaysFix()
        }
        .sheet(item: $shareContent) { content in
            ShareSheet(items: [content.text])
        }
        .sheet(isPresented: $viewModel.showWeeklyDiagnostic, onDismiss: {
            Task { await viewModel.onDiagnosticComplete() }
        }) {
            if let makeVM = makeWeeklyDiagnosticViewModel {
                WeeklyDiagnosticView(viewModel: makeVM())
            }
        }
        .sheet(item: $viewModel.weeklySummary) { summary in
            WeeklySummaryView(summary: summary, onDismiss: {
                viewModel.dismissWeeklySummary()
            })
        }
    }

    private func generateShareContent(for fix: Fix) -> ShareContent {
        var text = fix.prompt

        if let comment = fix.inlineComment {
            text += "\n\n// \(comment)"
        }

        text += "\n\n— EgoFix"

        return ShareContent(text: text, fixId: fix.id)
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

extension ShareContent: Identifiable {
    var id: UUID { fixId }
}
