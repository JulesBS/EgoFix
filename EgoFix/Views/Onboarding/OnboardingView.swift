import SwiftUI

// MARK: - Main Onboarding View

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    init(viewModel: OnboardingViewModel, onComplete: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onComplete = onComplete
    }

    @State private var soulRenderer: OnboardingSoulRenderer?
    @State private var rendererFailed = false

    var body: some View {
        ZStack {
            EgoTheme.bg.ignoresSafeArea()

            switch viewModel.phase {
            case .awakening:
                AwakeningPhaseView(
                    soulRenderer: $soulRenderer,
                    rendererFailed: $rendererFailed,
                    onBeginScan: {
                        viewModel.beginScenarios()
                    }
                )
                .transition(.opacity)

            case .scenario(let index):
                if let scenario = viewModel.currentScenario {
                    ScenarioPhaseView(
                        scenario: scenario,
                        scenarioIndex: index,
                        totalScenarios: viewModel.scenarios.count,
                        onSelect: { optionId in
                            if let option = scenario.options.first(where: { $0.id == optionId }) {
                                let indices = viewModel.cubeIndicesForOption(option)
                                soulRenderer?.animator.setCubeFlickerTarget(indices: indices, color: 1)
                            }
                            viewModel.selectScenarioOption(optionId, forScenario: index)
                        },
                        onBack: index > 0 ? { viewModel.goBackToScenario(index - 1) } : nil
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
                } else {
                    // Fallback: scenario missing — skip to reveal to avoid soft-lock
                    Color.clear.onAppear {
                        viewModel.skipToReveal()
                    }
                }

            case .reframe(let index):
                if let reframe = viewModel.currentReframe {
                    ReframePhaseView(
                        text: reframe,
                        onComplete: {
                            viewModel.advanceFromReframe(index)
                        },
                        onTextComplete: {
                            soulRenderer?.animator.triggerAllGreenPulse()
                        }
                    )
                    .transition(.opacity)
                }

            case .reveal:
                BugRevealPhaseView(
                    viewModel: viewModel,
                    onCommit: {
                        if let r = soulRenderer {
                            r.animator.triggerMerge(scene: r.soulScene)
                        }
                        viewModel.phase = .committing
                        Task {
                            await viewModel.commitAndAssignFirstFix()
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))
                // Soul already split during awakening education — no trigger needed here

            case .committing:
                CommittingPhaseView(viewModel: viewModel)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.35), value: viewModel.phase)
        .task {
            await viewModel.loadBugs()
        }
        .onChange(of: viewModel.isComplete) { _, isComplete in
            if isComplete {
                onComplete()
            }
        }
    }
}

// MARK: - Phase 1: Awakening (Soul in ORBIT)

private struct AwakeningPhaseView: View {
    @Binding var soulRenderer: OnboardingSoulRenderer?
    @Binding var rendererFailed: Bool
    let onBeginScan: () -> Void

    @State private var currentLine = 0
    @State private var showButton = false
    @State private var glitchFlash: Double = 0
    @State private var buttonPulse = false

    private struct BootLine {
        let text: String
        let characterDelay: Double
        let postDelay: Double
        let style: LineStyle
        let glitchWord: String?
        let topPadding: CGFloat

        enum LineStyle { case terminal, narrative }
    }

    // The soul split triggers on the first line that glitches "bugs"
    private var splitTriggerLineIndex: Int {
        lines.firstIndex(where: { $0.glitchWord == "bugs" }) ?? lines.count - 1
    }

    private let lines: [BootLine] = [
        // Part 1: What ego IS — soul in ORBIT
        BootLine(text: "Your brain built a defense system", characterDelay: 0.035, postDelay: 0.15, style: .narrative, glitchWord: nil, topPadding: 0),
        BootLine(text: "before you were old enough to know it.", characterDelay: 0.035, postDelay: 0.6, style: .narrative, glitchWord: nil, topPadding: 0),

        // Part 2: What it learned — paired action/motivation
        BootLine(text: "It learned to correct people", characterDelay: 0.028, postDelay: 0.15, style: .narrative, glitchWord: nil, topPadding: 16),
        BootLine(text: "so you\u{2019}d never be wrong.", characterDelay: 0.028, postDelay: 0.3, style: .narrative, glitchWord: nil, topPadding: 0),
        BootLine(text: "To perform for rooms", characterDelay: 0.028, postDelay: 0.15, style: .narrative, glitchWord: nil, topPadding: 8),
        BootLine(text: "so you\u{2019}d never be ignored.", characterDelay: 0.028, postDelay: 0.3, style: .narrative, glitchWord: nil, topPadding: 0),
        BootLine(text: "To keep score against everyone", characterDelay: 0.028, postDelay: 0.15, style: .narrative, glitchWord: nil, topPadding: 8),
        BootLine(text: "so you\u{2019}d never fall behind.", characterDelay: 0.028, postDelay: 0.7, style: .narrative, glitchWord: nil, topPadding: 0),

        // Part 3: The problem — legacy system on autopilot
        BootLine(text: "It kept you safe. Now it runs on", characterDelay: 0.030, postDelay: 0.15, style: .narrative, glitchWord: nil, topPadding: 16),
        BootLine(text: "autopilot \u{2014} firing when it shouldn\u{2019}t,", characterDelay: 0.030, postDelay: 0.15, style: .narrative, glitchWord: nil, topPadding: 0),
        BootLine(text: "protecting you from threats that", characterDelay: 0.030, postDelay: 0.15, style: .narrative, glitchWord: nil, topPadding: 0),
        BootLine(text: "aren\u{2019}t there.", characterDelay: 0.030, postDelay: 0.6, style: .narrative, glitchWord: nil, topPadding: 0),

        // Part 4: The naming — "bugs" glitches, soul SPLITS
        BootLine(text: "These automatic responses are bugs.", characterDelay: 0.035, postDelay: 0.3, style: .narrative, glitchWord: "bugs", topPadding: 16),

        // Part 5: The purpose — types WHILE split is happening
        BootLine(text: "This app finds them, and gives you", characterDelay: 0.035, postDelay: 0.15, style: .narrative, glitchWord: nil, topPadding: 8),
        BootLine(text: "daily fixes to take back control.", characterDelay: 0.040, postDelay: 0.0, style: .narrative, glitchWord: nil, topPadding: 0),
    ]

    var body: some View {
        ZStack {
            // CRT scanline effect
            ScanlineOverlay()
                .ignoresSafeArea()

            // Green flash on "bugs" glitch
            EgoTheme.green.opacity(glitchFlash)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                // 3D ASCII soul animation — matches BootSequenceView sizing
                GeometryReader { geo in
                    let size = min(geo.size.width - 48, 280)
                    OnboardingSoulView(
                        onRendererReady: { r in soulRenderer = r },
                        onRendererFailed: { rendererFailed = true }
                    )
                    .frame(width: size, height: size)
                    .cornerBrackets()
                    .frame(maxWidth: .infinity)
                }
                .aspectRatio(1, contentMode: .fit)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Scrollable text + button area
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(0..<min(currentLine + 1, lines.count), id: \.self) { index in
                            let line = lines[index]
                            if index < currentLine {
                                completedLineView(line)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            } else if index == currentLine {
                                activeLineView(line, index: index)
                            }
                        }

                        if showButton {
                            FigmaCTAButton(label: "BEGIN SCAN", action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                onBeginScan()
                            })
                            .overlay(
                                Rectangle()
                                    .stroke(EgoTheme.green.opacity(buttonPulse ? 0.6 : 0.3), lineWidth: 1)
                                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: buttonPulse)
                            )
                            .padding(.top, 26)
                            .transition(.opacity)
                            .onAppear {
                                buttonPulse = true
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                }
            }
        }
        .onAppear {
            currentLine = 0
        }
    }

    // MARK: Line rendering

    private func lineColor(_ line: BootLine) -> Color {
        if line.style == .terminal { return EgoTheme.green }
        // "so you'd..." motivation lines render dimmer — the ego's quiet justifications
        if line.text.hasPrefix("so you") || line.text.hasPrefix("aren") {
            return EgoTheme.textMuted
        }
        return EgoTheme.textPrimary
    }

    private func completedLineView(_ line: BootLine) -> some View {
        Group {
            if line.style == .terminal {
                Text(line.text)
                    .font(EgoTheme.mono())
                    .foregroundColor(EgoTheme.green)
            } else {
                Text(line.text)
                    .font(EgoTheme.mono())
                    .foregroundColor(EgoTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, line.topPadding)
    }

    @ViewBuilder
    private func activeLineView(_ line: BootLine, index: Int) -> some View {
        if let glitchWord = line.glitchWord {
            GlitchTypewriterLine(
                text: line.text,
                glitchWord: glitchWord,
                characterDelay: line.characterDelay,
                color: lineColor(line),
                onComplete: { advanceToNext(index) }
            )
            .padding(.top, line.topPadding)
        } else {
            TypewriterText(
                text: line.text,
                characterDelay: line.characterDelay,
                color: lineColor(line),
                onComplete: { advanceToNext(index) }
            )
            .padding(.top, line.topPadding)
        }
    }

    private func advanceToNext(_ index: Int) {
        // Trigger soul split + screen flash when "bugs" line completes
        if index == splitTriggerLineIndex {
            if let r = soulRenderer {
                r.animator.triggerSplit(scene: r.soulScene)
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            glitchFlash = 0.08
            withAnimation(.easeOut(duration: 0.4)) {
                glitchFlash = 0
            }
        }

        let postDelay = lines[index].postDelay
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(postDelay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            if index + 1 < lines.count {
                currentLine = index + 1
            } else {
                // Let the final line breathe before showing CTA
                try? await Task.sleep(nanoseconds: 800_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.easeIn(duration: 0.5)) {
                    showButton = true
                }
            }
        }
    }

}

// MARK: - Phase 2a: Scenario

private struct ScenarioPhaseView: View {
    let scenario: OnboardingScenario
    let scenarioIndex: Int
    let totalScenarios: Int
    let onSelect: (String) -> Void
    var onBack: (() -> Void)? = nil

    @State private var showSituation = false
    @State private var revealedOptions: Int = 0
    @State private var situationComplete = false
    @State private var cardAppeared = false
    @State private var selectedOptionId: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Progress indicator with optional back
            HStack {
                if let onBack {
                    Button(action: onBack) {
                        Text("[ back ]")
                            .font(EgoTheme.mono(.caption))
                            .foregroundColor(EgoTheme.textMuted)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Go back")
                    .accessibilityHint("Return to previous scenario")
                }
                Spacer()
                Text("\(scenarioIndex + 1) / \(totalScenarios)")
                    .font(EgoTheme.label())
                    .foregroundColor(EgoTheme.textMuted)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            Spacer()

            // Progress label (Figma: green tracked uppercase)
            Text("SCENARIO_0\(scenarioIndex + 1)")
                .font(EgoTheme.label())
                .tracking(2.2)
                .foregroundColor(EgoTheme.green)
                .greenGlow()
                .padding(.bottom, 20)

            // Situation inside glass card — slides up on entrance
            if showSituation {
                VStack(alignment: .leading, spacing: 0) {
                    TypewriterText(
                        text: scenario.situation,
                        characterDelay: 0.028,
                        color: EgoTheme.textPrimary,
                        font: .system(size: 18, weight: .light, design: .monospaced),
                        onComplete: {
                            situationComplete = true
                            revealOptions()
                        }
                    )
                }
                .padding(24)
                .glassCard()
                .padding(.bottom, 24)
                .offset(y: cardAppeared ? 0 : 20)
                .opacity(cardAppeared ? 1 : 0)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.3)) {
                        cardAppeared = true
                    }
                }
            }

            // Options (staggered reveal)
            if situationComplete {
                VStack(spacing: 10) {
                    ForEach(Array(scenario.options.enumerated()), id: \.element.id) { index, option in
                        if index < revealedOptions {
                            let isSelected = selectedOptionId == option.id
                            let isFaded = selectedOptionId != nil && !isSelected
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selectedOptionId = option.id
                                // Brief delay to show selection before advancing
                                Task { @MainActor in
                                    try? await Task.sleep(nanoseconds: 300_000_000)
                                    onSelect(option.id)
                                }
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Text(option.id.uppercased())
                                        .font(EgoTheme.mono(.caption))
                                        .foregroundColor(EgoTheme.green)
                                        .greenGlow()
                                        .frame(width: 16)

                                    Text(option.text)
                                        .font(EgoTheme.mono())
                                        .foregroundColor(EgoTheme.textPrimary)
                                        .multilineTextAlignment(.leading)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(isSelected ? EgoTheme.green.opacity(0.04) : .clear)
                                .overlay(
                                    Rectangle()
                                        .stroke(isSelected ? EgoTheme.green.opacity(0.4) : EgoTheme.border, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(selectedOptionId != nil)
                            .opacity(isFaded ? 0.3 : 1)
                            .animation(.easeOut(duration: 0.2), value: selectedOptionId)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                }
            }

            Spacer()
                .frame(height: 80)
        }
        .padding(.horizontal, 24)
        .onAppear {
            showSituation = true
        }
    }

    private func revealOptions() {
        Task { @MainActor in
            for i in 0..<scenario.options.count {
                try? await Task.sleep(nanoseconds: UInt64(0.15 * 1_000_000_000))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.3)) {
                    revealedOptions = i + 1
                }
            }
        }
    }
}

// MARK: - Phase 2b: Reframe

private struct ReframePhaseView: View {
    let text: String
    let onComplete: () -> Void
    let onTextComplete: () -> Void

    @State private var textFinished = false
    @State private var showTapHint = false
    @State private var autoAdvanceTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Position at ~40% from top, not centered
            Spacer().frame(maxHeight: .infinity)

            // // prefix in muted, reframe in green
            HStack(alignment: .top, spacing: 0) {
                Text("// ")
                    .font(.system(size: 16, weight: .regular, design: .monospaced))
                    .foregroundColor(EgoTheme.textMuted)

                TypewriterText(
                    text: text,
                    characterDelay: 0.025,
                    color: EgoTheme.green,
                    font: .system(size: 16, weight: .regular, design: .monospaced),
                    onComplete: {
                        textFinished = true
                        onTextComplete()
                        withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
                            showTapHint = true
                        }
                        // Scale reading time with text length (min 1.5s, ~20ms/char)
                        let readingNs = UInt64(max(1.5, Double(text.count) * 0.02) * 1_000_000_000)
                        autoAdvanceTask = Task { @MainActor in
                            try? await Task.sleep(nanoseconds: readingNs)
                            guard !Task.isCancelled else { return }
                            onComplete()
                        }
                    }
                )
                .greenGlow()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Tap hint
            if showTapHint {
                Text("// tap to continue")
                    .font(EgoTheme.label())
                    .foregroundColor(EgoTheme.textMuted.opacity(0.3))
                    .padding(.top, 20)
                    .transition(.opacity)
            }

            Spacer().frame(maxHeight: .infinity)
            Spacer().frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 24)
        .contentShape(Rectangle())
        .onTapGesture {
            if textFinished {
                autoAdvanceTask?.cancel()
                onComplete()
            }
        }
        .onDisappear {
            autoAdvanceTask?.cancel()
        }
    }
}

