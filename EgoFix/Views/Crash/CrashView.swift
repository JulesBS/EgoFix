import SwiftUI

struct CrashView: View {
    @StateObject private var viewModel: CrashViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: CrashViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            // Red-tinted black background
            EgoTheme.bg.ignoresSafeArea()
            Color.red.opacity(0.03).ignoresSafeArea()

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

    @State private var visibleBugCount = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("CRASH")
                    .font(EgoTheme.mono(.headline))
                    .foregroundColor(.red)

                Spacer()

                Button(action: onCancel) {
                    Text("[ x ]")
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textMuted)
                }
            }

            if isLoading {
                Spacer()
                HStack {
                    Spacer()
                    TerminalLoading()
                    Spacer()
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(bugs.enumerated()), id: \.element.id) { index, bug in
                            Button(action: { onSelectBug(bug) }) {
                                HStack {
                                    Text(bug.nickname)
                                        .foregroundColor(EgoTheme.textPrimary)
                                    Spacer()
                                    Text(">")
                                        .foregroundColor(EgoTheme.textMuted)
                                }
                                .font(EgoTheme.mono())
                                .padding(.vertical, 12)
                                .padding(.horizontal, 8)
                                .background(EgoTheme.surface)
                                .cornerRadius(2)
                            }
                            .opacity(index < visibleBugCount ? 1 : 0)
                            .offset(y: index < visibleBugCount ? 0 : 8)
                        }
                    }
                }

                TextField("// optional note", text: $note)
                    .font(EgoTheme.mono())
                    .foregroundColor(EgoTheme.textMuted)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(EgoTheme.surface)
                    .cornerRadius(2)

                Spacer()
            }
        }
        .padding()
        .onAppear {
            staggerBugList()
        }
    }

    private func staggerBugList() {
        for i in 0..<bugs.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                withAnimation(.easeOut(duration: 0.2)) {
                    visibleBugCount = i + 1
                }
            }
        }
    }
}

// MARK: - Crash Logged (Tap 2)

struct CrashLoggedView: View {
    let bug: Bug?
    var quickFix: Fix? = nil
    let onQuickFix: (() -> Void)?
    let onDone: () -> Void

    @State private var showContent = false
    @State private var flashOpacity: Double = 0.1
    private let message = CrashViewModel.randomCrashMessage()

    var body: some View {
        ZStack {
            // Red flash overlay
            Color.red.opacity(flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 24) {
                Spacer()

                Text("LOGGED.")
                    .font(EgoTheme.mono(.title2))
                    .foregroundColor(.red)

                // Soul appears instantly at loud intensity
                if let bug = bug {
                    BugSoulView(slug: bug.slug, intensity: .loud, size: .large)
                        .frame(height: 160)
                }

                if showContent {
                    Text(message)
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()

                // Quick fix display
                if showContent, let fix = quickFix {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("QUICK_FIX")
                            .font(EgoTheme.label())
                            .tracking(1.5)
                            .foregroundColor(EgoTheme.amber)

                        Text(fix.prompt)
                            .font(EgoTheme.mono())
                            .foregroundColor(EgoTheme.textPrimary)

                        if let comment = fix.inlineComment {
                            Text("// \(comment)")
                                .font(EgoTheme.mono(.caption))
                                .foregroundColor(EgoTheme.textMuted)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()
                    .padding(.horizontal, 8)
                }

                if showContent {
                    FigmaSecondaryButton(label: "DONE", action: onDone)
                        .padding(.horizontal, 8)
                }
            }
            .padding()
        }
        .onAppear {
            // Brief red flash (100ms on, then fade)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.3)) {
                    flashOpacity = 0
                }
            }
            // Show content after flash
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.25)) {
                    showContent = true
                }
            }
        }
    }
}
