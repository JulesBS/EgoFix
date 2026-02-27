import SwiftUI

struct TodayView: View {
    @StateObject private var viewModel: TodayViewModel
    @ObservedObject var progressTracker: AppProgressTracker
    @State private var shareContent: ShareContent?
    @State private var showCrash = false
    @State private var navigationPath = NavigationPath()
    let makeWeeklyDiagnosticViewModel: (() -> WeeklyDiagnosticViewModel)?
    let makeCrashViewModel: (() -> CrashViewModel)?
    let makeHistoryViewModel: (() -> HistoryViewModel)?
    let makePatternsViewModel: (() -> PatternsViewModel)?
    let makeBugLibraryViewModel: (() -> BugLibraryViewModel)?

    init(
        viewModel: TodayViewModel,
        progressTracker: AppProgressTracker,
        makeWeeklyDiagnosticViewModel: (() -> WeeklyDiagnosticViewModel)? = nil,
        makeCrashViewModel: (() -> CrashViewModel)? = nil,
        makeHistoryViewModel: (() -> HistoryViewModel)? = nil,
        makePatternsViewModel: (() -> PatternsViewModel)? = nil,
        makeBugLibraryViewModel: (() -> BugLibraryViewModel)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.progressTracker = progressTracker
        self.makeWeeklyDiagnosticViewModel = makeWeeklyDiagnosticViewModel
        self.makeCrashViewModel = makeCrashViewModel
        self.makeHistoryViewModel = makeHistoryViewModel
        self.makePatternsViewModel = makePatternsViewModel
        self.makeBugLibraryViewModel = makeBugLibraryViewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // HEADER BAR
                        headerBar
                            .padding(.bottom, 16)

                        // SOUL (hero)
                        BugSoulView(
                            slug: viewModel.currentBugSlug ?? "need-to-be-right",
                            intensity: viewModel.currentIntensity,
                            size: .large
                        )
                        .frame(height: 200)
                        .padding(.bottom, 8)

                        // STATUS LINE
                        Text(viewModel.statusLine)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gray)
                            .padding(.bottom, 24)

                        // MAIN CONTENT
                        mainContent

                        // CRASH BUTTON
                        crashButton
                            .padding(.top, 32)
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }

            // NAV BAR (appears after full nav unlock)
            if progressTracker.isFullNavUnlocked {
                AppNavBar(
                    activeDestination: nil,
                    isHistoryUnlocked: progressTracker.isHistoryUnlocked,
                    isPatternsUnlocked: progressTracker.isPatternsUnlocked,
                    onSelect: { dest in
                        if let dest {
                            navigationPath.append(dest)
                        }
                    }
                )
            }
        }
        .navigationDestination(for: AppDestination.self) { destination in
            destinationView(for: destination)
        }
        .task {
            await viewModel.loadHeaderData()
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
        .sheet(isPresented: $showCrash) {
            if let makeVM = makeCrashViewModel {
                CrashView(viewModel: makeVM())
            }
        }
        .sheet(item: $viewModel.weeklySummary) { summary in
            WeeklySummaryView(summary: summary, onDismiss: {
                viewModel.dismissWeeklySummary()
            })
        }
    }

    // MARK: - Navigation Destinations

    @ViewBuilder
    private func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .history:
            if let makeVM = makeHistoryViewModel {
                HistoryView(viewModel: makeVM())
            }
        case .patterns:
            if let makeVM = makePatternsViewModel {
                PatternsView(viewModel: makeVM())
            }
        case .bugLibrary:
            if let makeVM = makeBugLibraryViewModel {
                BugLibraryView(viewModel: makeVM())
            }
        case .docs:
            if let makeVM = makeBugLibraryViewModel {
                DocsView(makeBugLibraryViewModel: makeVM)
            }
        case .settings:
            SettingsView(
                progressTracker: progressTracker,
                bugRepository: nil
            )
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            // Version — left
            Text("v\(viewModel.currentVersion)")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.green)

            Spacer()

            // Streak — right
            VStack(alignment: .trailing, spacing: 2) {
                Text(StatusLineProvider.formatStreak(viewModel.currentStreak))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.gray)

                if let milestone = StatusLineProvider.streakMilestoneComment(for: viewModel.currentStreak) {
                    Text(milestone)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(Color(white: 0.3))
                }
            }
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .tint(.green)
                .padding(.top, 40)

        case .noFix:
            NoFixView()

        case .fixAvailable(_, let fix):
            FixCardView(
                fix: fix,
                bugTitle: viewModel.currentBugTitle,
                interactionManager: viewModel.interactionManager,
                onApplied: { Task { await viewModel.markOutcome(.applied) } },
                onSkipped: { Task { await viewModel.markOutcome(.skipped) } },
                onFailed: { Task { await viewModel.markOutcome(.failed) } }
            )

        case .completed(let outcome, let tidbit):
            InlineCompletionView(
                outcome: outcome,
                educationTidbit: tidbit,
                onAnimationComplete: {
                    viewModel.transitionToDone()
                }
            )

        case .doneForToday:
            doneForTodayContent

        case .pattern(let pattern):
            PatternAlertView(
                pattern: pattern,
                onAcknowledge: { Task { await viewModel.acknowledgePattern(pattern.id) } },
                onDismiss: { Task { await viewModel.dismissPattern(pattern.id) } }
            )
        }
    }

    // MARK: - Done-for-Today

    private var doneForTodayContent: some View {
        VStack(spacing: 24) {
            Text(viewModel.doneStatusLine)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.gray)

            if let summary = viewModel.weeklySummary {
                VStack(spacing: 8) {
                    HStack(spacing: 16) {
                        summaryPill(count: summary.applied, label: "applied", color: .green)
                        summaryPill(count: summary.skipped, label: "skipped", color: .yellow)
                        summaryPill(count: summary.failed, label: "failed", color: .red)
                    }

                    Text(summary.comment)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(Color(white: 0.3))
                }
                .padding(.top, 8)
            }

            // Progressive footer links
            if progressTracker.isHistoryUnlocked || progressTracker.isPatternsUnlocked || progressTracker.isBugLibraryUnlocked {
                FooterLinks(tracker: progressTracker) { destination in
                    navigationPath.append(destination)
                }
                .padding(.top, 16)
            }
        }
        .padding(.top, 24)
    }

    private func summaryPill(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(Color(white: 0.4))
        }
    }

    // MARK: - Crash Button

    private var crashButton: some View {
        Button(action: { showCrash = true }) {
            Text("[ ! ]")
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(2)
                .shadow(color: .red.opacity(0.5), radius: 5, x: 0, y: 0)
        }
    }

    // MARK: - Share

    private func generateShareContent(for fix: Fix) -> ShareContent {
        var text = fix.prompt

        if let comment = fix.inlineComment {
            text += "\n\n// \(comment)"
        }

        text += "\n\n— EgoFix"

        return ShareContent(text: text, fixId: fix.id)
    }
}