// MARK: - Phase 3: Bug Reveal (Soul SPLITS)

private struct BugRevealPhaseView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onCommit: () -> Void

    @State private var appeared = false
    @State private var revealedTiles: Int = 0
    @State private var headerGlow = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header with pulse glow
                Text("PATTERNS_DETECTED")
                    .font(EgoTheme.label())
                    .tracking(2.2)
                    .foregroundColor(EgoTheme.green)
                    .shadow(color: EgoTheme.green.opacity(headerGlow ? 0.4 : 0.2), radius: headerGlow ? 6 : 4)
                    .padding(.bottom, 8)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2).repeatCount(2, autoreverses: true)) {
                            headerGlow = true
                        }
                    }

                Text(viewModel.scenarioSelections.isEmpty
                    ? "// Select the pattern to debug first."
                    : "// Your responses lit up these patterns.\n// Select the one to debug first.")
                    .font(EgoTheme.label())
                    .foregroundColor(EgoTheme.textMuted)
                    .padding(.bottom, 24)

                // Top bugs as bento diagnostic tiles — staggered cascade
                VStack(spacing: 1) {
                    ForEach(Array(viewModel.topBugs.enumerated()), id: \.element.id) { index, bug in
                        if index < revealedTiles {
                        BugDiagnosticTile(
                            bug: bug,
                            nodeIndex: index + 1,
                            isSelected: viewModel.selectedBugId == bug.id,
                            matchScore: viewModel.normalizedScore(for: bug.slug),
                            inlineComment: viewModel.inlineComment(for: bug.slug),
                            examples: viewModel.examples(for: bug.slug),
                            onSelect: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    viewModel.selectedBugId = bug.id
                                }
                            }
                        )
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                }
                .background(EgoTheme.borderSubtle)

                // Show all 7 toggle
                if !viewModel.remainingBugs.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.showAllBugs.toggle()
                        }
                    } label: {
                        HStack {
                            Text(viewModel.showAllBugs ? "// hide other patterns" : "// show all 7 patterns")
                                .font(EgoTheme.label())
                                .foregroundColor(EgoTheme.textMuted)
                            Spacer()
                            Text(viewModel.showAllBugs ? "\u{25B4}" : "\u{25BE}")
                                .font(EgoTheme.mono(.caption))
                                .foregroundColor(EgoTheme.textMuted)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 20)

                    if viewModel.showAllBugs {
                        VStack(spacing: 1) {
                            ForEach(Array(viewModel.remainingBugs.enumerated()), id: \.element.id) { index, bug in
                                BugDiagnosticTile(
                                    bug: bug,
                                    nodeIndex: viewModel.topBugs.count + index + 1,
                                    isSelected: viewModel.selectedBugId == bug.id,
                                    matchScore: viewModel.normalizedScore(for: bug.slug),
                                    inlineComment: viewModel.inlineComment(for: bug.slug),
                                    examples: viewModel.examples(for: bug.slug),
                                    onSelect: {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            viewModel.selectedBugId = bug.id
                                        }
                                    }
                                )
                            }
                        }
                        .background(EgoTheme.borderSubtle)
                        .padding(.top, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                // Footer
                Text("// More patterns will surface\n// as you generate data.")
                    .font(EgoTheme.label())
                    .foregroundColor(EgoTheme.textMuted)
                    .padding(.top, 20)

                if viewModel.selectedBugId != nil {
                    FigmaCTAButton(label: "BEGIN DEBUGGING", action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onCommit()
                    })
                        .padding(.top, 24)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }
            // Staggered tile cascade
            Task { @MainActor in
                for i in 1...viewModel.topBugs.count {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    withAnimation(.easeOut(duration: 0.3)) {
                        revealedTiles = i
                    }
                }
            }
        }
    }
}

