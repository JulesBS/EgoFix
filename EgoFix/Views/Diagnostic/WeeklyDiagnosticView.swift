import SwiftUI

struct WeeklyDiagnosticView: View {
    @StateObject private var viewModel: WeeklyDiagnosticViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: WeeklyDiagnosticViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

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
                        Text("[ Skip ]")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gray.opacity(0.6))
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
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)
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
            Text("[ \(label) ]")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(color)
                .padding()
                .frame(maxWidth: .infinity)
                .background(color.opacity(0.1))
                .cornerRadius(4)
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
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)

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
            Text("[ \(label) ]")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.gray)
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
                .font(.system(.headline, design: .monospaced))
                .foregroundColor(.green)

            Text("Data logged. Patterns emerge over time.")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Spacer()

            Button(action: onDismiss) {
                Text("[ Continue ]")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .padding()
    }
}
