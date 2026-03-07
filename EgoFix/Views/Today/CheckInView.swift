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
        VStack(spacing: 24) {
            Text("CHECK IN")
                .font(.system(.headline, design: .monospaced))
                .foregroundColor(.green)

            Text(fix.prompt)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(Color(white: 0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            checkInContent

            if fix.interactionType != .standard &&
               fix.interactionType != .abstain &&
               fix.interactionType != .reversal {
                // Show apply button when interaction data is ready
                if interactionManager.canMarkApplied {
                    Button(action: onApplied) {
                        Text("[ Done ]")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.green)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(2)
                    }
                }
            }
        }
        .padding(.top, 8)
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
            // These shouldn't reach check-in — they're immediate in-app
            standardCheckIn
        }
    }

    // MARK: - Check-In Variants

    private var standardCheckIn: some View {
        VStack(spacing: 12) {
            Text("How'd it go?")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)

            VStack(spacing: 8) {
                Button(action: onApplied) {
                    Text("[ Applied ]")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(2)
                }

                Button(action: onFailed) {
                    Text("[ Tried, couldn't ]")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }

                Button(action: onSkipped) {
                    Text("[ Didn't attempt ]")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private var counterCheckIn: some View {
        VStack(spacing: 16) {
            Text("How many times?")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)

            HStack(spacing: 24) {
                Button(action: { interactionManager.decrementCounter() }) {
                    Text("[ - ]")
                        .font(.system(.title2, design: .monospaced))
                        .foregroundColor(.gray)
                }

                Text("\(interactionManager.counterValue)")
                    .font(.system(.title, design: .monospaced))
                    .foregroundColor(.green)
                    .frame(minWidth: 60)

                Button(action: { interactionManager.incrementCounter() }) {
                    Text("[ + ]")
                        .font(.system(.title2, design: .monospaced))
                        .foregroundColor(.green)
                }
            }
        }
    }

    private var observationCheckIn: some View {
        VStack(spacing: 12) {
            Text("What did you notice?")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)

            TextField("", text: $interactionManager.observationReport, axis: .vertical)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)
                .padding(12)
                .background(Color(white: 0.1))
                .cornerRadius(2)
                .lineLimit(3...6)
                .padding(.horizontal, 16)
        }
    }

    private var abstainCheckIn: some View {
        VStack(spacing: 12) {
            Text("Did you make it through?")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)

            VStack(spacing: 8) {
                Button(action: {
                    interactionManager.abstainCompleted = true
                    onApplied()
                }) {
                    Text("[ Made it ]")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(2)
                }

                Button(action: {
                    interactionManager.abstainCompleted = false
                    onFailed()
                }) {
                    Text("[ Broke it ]")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private var substituteCheckIn: some View {
        VStack(spacing: 16) {
            Text("Urges vs. substitutions")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)

            HStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("Urges")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.red)
                    HStack(spacing: 12) {
                        Button(action: { if interactionManager.urgeCount > 0 { interactionManager.urgeCount -= 1 } }) {
                            Text("-").font(.system(.body, design: .monospaced)).foregroundColor(.gray)
                        }
                        Text("\(interactionManager.urgeCount)")
                            .font(.system(.title3, design: .monospaced))
                            .foregroundColor(.red)
                        Button(action: { interactionManager.urgeCount += 1 }) {
                            Text("+").font(.system(.body, design: .monospaced)).foregroundColor(.red)
                        }
                    }
                }

                VStack(spacing: 8) {
                    Text("Substituted")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.green)
                    HStack(spacing: 12) {
                        Button(action: { if interactionManager.substituteCount > 0 { interactionManager.substituteCount -= 1 } }) {
                            Text("-").font(.system(.body, design: .monospaced)).foregroundColor(.gray)
                        }
                        Text("\(interactionManager.substituteCount)")
                            .font(.system(.title3, design: .monospaced))
                            .foregroundColor(.green)
                        Button(action: { interactionManager.substituteCount += 1 }) {
                            Text("+").font(.system(.body, design: .monospaced)).foregroundColor(.green)
                        }
                    }
                }
            }
        }
    }

    private var journalCheckIn: some View {
        VStack(spacing: 12) {
            Text("Reflect on today")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)

            TextField("", text: $interactionManager.journalText, axis: .vertical)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)
                .padding(12)
                .background(Color(white: 0.1))
                .cornerRadius(2)
                .lineLimit(3...8)
                .padding(.horizontal, 16)
        }
    }

    private var predictCheckIn: some View {
        VStack(spacing: 12) {
            Text("What actually happened?")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)

            if !interactionManager.predictionText.isEmpty {
                Text("You predicted: \(interactionManager.predictionText)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Color(white: 0.4))
                    .padding(.horizontal, 16)
            }

            TextField("", text: $interactionManager.observationText, axis: .vertical)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)
                .padding(12)
                .background(Color(white: 0.1))
                .cornerRadius(2)
                .lineLimit(3...6)
                .padding(.horizontal, 16)
        }
    }

    private var auditCheckIn: some View {
        VStack(spacing: 12) {
            Text("End-of-day review")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)

            if let config = fix.auditConfig {
                ForEach(config.categories, id: \.id) { category in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.label)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gray)

                        TextField("", text: auditBinding(for: category.id))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color(white: 0.1))
                            .cornerRadius(2)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var scenarioCheckIn: some View {
        VStack(spacing: 12) {
            if let config = fix.scenarioConfig {
                Text(config.situation)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                ForEach(config.options, id: \.id) { option in
                    Button(action: { interactionManager.selectScenarioOption(option) }) {
                        Text("[ \(option.text) ]")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(interactionManager.selectedScenarioOptionId == option.id ? .green : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                interactionManager.selectedScenarioOptionId == option.id
                                    ? Color.green.opacity(0.1) : Color.clear
                            )
                            .cornerRadius(2)
                    }
                    .disabled(interactionManager.scenarioAnswered)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var multiStepCheckIn: some View {
        VStack(spacing: 12) {
            Text("Step checklist")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)

            if let config = fix.multiStepConfig {
                ForEach(Array(config.steps.enumerated()), id: \.element.id) { index, step in
                    let isCompleted = interactionManager.completedSteps.contains { $0.stepId == step.id && !$0.skipped }
                    let isSkipped = interactionManager.completedSteps.contains { $0.stepId == step.id && $0.skipped }
                    let isCurrent = index == interactionManager.currentStepIndex && !interactionManager.allStepsProcessed

                    HStack {
                        Text(isCompleted ? "[x]" : isSkipped ? "[-]" : "[ ]")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(isCompleted ? .green : isSkipped ? .yellow : .gray)

                        Text(step.prompt)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(isCurrent ? .white : Color(white: 0.5))

                        Spacer()

                        if isCurrent {
                            HStack(spacing: 8) {
                                Button(action: { interactionManager.completeCurrentStep() }) {
                                    Text("Done").font(.system(.caption2, design: .monospaced)).foregroundColor(.green)
                                }
                                Button(action: { interactionManager.skipCurrentStep() }) {
                                    Text("Skip").font(.system(.caption2, design: .monospaced)).foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Helpers

    private func auditBinding(for categoryId: String) -> Binding<String> {
        Binding(
            get: { interactionManager.auditItems[categoryId] ?? "" },
            set: { interactionManager.auditItems[categoryId] = $0 }
        )
    }
}