// MARK: - Bug Diagnostic Tile (Figma Bento Style)

private struct BugDiagnosticTile: View {
    let bug: Bug
    let nodeIndex: Int
    let isSelected: Bool
    let matchScore: Double
    let inlineComment: String
    let examples: [String]
    let onSelect: () -> Void

    @State private var animatedScore: Double = 0

    private var bugColor: Color {
        BugColors.color(for: bug.slug)
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 0) {
                // Node label (Figma: "Status / Node 01")
                Text("STATUS / NODE \(String(format: "%02d", nodeIndex))")
                    .font(EgoTheme.label())
                    .tracking(1)
                    .foregroundColor(EgoTheme.textMuted)
                    .padding(.bottom, 12)

                // Bug name
                Text(bug.slug)
                    .font(.system(size: 18, weight: .light, design: .monospaced))
                    .foregroundColor(isSelected ? EgoTheme.green : EgoTheme.textPrimary)
                    .padding(.bottom, 8)

                // Description
                Text(bug.bugDescription)
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(EgoTheme.textMuted)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 12)

                // One example
                if let example = examples.first {
                    HStack(alignment: .top, spacing: 8) {
                        Text("\u{00B7}")
                            .font(EgoTheme.mono(.caption))
                            .foregroundColor(bugColor.opacity(0.6))
                        Text(example)
                            .font(EgoTheme.mono(.caption))
                            .foregroundColor(EgoTheme.textMuted.opacity(0.8))
                    }
                    .padding(.bottom, 12)
                }

