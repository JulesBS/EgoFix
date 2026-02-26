import SwiftUI

struct CrashView: View {
    @StateObject private var viewModel: CrashViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: CrashViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch viewModel.state {
            case .initial:
                CrashInitialView(onStart: viewModel.startCrashLog)

            case .selectBug:
                CrashBugSelectView(
                    bugs: viewModel.availableBugs,
                    selectedBug: viewModel.selectedBug,
                    note: $viewModel.note,
                    isLoading: viewModel.isLoading,
                    onSelectBug: viewModel.selectBug,
                    onConfirm: { Task { await viewModel.confirmCrash() } },
                    onCancel: viewModel.reset
                )

            case .crashed(let crash):
                CrashLoggedView(
                    crash: crash,
                    onReboot: { Task { await viewModel.reboot() } }
                )

            case .quickFix(_, let fix):
                QuickFixView(
                    fix: fix,
                    onDismiss: {
                        viewModel.reset()
                        dismiss()
                    }
                )
            }
        }
        .task {
            await viewModel.loadBugs()
        }
    }
}

struct CrashInitialView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                Text("!")
                    .font(.system(size: 64, design: .monospaced))
                    .foregroundColor(.red)

                Text("CRASH")
                    .font(.system(.title, design: .monospaced))
                    .foregroundColor(.red)
            }

            Text("Something resurfaced?")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.gray)

            Spacer()

            Button(action: onStart) {
                Text("[ Log Crash ]")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.red)
                    .padding()
            }

            Spacer()
        }
    }
}

struct CrashBugSelectView: View {
    let bugs: [Bug]
    let selectedBug: Bug?
    @Binding var note: String
    let isLoading: Bool
    let onSelectBug: (Bug) -> Void
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Button(action: onCancel) {
                Text("< Cancel")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.gray)
            }

            Text("CRASH LOGGED")
                .font(.system(.headline, design: .monospaced))
                .foregroundColor(.red)

            Text("What resurfaced?")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.gray)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(bugs, id: \.id) { bug in
                        Button(action: { onSelectBug(bug) }) {
                            HStack {
                                Text(selectedBug?.id == bug.id ? "[x]" : "[ ]")
                                    .foregroundColor(selectedBug?.id == bug.id ? .red : .gray)
                                Text(bug.title)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .font(.system(.body, design: .monospaced))
                            .padding(.vertical, 8)
                        }
                    }
                }
            }

            TextField("// Optional note", text: $note)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.gray)
                .textFieldStyle(.plain)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)

            Spacer()

            if isLoading {
                ProgressView()
                    .tint(.red)
            } else {
                Button(action: onConfirm) {
                    Text("[ Confirm Crash ]")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.red)
                        .padding()
                }
            }
        }
        .padding()
    }
}

struct CrashLoggedView: View {
    let crash: Crash
    let onReboot: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("CRASH LOGGED")
                .font(.system(.headline, design: .monospaced))
                .foregroundColor(.red)

            Text("It happens.")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.gray)

            Spacer()

            Button(action: onReboot) {
                Text("[ Reboot ]")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.yellow)
                    .padding()
            }

            Spacer()
        }
    }
}

struct QuickFixView: View {
    let fix: Fix
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("QUICK FIX")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.yellow)

            Text(fix.prompt)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()

            if let comment = fix.inlineComment {
                Text("// \(comment)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.6))
            }

            Spacer()

            Button(action: onDismiss) {
                Text("[ Noted ]")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .padding()
    }
}