// MARK: - Inline Completion View

/// Outcome display rendered inline within the Today scroll.
/// Auto-transitions to done-for-today after animation completes.
struct InlineCompletionView: View {
    let outcome: FixOutcome
    var educationTidbit: String?
    var onAnimationComplete: (() -> Void)?

    @State private var appeared = false
    @State private var showMessage = false
    @State private var showEducation = false
    @State private var typedMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            // Status symbol
            Text(symbol)
                .font(.system(size: 48, design: .monospaced))
                .foregroundColor(titleColor)
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)
                .shadow(color: titleColor.opacity(0.5), radius: 8, x: 0, y: 0)

            Text(title)
                .font(.system(.title2, design: .monospaced))
                .foregroundColor(titleColor)
                .padding(.top, 16)
                .opacity(appeared ? 1 : 0)

            // Typing animation for message
            Text(typedMessage + (showMessage && typedMessage.count < message.count ? "_" : ""))
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
                .opacity(showMessage ? 1 : 0)

            // Micro-education tidbit
            if let tidbit = educationTidbit {
                Text(tidbit)
                    .font(.system(.callout, design: .monospaced))
                    .foregroundColor(Color(white: 0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .opacity(showEducation ? 1 : 0)
                    .offset(y: showEducation ? 0 : 10)
            }
        }
        .padding(.vertical, 32)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                appeared = true
            }

            // Start typing animation after symbol appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showMessage = true
                typeMessage()
            }

            withAnimation(.easeOut(duration: 0.4).delay(1.5)) {
                showEducation = true
            }

            // Auto-transition to done after animation completes (~3 seconds)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                onAnimationComplete?()
            }
        }
    }

    private func typeMessage() {
        let characters = Array(message)
        var currentIndex = 0

        func typeNextCharacter() {
            guard currentIndex < characters.count else { return }

            typedMessage.append(characters[currentIndex])
            currentIndex += 1

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                typeNextCharacter()
            }
        }

        typeNextCharacter()
    }

    private var symbol: String {
        switch outcome {
        case .applied: return "+"
        case .skipped: return "~"
        case .failed: return "x"
        case .pending: return "..."
        }
    }

    private var title: String {
        switch outcome {
        case .applied: return "FIX APPLIED"
        case .skipped: return "FIX SKIPPED"
        case .failed: return "FIX FAILED"
        case .pending: return "PENDING"
        }
    }

    private var titleColor: Color {
        switch outcome {
        case .applied: return .green
        case .skipped: return .yellow
        case .failed: return .red
        case .pending: return .gray
        }
    }

    private var message: String {
        switch outcome {
        case .applied: return "No fanfare. You did the thing."
        case .skipped: return "Noted. No judgment."
        case .failed: return "It happens. The bug won this round."
        case .pending: return ""
        }
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