                // Match score progress bar (animates on appear)
                HStack(spacing: 12) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(EgoTheme.surface)
                                .frame(height: 4)
                            Rectangle()
                                .fill(isSelected ? EgoTheme.green : bugColor)
                                .frame(width: geo.size.width * animatedScore, height: 4)
                                .shadow(color: isSelected ? EgoTheme.greenGlow : .clear, radius: 4)
                        }
                    }
                    .frame(height: 4)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                            animatedScore = matchScore
                        }
                    }

                    // Signal strength label
                    Text(matchScore > 0.7 ? "HIGH" : matchScore > 0.4 ? "MED" : "LOW")
                        .font(EgoTheme.label())
                        .foregroundColor(EgoTheme.textMuted)
                        .frame(width: 32, alignment: .trailing)
                }

                // Inline comment
                if !inlineComment.isEmpty {
                    Text(inlineComment)
                        .font(EgoTheme.label())
                        .foregroundColor(bugColor.opacity(0.7))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .background(EgoTheme.bg)
            .overlay(
                Rectangle()
                    .stroke(
                        isSelected ? EgoTheme.green.opacity(0.6) : .clear,
                        lineWidth: 1
                    )
            )
            .shadow(color: isSelected ? EgoTheme.green.opacity(0.2) : .clear, radius: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Phase 4: Committing

private struct CommittingPhaseView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var dots = ""
    @State private var visibleLines: Int = 1
    @State private var errorShake: CGFloat = 0
    @State private var successFlash = false

    private struct SysLine {
        let timestamp: String
        let message: String
    }

    private let sysLines: [SysLine] = [
        SysLine(timestamp: "[0.01200]", message: "SYS: Bug locked."),
        SysLine(timestamp: "[0.01458]", message: "SYS: Assigning fix #001"),
        SysLine(timestamp: "[0.01892]", message: "SYS: Calibrating fix difficulty..."),
        SysLine(timestamp: "[0.02140]", message: "SYS: Writing user profile..."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                // Sequential terminal lines
                ForEach(0..<min(visibleLines, sysLines.count), id: \.self) { i in
                    let line = sysLines[i]
                    let isComplete = i < visibleLines - 1 || viewModel.commitError != nil
                    let isLast = i == min(visibleLines, sysLines.count) - 1

                    HStack(spacing: 8) {
                        Text(line.timestamp)
                            .font(EgoTheme.mono(.caption))
                            .foregroundColor(EgoTheme.textMuted)
                        Text(isLast && !isComplete ? "\(line.message)\(dots)" : line.message)
                            .font(EgoTheme.mono(.caption))
                            .foregroundColor(EgoTheme.textPrimary)
                        if isComplete {
                            Text("OK")
                                .font(EgoTheme.mono(.caption))
                                .foregroundColor(EgoTheme.green)
                        } else if !isComplete && viewModel.commitError == nil {
                            Text("PENDING")
                                .font(EgoTheme.mono(.caption))
                                .foregroundColor(EgoTheme.amber)
                        }
                    }
                    .transition(.opacity)
                }

                if let error = viewModel.commitError {
                    HStack(spacing: 8) {
                        Text("[ERROR]")
                            .font(EgoTheme.mono(.caption))
                            .foregroundColor(.red)
                        Text(error)
                            .font(EgoTheme.mono(.caption))
                            .foregroundColor(EgoTheme.textPrimary)
                    }

                    Button {
                        Task { await viewModel.commitAndAssignFirstFix() }
                    } label: {
                        Text("[ RETRY ]")
                            .font(EgoTheme.mono(.caption))
                            .foregroundColor(EgoTheme.green)
                            .padding(.vertical, 8)
                    }
                }
            }
            .padding(24)
            .glassCard()
            .overlay(
                Rectangle()
                    .stroke(successFlash ? EgoTheme.green : .clear, lineWidth: 1)
            )
            .offset(x: errorShake)

            Spacer()
        }
        .padding(.horizontal, 24)
        .task {
            // Stagger line reveals
            for i in 2...sysLines.count {
                try? await Task.sleep(nanoseconds: 400_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    visibleLines = i
                }
            }
            // Dots animation on final line
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 400_000_000)
                guard !Task.isCancelled else { break }
                dots = dots.count >= 3 ? "" : dots + "."
            }
        }
        .onChange(of: viewModel.isComplete) { _, complete in
            if complete {
                withAnimation(.easeIn(duration: 0.3)) {
                    successFlash = true
                }
            }
        }
        .onChange(of: viewModel.commitError) { _, error in
            if error != nil {
                // Horizontal shake
                withAnimation(.default) { errorShake = -4 }
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 50_000_000)
                    withAnimation(.default) { errorShake = 4 }
                    try? await Task.sleep(nanoseconds: 50_000_000)
                    withAnimation(.default) { errorShake = -2 }
                    try? await Task.sleep(nanoseconds: 50_000_000)
                    withAnimation(.default) { errorShake = 0 }
                }
            }
        }
    }
}
