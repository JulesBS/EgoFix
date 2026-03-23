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
                        }
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
        .animation(.easeInOut(duration: 0.4), value: viewModel.phase)
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
        VStack(spacing: 0) {
            // 3D ASCII soul animation with corner brackets — fixed size, never scales down
            OnboardingSoulView(
                onRendererReady: { r in soulRenderer = r },
                onRendererFailed: { rendererFailed = true }
            )
            .frame(width: 200, height: 200)
            .cornerBrackets()
            .padding(.top, 40)
            .padding(.bottom, 24)

            // Scrollable text + button area
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(0..<min(currentLine + 1, lines.count), id: \.self) { index in
                        let line = lines[index]
                        if index < currentLine {
                            completedLineView(line)
                        } else if index == currentLine {
                            activeLineView(line, index: index)
                        }
                    }

                    if showButton {
                        FigmaCTAButton(label: "INITIALIZE SEQUENCE", action: onBeginScan)
                            .padding(.top, 26)
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            currentLine = 0
        }
    }

    // MARK: Line rendering

    private func lineColor(_ line: BootLine) -> Color {
        line.style == .terminal ? EgoTheme.green : EgoTheme.textPrimary
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
        // Trigger soul split when "bugs" line completes
        if index == splitTriggerLineIndex {
            if let r = soulRenderer {
                r.animator.triggerSplit(scene: r.soulScene)
            }
        }

        let postDelay = lines[index].postDelay
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(postDelay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            if index + 1 < lines.count {
                currentLine = index + 1
            } else {
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

    @State private var showSituation = false
    @State private var revealedOptions: Int = 0
    @State private var situationComplete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            // Progress label (Figma: green tracked uppercase)
            Text("SCENARIO_0\(scenarioIndex + 1)")
                .font(EgoTheme.label())
                .tracking(2.2)
                .foregroundColor(EgoTheme.green)
                .greenGlow()
                .padding(.bottom, 8)

            Text("\(scenarioIndex + 1) of \(totalScenarios)")
                .font(EgoTheme.label())
                .foregroundColor(EgoTheme.textMuted)
                .padding(.bottom, 20)

            // Situation inside glass card
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
            }

            // Options (staggered reveal)
            if situationComplete {
                VStack(spacing: 10) {
                    ForEach(Array(scenario.options.enumerated()), id: \.element.id) { index, option in
                        if index < revealedOptions {
                            Button {
                                onSelect(option.id)
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
                                .overlay(
                                    Rectangle()
                                        .stroke(EgoTheme.border, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
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
    @State private var autoAdvanceTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            TypewriterText(
                text: text,
                characterDelay: 0.025,
                color: EgoTheme.green,
                font: .system(size: 16, weight: .regular, design: .monospaced),
                onComplete: {
                    textFinished = true
                    onTextComplete()
                    autoAdvanceTask = Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        guard !Task.isCancelled else { return }
                        onComplete()
                    }
                }
            )
            .greenGlow()
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header (Figma: tracked green uppercase)
                Text("PATTERNS_DETECTED")
                    .font(EgoTheme.label())
                    .tracking(2.2)
                    .foregroundColor(EgoTheme.green)
                    .greenGlow()
                    .padding(.bottom, 8)

                Text(viewModel.scenarioSelections.isEmpty
                    ? "// Select the pattern to debug first."
                    : "// Your responses lit up these patterns.\n// Select the one to debug first.")
                    .font(EgoTheme.label())
                    .foregroundColor(EgoTheme.textMuted)
                    .padding(.bottom, 24)

                // Top bugs as bento diagnostic tiles
                VStack(spacing: 1) {
                    ForEach(Array(viewModel.topBugs.enumerated()), id: \.element.id) { index, bug in
                        BugDiagnosticTile(
                            bug: bug,
                            nodeIndex: index + 1,
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
                    FigmaCTAButton(label: "BEGIN DEBUGGING", action: onCommit)
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

                // Match score progress bar
                HStack(spacing: 12) {
                    // Progress track
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(EgoTheme.surface)
                                .frame(height: 4)
                            Rectangle()
                                .fill(isSelected ? EgoTheme.green : bugColor)
                                .frame(width: geo.size.width * matchScore, height: 4)
                                .shadow(color: isSelected ? EgoTheme.greenGlow : .clear, radius: 4)
                        }
                    }
                    .frame(height: 4)

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
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Phase 4: Committing

private struct CommittingPhaseView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var dots = ""

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("[0.01200]")
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textMuted)
                    Text("SYS: Bug locked.")
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textPrimary)
                    Text("OK")
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.green)
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
                } else {
                    HStack(spacing: 8) {
                        Text("[0.01458]")
                            .font(EgoTheme.mono(.caption))
                            .foregroundColor(EgoTheme.textMuted)
                        Text("SYS: Assigning fix #001\(dots)")
                            .font(EgoTheme.mono(.caption))
                            .foregroundColor(EgoTheme.textPrimary)
                        Text("PENDING")
                            .font(EgoTheme.mono(.caption))
                            .foregroundColor(EgoTheme.amber)
                    }
                }
            }
            .padding(24)
            .glassCard()

            Spacer()
        }
        .padding(.horizontal, 24)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 400_000_000)
                guard !Task.isCancelled else { break }
                dots = dots.count >= 3 ? "" : dots + "."
            }
        }
    }
}
