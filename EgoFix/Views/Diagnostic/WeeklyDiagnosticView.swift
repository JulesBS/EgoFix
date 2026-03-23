import SwiftUI

struct WeeklyDiagnosticView: View {
    @StateObject private var viewModel: WeeklyDiagnosticViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: WeeklyDiagnosticViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            EgoTheme.bg.ignoresSafeArea()

            if viewModel.isComplete {
                DiagnosticCompleteView(onDismiss: { dismiss() })
            } else if let currentBug = viewModel.currentBug {
                VStack(spacing: 32) {
                    // Progress indicator
                    HStack(spacing: 4) {
                        ForEach(0..<viewModel.bugs.count, id: \.self) { index in
                            Circle()
                                .fill(index <= viewModel.currentBugIndex ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }

                    Spacer()

                    if viewModel.needsContextQuestion {
                        ContextQuestionView(
                            bug: currentBug.bug,
                            onSelect: viewModel.setContext,
                            onSkip: viewModel.skipContext
                        )
                    } else {
                        IntensityQuestionView(
                            bug: currentBug.bug,
                            onSelect: viewModel.setIntensity
                        )
                    }

                    Spacer()

                    Button(action: { Task { await viewModel.skip() }; dismiss() }) {
                        Text("SKIP")
                            .font(EgoTheme.mono(.caption))
                            .foregroundColor(EgoTheme.textMuted)
                    }
                }
                .padding()
            }
        }
        .task {
            await viewModel.checkShouldPrompt()
        }
    }
}

struct IntensityQuestionView: View {
    let bug: Bug
    let onSelect: (BugIntensity) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("This week, \"\(bug.title)\" felt...")
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textPrimary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                IntensityButton(label: "Quiet", color: .green, action: { onSelect(.quiet) })
                IntensityButton(label: "Present", color: .yellow, action: { onSelect(.present) })
                IntensityButton(label: "Loud", color: .red, action: { onSelect(.loud) })
            }
        }
    }
}

struct IntensityButton: View {
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label.uppercased())
                .font(EgoTheme.mono())
                .foregroundColor(color)
                .padding()
                .frame(maxWidth: .infinity)
                .background(color.opacity(0.1))
                .cornerRadius(2)
        }
    }
}

struct ContextQuestionView: View {
    let bug: Bug
    let onSelect: (EventContext) -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Where was it loudest?")
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textPrimary)

            VStack(spacing: 8) {
                ContextButton(label: "Work", action: { onSelect(.work) })
                ContextButton(label: "Home", action: { onSelect(.home) })
                ContextButton(label: "Social", action: { onSelect(.social) })
                ContextButton(label: "Family", action: { onSelect(.family) })
                ContextButton(label: "Online", action: { onSelect(.online) })
                ContextButton(label: "Unsure", action: onSkip)
            }
        }
    }
}

struct ContextButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label.uppercased())
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textMuted)
                .padding(.vertical, 8)
        }
    }
}

struct DiagnosticCompleteView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("DIAGNOSTIC COMPLETE")
                .font(EgoTheme.mono(.headline))
                .foregroundColor(EgoTheme.green)

            Text("Data logged. Patterns emerge over time.")
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textMuted)
                .multilineTextAlignment(.center)

            Spacer()

            Button(action: onDismiss) {
                Text("CONTINUE")
                    .font(EgoTheme.mono())
                    .foregroundColor(EgoTheme.textMuted)
                    .padding()
            }
        }
        .padding()
    }
}
