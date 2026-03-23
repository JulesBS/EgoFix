import SwiftUI

struct TodayView: View {
    @StateObject private var viewModel: TodayViewModel
    @ObservedObject var progressTracker: AppProgressTracker
    @State private var shareContent: ShareContent?
    @State private var showCrash = false
    @State private var navigationPath = NavigationPath()
    let makeCrashViewModel: (() -> CrashViewModel)?
    let makeHistoryViewModel: (() -> HistoryViewModel)?
    let makePatternsViewModel: (() -> PatternsViewModel)?
    let makeBugLibraryViewModel: (() -> BugLibraryViewModel)?

    init(
        viewModel: TodayViewModel,
        progressTracker: AppProgressTracker,
        makeCrashViewModel: (() -> CrashViewModel)? = nil,
        makeHistoryViewModel: (() -> HistoryViewModel)? = nil,
        makePatternsViewModel: (() -> PatternsViewModel)? = nil,
        makeBugLibraryViewModel: (() -> BugLibraryViewModel)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.progressTracker = progressTracker
        self.makeCrashViewModel = makeCrashViewModel
        self.makeHistoryViewModel = makeHistoryViewModel
        self.makePatternsViewModel = makePatternsViewModel
        self.makeBugLibraryViewModel = makeBugLibraryViewModel
    }

