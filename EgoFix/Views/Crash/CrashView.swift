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
            case .selectBug:
                CrashBugSelectView(
                    bugs: viewModel.availableBugs,
                    note: $viewModel.note,
                    isLoading: viewModel.isLoading,
                    onSelectBug: { bug in
                        Task { await viewModel.selectAndLogCrash(bug) }
                    },
                    onCancel: { dismiss() }
                )

            case .crashed(_, let bug):
                CrashLoggedView(
                    bug: bug,
                    onQuickFix: nil,
                    onDone: {
                        viewModel.reset()
                        dismiss()
                    }
                )

            case .quickFix(_, let fix):
                CrashLoggedView(
                    bug: nil,
                    quickFix: fix,
                    onQuickFix: nil,
                    onDone: {
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

// MARK: - Bug Selection (Tap 1)

struct CrashBugSelectView: View {
    let bugs: [Bug]
    @Binding var note: String
    let isLoading: Bool
    let onSelectBug: (Bug) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("CRASH")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundColor(.red)

                Spacer()

                Button(action: onCancel) {
                    Text("[ x ]")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)
                }
            }

            if isLoading {
                Spacer()
                HStack {
                    Spacer()
                    Text("> loading...")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)
                    Spacer()
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(bugs, id: \.id) { bug in
                            Button(action: { onSelectBug(bug) }) {
                                HStack {
                                    Text(bug.nickname ?? bug.title)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(">")
                                        .foregroundColor(.gray.opacity(0.4))
                                }
                                .font(.system(.body, design: .monospaced))
                                .padding(.vertical, 12)
                                .padding(.horizontal, 8)
                                .background(Color(white: 0.08))
                                .cornerRadius(2)
                            }
                        }
                    }
                }

                TextField("// optional note", text: $note)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.gray)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)

                Spacer()
            }
        }
        .padding()
    }
}

// MARK: - Crash Logged (Tap 2)

struct CrashLoggedView: View {
    let bug: Bug?
    var quickFix: Fix? = nil
    let onQuickFix: (() -> Void)?
    let onDone: () -> Void

    @State private var appeared = false
    private let message = CrashViewModel.randomCrashMessage()

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("LOGGED.")
                .font(.system(.title2, design: .monospaced))
                .foregroundColor(.red)
                .opacity(appeared ? 1 : 0)

            // Soul animation at loud intensity
            if let bug = bug {
                BugSoulView(slug: bug.slug, intensity: .loud, size: .large)
                    .frame(height: 160)
                    .opacity(appeared ? 1 : 0)
            }

            Text(message)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(Color(white: 0.35))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)

            Spacer()

            // Quick fix display
            if let fix = quickFix {
                VStack(spacing: 8) {
                    Text("QUICK FIX")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.yellow)

                    Text(fix.prompt)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    if let comment = fix.inlineComment {
                        Text("// \(comment)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(Color(white: 0.35))
                    }
                }
                .padding(.bottom, 16)
            }

            Button(action: onDone) {
                Text("[ Done ]")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .padding()
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }
        }
    }
}
