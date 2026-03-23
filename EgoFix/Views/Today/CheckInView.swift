import SwiftUI

/// Evening check-in: interaction-type-specific UI for reporting the day's outcome.
struct CheckInView: View {
    let fix: Fix
    let bugTitle: String?
    @ObservedObject var interactionManager: FixInteractionManager
    let onApplied: () -> Void
    let onSkipped: () -> Void
    let onFailed: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // MISSION — small prompt reminder (deemphasized)
            VStack(alignment: .leading, spacing: 0) {
                Text("MISSION")
                    .font(EgoTheme.label())
                    .tracking(1.5)
                    .foregroundColor(EgoTheme.textMuted)
                    .padding(.bottom, 8)

                Text(fix.prompt)
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(EgoTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard()

            // DEBRIEF — interaction-specific content
            VStack(alignment: .leading, spacing: 0) {
                Text("DEBRIEF")
                    .font(EgoTheme.label())
                    .tracking(1.5)
                    .foregroundColor(EgoTheme.amber)
                    .padding(.bottom, 16)

                checkInContent
            }
            .padding(24)
            .glassCard()

            // Submit button for non-standard types
            if fix.interactionType != .standard &&
               fix.interactionType != .abstain &&
               fix.interactionType != .reversal {
                if interactionManager.canMarkApplied {
                    FigmaCTAButton(label: "SUBMIT", action: onApplied)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
    }

    @ViewBuilder
    private var checkInContent: some View {
        switch fix.interactionType {
        case .standard, .reversal:
            standardCheckIn
        case .counter:
            counterCheckIn
        case .observation:
            observationCheckIn
        case .abstain:
            abstainCheckIn
        case .substitute:
            substituteCheckIn
        case .journal:
            journalCheckIn
        case .body:
            standardCheckIn
        case .predict:
            predictCheckIn
        case .audit:
            auditCheckIn
        case .scenario:
            scenarioCheckIn
        case .multiStep:
            multiStepCheckIn
        case .timed, .quiz:
            standardCheckIn
        }
    }

    // MARK: - Standard / Reversal / Body

    private var standardCheckIn: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How'd it go?")
                .font(.system(size: 18, weight: .light, design: .monospaced))
                .foregroundColor(EgoTheme.textPrimary)
                .padding(.bottom, 4)

            Button(action: onApplied) {
                HStack {
                    Spacer()
                    Text("APPLIED")
                        .font(EgoTheme.mono(.callout))
                        .tracking(2)
                        .foregroundColor(EgoTheme.green)
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(EgoTheme.surface)
                .overlay(Rectangle().stroke(EgoTheme.green.opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button(action: onFailed) {
                HStack {
                    Spacer()
                    Text("TRIED, COULDN'T")
                        .font(EgoTheme.mono(.callout))
                        .tracking(1.4)
                        .foregroundColor(.red.opacity(0.8))
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(EgoTheme.surface)
                .overlay(Rectangle().stroke(EgoTheme.border, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button(action: onSkipped) {
                HStack {
                    Spacer()
                    Text("DIDN'T ATTEMPT")
                        .font(EgoTheme.mono(.callout))
                        .tracking(1.4)
                        .foregroundColor(EgoTheme.textMuted)
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(EgoTheme.surface)
                .overlay(Rectangle().stroke(EgoTheme.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Counter

    private var counterCheckIn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("How many times?")
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textPrimary)
                .padding(.bottom, 20)

            HStack(spacing: 0) {
                Button(action: { interactionManager.decrementCounter() }) {
                    Text("\u{2212}")
                        .font(.system(size: 24, weight: .light, design: .monospaced))
                        .foregroundColor(EgoTheme.textMuted)
                        .frame(width: 56, height: 56)
                        .background(EgoTheme.surface)
                        .overlay(Rectangle().stroke(EgoTheme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Text("\(interactionManager.counterValue)")
                    .font(.system(size: 36, weight: .light, design: .monospaced))
                    .foregroundColor(EgoTheme.green)
                    .greenGlow()
                    .frame(maxWidth: .infinity)

                Button(action: { interactionManager.incrementCounter() }) {
                    Text("+")
                        .font(.system(size: 24, weight: .light, design: .monospaced))
                        .foregroundColor(EgoTheme.green)
                        .frame(width: 56, height: 56)
                        .background(EgoTheme.surface)
                        .overlay(Rectangle().stroke(EgoTheme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .glassCard()
    }

    // MARK: - Observation

    private var observationCheckIn: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What did you notice?")
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textPrimary)

            TextField("", text: $interactionManager.observationReport, axis: .vertical)
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textPrimary)
                .padding(16)
                .background(EgoTheme.surface)
                .overlay(Rectangle().stroke(EgoTheme.border, lineWidth: 1))
                .lineLimit(3...6)
        }
        .padding(24)
        .glassCard()
    }

    // MARK: - Abstain

    private var abstainCheckIn: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Did you make it through?")
                .font(.system(size: 18, weight: .light, design: .monospaced))
                .foregroundColor(EgoTheme.textPrimary)
                .padding(.bottom, 4)

            Button(action: {
                interactionManager.abstainCompleted = true
                onApplied()
            }) {
                HStack {
                    Spacer()
                    Text("MADE IT")
                        .font(EgoTheme.mono(.callout))
                        .tracking(2)
                        .foregroundColor(EgoTheme.green)
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(EgoTheme.surface)
                .overlay(Rectangle().stroke(EgoTheme.green.opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button(action: {
                interactionManager.abstainCompleted = false
                onFailed()
            }) {
                HStack {
                    Spacer()
                    Text("BROKE IT")
                        .font(EgoTheme.mono(.callout))
                        .tracking(1.4)
                        .foregroundColor(.red.opacity(0.8))
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(EgoTheme.surface)
                .overlay(Rectangle().stroke(EgoTheme.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Substitute

    private var substituteCheckIn: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Urges vs. substitutions")
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textPrimary)

            HStack(spacing: 1) {
                VStack(spacing: 8) {
                    Text("URGES")
                        .font(EgoTheme.label())
                        .tracking(1)
                        .foregroundColor(.red)
                    HStack(spacing: 12) {
                        Button(action: { if interactionManager.urgeCount > 0 { interactionManager.urgeCount -= 1 } }) {
                            Text("\u{2212}").font(EgoTheme.mono()).foregroundColor(EgoTheme.textMuted)
                        }
                        Text("\(interactionManager.urgeCount)")
                            .font(.system(size: 28, weight: .light, design: .monospaced))
                            .foregroundColor(.red)
                        Button(action: { interactionManager.urgeCount += 1 }) {
                            Text("+").font(EgoTheme.mono()).foregroundColor(.red)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(EgoTheme.bg)

                VStack(spacing: 8) {
                    Text("SUBSTITUTED")
                        .font(EgoTheme.label())
                        .tracking(1)
                        .foregroundColor(EgoTheme.green)
                    HStack(spacing: 12) {
                        Button(action: { if interactionManager.substituteCount > 0 { interactionManager.substituteCount -= 1 } }) {
                            Text("\u{2212}").font(EgoTheme.mono()).foregroundColor(EgoTheme.textMuted)
                        }
                        Text("\(interactionManager.substituteCount)")
                            .font(.system(size: 28, weight: .light, design: .monospaced))
                            .foregroundColor(EgoTheme.green)
                        Button(action: { interactionManager.substituteCount += 1 }) {
                            Text("+").font(EgoTheme.mono()).foregroundColor(EgoTheme.green)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(EgoTheme.bg)
            }
            .background(EgoTheme.borderSubtle)
        }
    }

    // MARK: - Journal

    private var journalCheckIn: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reflect on today")
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textPrimary)

            TextField("", text: $interactionManager.journalText, axis: .vertical)
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textPrimary)
                .padding(16)
                .background(EgoTheme.surface)
                .overlay(Rectangle().stroke(EgoTheme.border, lineWidth: 1))
                .lineLimit(3...8)
        }
        .padding(24)
        .glassCard()
    }

    // MARK: - Predict

    private var predictCheckIn: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What actually happened?")
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textPrimary)

            if !interactionManager.predictionText.isEmpty {
                Text("You predicted: \(interactionManager.predictionText)")
                    .font(EgoTheme.label())
                    .foregroundColor(EgoTheme.textMuted)
            }

            TextField("", text: $interactionManager.observationText, axis: .vertical)
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textPrimary)
                .padding(16)
                .background(EgoTheme.surface)
                .overlay(Rectangle().stroke(EgoTheme.border, lineWidth: 1))
                .lineLimit(3...6)
        }
        .padding(24)
        .glassCard()
    }

    // MARK: - Audit

    private var auditCheckIn: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("End-of-day review")
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textPrimary)

            if let config = fix.auditConfig {
                ForEach(config.categories, id: \.id) { category in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(category.label.uppercased())
                            .font(EgoTheme.label())
                            .tracking(1)
                            .foregroundColor(EgoTheme.textMuted)

                        TextField("", text: auditBinding(for: category.id))
                            .font(EgoTheme.mono())
                            .foregroundColor(EgoTheme.textPrimary)
                            .padding(12)
                            .background(EgoTheme.surface)
                            .overlay(Rectangle().stroke(EgoTheme.border, lineWidth: 1))
                    }
                }
            }
        }
        .padding(24)
        .glassCard()
    }

    // MARK: - Scenario

    private var scenarioCheckIn: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let config = fix.scenarioConfig {
                Text(config.situation)
                    .font(.system(size: 16, weight: .light, design: .monospaced))
                    .foregroundColor(EgoTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 16)

                Rectangle()
                    .fill(EgoTheme.borderSubtle)
                    .frame(height: 0.5)
                    .padding(.bottom, 16)

                VStack(spacing: 8) {
                    ForEach(config.options, id: \.id) { option in
                        let isSelected = interactionManager.selectedScenarioOptionId == option.id
                        Button(action: { interactionManager.selectScenarioOption(option) }) {
                            Text(option.text)
                                .font(EgoTheme.mono())
                                .foregroundColor(isSelected ? EgoTheme.green : EgoTheme.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .overlay(
                                    Rectangle()
                                        .stroke(
                                            isSelected ? EgoTheme.green.opacity(0.6) : EgoTheme.border,
                                            lineWidth: 1
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(interactionManager.scenarioAnswered)
                    }
                }
            }
        }
        .padding(24)
        .glassCard()
    }

    // MARK: - Multi-Step

    private var multiStepCheckIn: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Step checklist")
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textPrimary)
                .padding(.bottom, 4)

            if let config = fix.multiStepConfig {
                ForEach(Array(config.steps.enumerated()), id: \.element.id) { index, step in
                    let isCompleted = interactionManager.completedSteps.contains { $0.stepId == step.id && !$0.skipped }
                    let isSkipped = interactionManager.completedSteps.contains { $0.stepId == step.id && $0.skipped }
                    let isCurrent = index == interactionManager.currentStepIndex && !interactionManager.allStepsProcessed

                    HStack(alignment: .top) {
                        Text(isCompleted ? "[x]" : isSkipped ? "[-]" : "[ ]")
                            .font(EgoTheme.mono())
                            .foregroundColor(isCompleted ? EgoTheme.green : isSkipped ? EgoTheme.amber : EgoTheme.textMuted)
                            .frame(width: 28)

                        Text(step.prompt)
                            .font(EgoTheme.mono(.caption))
                            .foregroundColor(isCurrent ? EgoTheme.textPrimary : EgoTheme.textMuted)

                        Spacer()

                        if isCurrent {
                            HStack(spacing: 8) {
                                Button(action: { interactionManager.completeCurrentStep() }) {
                                    Text("Done")
                                        .font(EgoTheme.label())
                                        .foregroundColor(EgoTheme.green)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(EgoTheme.surface)
                                }
                                Button(action: { interactionManager.skipCurrentStep() }) {
                                    Text("Skip")
                                        .font(EgoTheme.label())
                                        .foregroundColor(EgoTheme.textMuted)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(24)
        .glassCard()
    }

    // MARK: - Helpers

    private func auditBinding(for categoryId: String) -> Binding<String> {
        Binding(
            get: { interactionManager.auditItems[categoryId] ?? "" },
            set: { interactionManager.auditItems[categoryId] = $0 }
        )
    }
}