    /// Soul opacity varies by intensity to create subtle ambient breathing
    private var soulOpacity: Double {
        switch viewModel.currentIntensity {
        case .quiet: return 0.08
        case .present: return 0.12
        case .loud: return 0.18
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                EgoTheme.bg.ignoresSafeArea()

                // SOUL — ambient background layer
                BugSoulView(
                    slug: viewModel.currentBugSlug ?? "need-to-be-right",
                    intensity: viewModel.currentIntensity,
                    size: .large,
                    reaction: viewModel.soulReaction
                )
                .frame(height: 280)
                .opacity(soulOpacity)
                .blur(radius: 1)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // HEADER BAR
                        headerBar
                            .padding(.bottom, 4)

                        // Divider
                        Rectangle()
                            .fill(EgoTheme.greenSubtle)
                            .frame(height: 0.5)
                            .padding(.bottom, 24)
                            .accessibilityHidden(true)

                        // STATE LABEL
                        stateLabel
                            .padding(.bottom, 4)

                        // STATUS LINE
                        Text(viewModel.statusLine)
                            .font(EgoTheme.label())
                            .foregroundColor(EgoTheme.textMuted)
                            .padding(.bottom, 24)

                        // MAIN CONTENT — transitions between states
                        mainContent
                            .animation(.easeOut(duration: 0.25), value: viewModel.state.stateKey)

                        // CRASH BUTTON (briefing + active states)
                        if showCrashButton {
                            crashButton
                                .padding(.top, 24)
                        }

                        Spacer()
                            .frame(height: 32)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
            }

            // NAV BAR
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

    // MARK: - State Label

    private var stateLabelColor: Color {
        switch viewModel.state {
        case .checkIn: return EgoTheme.amber
        default: return EgoTheme.green
        }
    }

    private var stateLabel: some View {
        Text(stateLabelText)
            .font(EgoTheme.label())
            .tracking(2.2)
            .foregroundColor(stateLabelColor)
            .shadow(color: stateLabelColor.opacity(0.4), radius: 4)
    }

    private var stateLabelText: String {
        switch viewModel.state {
        case .loading: return "LOADING"
        case .diagnostic, .diagnosticComplete: return "WEEKLY_DIAGNOSTIC"
        case .noFix: return "NO_FIX"
        case .fixBriefing: return "TODAY'S_FIX"
        case .fixEducation: return "FIX_ACCEPTED"
        case .fixActive: return "FIX_ACTIVE"
        case .checkIn: return "FIX_REPORT"
        case .fixAvailable: return "FIX_AVAILABLE"
        case .completed(let outcome, _):
            switch outcome {
            case .applied: return "FIX_APPLIED"
            case .skipped: return "FIX_SKIPPED"
            case .failed: return "FIX_FAILED"
            case .pending: return "PENDING"
            }
        case .debrief: return "DEBRIEF"
        case .doneForToday: return "SYSTEM_STABLE"
        case .pattern: return "PATTERN_DETECTED"
        }
    }

    private var showCrashButton: Bool {
        switch viewModel.state {
        case .fixBriefing, .fixActive, .checkIn: return true
        default: return false
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            // Version (tap → settings)
            Button(action: { navigationPath.append(AppDestination.settings) }) {
                Text("v\(viewModel.currentVersion)")
                    .font(EgoTheme.label())
                    .tracking(1)
                    .foregroundColor(EgoTheme.green)
            }
            .accessibilityLabel("Settings, version \(viewModel.currentVersion)")
            .accessibilityHint("Opens settings")

            Spacer()

            // Status badge
            StatusBadge(text: statusBadgeText, color: statusBadgeColor)
                .accessibilityLabel("Status: \(statusBadgeText)")

            // Streak
            Text(StatusLineProvider.formatStreak(viewModel.currentStreak))
                .font(EgoTheme.label())
                .foregroundColor(EgoTheme.textMuted)
                .padding(.leading, 12)
                .accessibilityLabel("Streak: \(viewModel.currentStreak) days")
        }
    }

    private var statusBadgeText: String {
        switch viewModel.state {
        case .fixBriefing: return "PENDING"
        case .fixEducation: return "ACCEPTED"
        case .fixActive: return "ACTIVE"
        case .checkIn: return "REPORTING"
        case .completed(let outcome, _):
            switch outcome {
            case .applied: return "APPLIED"
            case .skipped: return "SKIPPED"
            case .failed: return "FAILED"
            case .pending: return "PENDING"
            }
        case .doneForToday: return "IDLE"
        default: return "SYS"
        }
    }

    private var statusBadgeColor: Color {
        switch viewModel.state {
        case .fixBriefing, .checkIn: return EgoTheme.amber
        case .fixEducation, .fixActive: return EgoTheme.green
        case .completed(let outcome, _):
            switch outcome {
            case .applied: return EgoTheme.green
            case .skipped: return EgoTheme.amber
            case .failed: return .red
            case .pending: return EgoTheme.textMuted
            }
        default: return EgoTheme.textMuted
        }
    }

    // MARK: - Crash Button (full-width, styled)

    private var crashButton: some View {
        Button(action: { showCrash = true }) {
            HStack {
                Spacer()
                Text("! CRASH")
                    .font(EgoTheme.mono(.callout))
                    .tracking(1.4)
                    .foregroundColor(.red)
                Spacer()
            }
            .padding(.vertical, 14)
            .background(EgoTheme.surface)
            .overlay(
                Rectangle()
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Log a crash")
        .accessibilityHint("Record an ego crash event")
    }

    // MARK: - Navigation Destinations

    @ViewBuilder
    private func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .history:
            if let makeVM = makeHistoryViewModel {
                HistoryView(viewModel: makeVM())
                    .terminalBackButton()
            }
        case .patterns:
            if let makeVM = makePatternsViewModel {
                PatternsView(viewModel: makeVM())
                    .terminalBackButton()
            }
        case .bugLibrary:
            if let makeVM = makeBugLibraryViewModel {
                BugLibraryView(viewModel: makeVM())
                    .terminalBackButton()
            }
        case .docs:
            if let makeVM = makeBugLibraryViewModel {
                DocsView(makeBugLibraryViewModel: makeVM)
                    .terminalBackButton()
            }
        case .settings:
            SettingsView(
                progressTracker: progressTracker
            )
            .terminalBackButton()
        case .soulDebug:
            SoulDebugView()
                .terminalBackButton()
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.state {
        case .loading:
            TerminalLoading()
                .padding(.top, 40)

        case .diagnostic:
            inlineDiagnosticContent
                .transition(.opacity)

        case .diagnosticComplete:
            inlineDiagnosticCompleteContent
                .transition(.opacity)

        case .noFix:
            NoFixView()

        case .fixBriefing(_, let fix):
            FixBriefingView(
                fix: fix,
                bugTitle: viewModel.currentBugTitle,
                onAccept: { Task { await viewModel.acceptFix() } },
                onSkip: { Task { await viewModel.markOutcome(.skipped) } }
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))

        case .fixEducation(_, let fix, let education):
            FixEducationView(
                fix: fix,
                bugTitle: viewModel.currentBugTitle,
                educationBody: education,
                onContinue: { viewModel.continuePastEducation() }
            )
            .transition(.opacity)

        case .fixActive(_, let fix):
            FixActiveView(
                fix: fix,
                bugTitle: viewModel.currentBugTitle,
                acceptedAt: viewModel.fixAcceptedAt,
                onCheckIn: { viewModel.beginCheckIn() },
                onCrash: { showCrash = true }
            )
            .transition(.opacity)

        case .checkIn(_, let fix):
            CheckInView(
                fix: fix,
                bugTitle: viewModel.currentBugTitle,
                interactionManager: viewModel.interactionManager,
                onApplied: { Task { await viewModel.markOutcome(.applied) } },
                onSkipped: { Task { await viewModel.markOutcome(.skipped) } },
                onFailed: { Task { await viewModel.markOutcome(.failed) } }
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))

        case .fixAvailable(_, let fix):
            FixCardView(
                fix: fix,
                bugTitle: viewModel.currentBugTitle,
                interactionManager: viewModel.interactionManager,
                onApplied: { Task { await viewModel.markOutcome(.applied) } },
                onSkipped: { Task { await viewModel.markOutcome(.skipped) } },
                onFailed: { Task { await viewModel.markOutcome(.failed) } }
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))

        case .completed(let outcome, let tidbit):
            InlineCompletionView(
                outcome: outcome,
                educationTidbit: tidbit,
                onAnimationComplete: {
                    viewModel.transitionToDone()
                }
            )
            .transition(.opacity)

        case .debrief(let content):
            DebriefView(
                content: content,
                onDismiss: { viewModel.dismissDebrief() },
                onShare: {
                    if let fix = viewModel.currentFix {
                        var text = fix.prompt
                        if let comment = fix.inlineComment { text += "\n\n// \(comment)" }
                        text += "\n\n\u{2014} EgoFix"
                        shareContent = ShareContent(text: text, fixId: fix.id)
                    }
                }
            )
            .transition(.opacity)

        case .doneForToday:
            doneForTodayContent
                .transition(.opacity)

        case .pattern(let pattern):
            PatternAlertView(
                pattern: pattern,
                onAcknowledge: { Task { await viewModel.acknowledgePattern(pattern.id) } },
                onDismiss: { Task { await viewModel.dismissPattern(pattern.id) } }
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Done-for-Today

    private var doneForTodayContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(viewModel.doneStatusLine)
                .font(EgoTheme.mono(.caption))
                .foregroundColor(EgoTheme.textMuted)

            if let summary = viewModel.weeklySummary {
                // Bento summary tiles
                HStack(spacing: 1) {
                    bentoTile(count: summary.applied, label: "APPLIED", color: EgoTheme.green)
                    bentoTile(count: summary.skipped, label: "SKIPPED", color: EgoTheme.amber)
                    bentoTile(count: summary.failed, label: "FAILED", color: .red)
                }
                .background(EgoTheme.borderSubtle)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Weekly summary: \(summary.applied) applied, \(summary.skipped) skipped, \(summary.failed) failed")

                Text(summary.comment)
                    .font(EgoTheme.label())
                    .foregroundColor(EgoTheme.textMuted)
            }

            // Progressive footer links
            if progressTracker.isHistoryUnlocked || progressTracker.isPatternsUnlocked || progressTracker.isBugLibraryUnlocked {
                FooterLinks(tracker: progressTracker) { destination in
                    navigationPath.append(destination)
                }
                .padding(.top, 8)
            }
        }
    }

