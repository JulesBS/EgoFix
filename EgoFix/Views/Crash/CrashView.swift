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
            Color.black.ignoresSafeArea()
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
                        ForEach(Array(bugs.enumerated()), id: \.element.id) { index, bug in
                            Button(action: { onSelectBug(bug) }) {
                                HStack {
                                    Text(bug.nickname)
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
                            .opacity(index < visibleBugCount ? 1 : 0)
                            .offset(y: index < visibleBugCount ? 0 : 8)
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
                    .font(.system(.title2, design: .monospaced))
                    .foregroundColor(.red)

                // Soul appears instantly at loud intensity
                if let bug = bug {
                    BugSoulView(slug: bug.slug, intensity: .loud, size: .large)
                        .frame(height: 160)
                }

                if showContent {
                    Text(message)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.35))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()

                // Quick fix display
                if showContent, let fix = quickFix {
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

                if showContent {
                    Button(action: onDone) {
                        Text("[ Done ]")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.gray)
                            .padding()
                    }
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