    private func bentoTile(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 28, weight: .light, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(EgoTheme.label())
                .tracking(1)
                .foregroundColor(EgoTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(EgoTheme.bg)
    }

    // MARK: - Inline Diagnostic

    private var inlineDiagnosticContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let current = viewModel.currentDiagnosticBug {
                if viewModel.diagnosticNeedsContext {
                    Text("Where was it loudest?")
                        .font(EgoTheme.mono())
                        .foregroundColor(EgoTheme.textPrimary)

                    VStack(spacing: 8) {
                        diagnosticContextButton("Work", context: .work)
                        diagnosticContextButton("Home", context: .home)
                        diagnosticContextButton("Social", context: .social)
                        diagnosticContextButton("Family", context: .family)
                        diagnosticContextButton("Online", context: .online)
                        FigmaSecondaryButton(label: "UNSURE") {
                            viewModel.skipDiagnosticContext()
                        }
                    }
                } else {
                    Text("This week, \(current.bug.slug) was...")
                        .font(EgoTheme.mono())
                        .foregroundColor(EgoTheme.textPrimary)

                    VStack(spacing: 10) {
                        intensityButton(label: "QUIET", color: EgoTheme.green, action: { viewModel.setDiagnosticIntensity(.quiet) })
                        intensityButton(label: "PRESENT", color: EgoTheme.amber, action: { viewModel.setDiagnosticIntensity(.present) })
                        intensityButton(label: "LOUD", color: .red, action: { viewModel.setDiagnosticIntensity(.loud) })
                    }
                }

                if viewModel.diagnosticRemainingCount > 0 {
                    Text("// \(viewModel.diagnosticRemainingCount) more \(viewModel.diagnosticRemainingCount == 1 ? "bug" : "bugs") to check")
                        .font(EgoTheme.label())
                        .foregroundColor(EgoTheme.textMuted)
                        .padding(.top, 4)
                }
            }

            FigmaSecondaryButton(label: "SKIP") {
                Task { await viewModel.skipDiagnostic() }
            }
        }
        .animation(.easeOut(duration: 0.25), value: viewModel.diagnosticBugIndex)
    }

    private func diagnosticContextButton(_ label: String, context: EventContext) -> some View {
        Button(action: { viewModel.setDiagnosticContext(context) }) {
            Text(label)
                .font(EgoTheme.mono(.callout))
                .tracking(1.4)
                .foregroundColor(EgoTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(EgoTheme.surface)
                .overlay(Rectangle().stroke(EgoTheme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func intensityButton(label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(EgoTheme.mono(.callout))
                .tracking(2)
                .foregroundColor(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(EgoTheme.surface)
                .overlay(Rectangle().stroke(color.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var inlineDiagnosticCompleteContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.diagnosticResults, id: \.bugTitle) { result in
                    HStack {
                        Text(result.bugTitle)
                            .font(EgoTheme.mono(.caption))
                            .foregroundColor(EgoTheme.textPrimary)
                        Spacer()
                        Text(result.intensity.rawValue.uppercased())
                            .font(EgoTheme.label())
                            .tracking(1)
                            .foregroundColor(intensityColor(result.intensity))
                    }
                }
            }
            .padding(20)
            .glassCard()

            Text("// Data logged. Tomorrow's fix will account for this.")
                .font(EgoTheme.label())
                .foregroundColor(EgoTheme.textMuted)

            FigmaCTAButton(label: "CONTINUE", showArrow: true) {
                Task { await viewModel.continuePastDiagnostic() }
            }
        }
    }

    private func intensityColor(_ intensity: BugIntensity) -> Color {
        switch intensity {
        case .quiet: return EgoTheme.green
        case .present: return EgoTheme.amber
        case .loud: return .red
        }
    }

    // MARK: - Share

    private func generateShareContent(for fix: Fix) -> ShareContent {
        var text = fix.prompt
        if let comment = fix.inlineComment {
            text += "\n\n// \(comment)"
        }
        text += "\n\n\u{2014} EgoFix"
        return ShareContent(text: text, fixId: fix.id)
    }
}

// MARK: - Inline Completion View

struct InlineCompletionView: View {
    let outcome: FixOutcome
    var educationTidbit: String?
    var onAnimationComplete: (() -> Void)?

    @State private var appeared = false
    @State private var showMessage = false
    @State private var showEducation = false
    @State private var typedMessage = ""

    private var outcomeColor: Color {
        switch outcome {
        case .applied: return EgoTheme.green
        case .skipped: return EgoTheme.amber
        case .failed: return .red
        case .pending: return EgoTheme.textMuted
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 32)

            // Symbol
            Text(symbol)
                .font(.system(size: 48, design: .monospaced))
                .foregroundColor(outcomeColor)
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)
                .shadow(color: outcomeColor.opacity(0.5), radius: 8)
                .accessibilityHidden(true)

            // Title (tracked)
            Text(title)
                .font(EgoTheme.mono(.title2))
                .tracking(2)
                .foregroundColor(outcomeColor)
                .greenGlow()
                .padding(.top, 16)
                .opacity(appeared ? 1 : 0)
                .accessibilityLabel("Outcome: \(title)")

            // Typing message
            Text(typedMessage + (showMessage && typedMessage.count < message.count ? "_" : ""))
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
                .opacity(showMessage ? 1 : 0)

            // Education tidbit in glass card
            if let tidbit = educationTidbit {
                Text(tidbit)
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(EgoTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()
                    .padding(.top, 24)
                    .opacity(showEducation ? 1 : 0)
                    .offset(y: showEducation ? 0 : 10)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showMessage = true
                typeMessage()
            }
            withAnimation(.easeOut(duration: 0.4).delay(1.5)) {
                showEducation = true
            }
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
