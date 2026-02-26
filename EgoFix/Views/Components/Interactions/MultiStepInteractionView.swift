import SwiftUI

struct MultiStepInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager

    private var config: MultiStepConfig? {
        interactionManager.multiStepConfig
    }

    private var currentStep: MultiStepConfig.StepItem? {
        interactionManager.currentStep
    }

    private var isComplete: Bool {
        interactionManager.allStepsProcessed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with step indicator
            HStack {
                Text("STEP \(interactionManager.currentStepIndex + 1)/\(interactionManager.totalSteps)")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.green)

                Spacer()

                // Progress dots
                progressDots
            }

            if isComplete {
                // Completion state
                completedView
            } else if let step = currentStep {
                // Current step prompt
                Text(step.prompt)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white)
                    .lineSpacing(4)

                // Optional inline comment
                if let comment = step.inlineComment {
                    Text("// \(comment)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.35))
                        .italic()
                }

                // Optional validation
                if let validation = step.validation {
                    Text(validation)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.5))
                        .padding(.top, 4)
                }

                // Action buttons
                HStack(spacing: 12) {
                    Spacer()

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            interactionManager.completeCurrentStep()
                        }
                    }) {
                        Text("[ Done ]")
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.green)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(2)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            interactionManager.skipCurrentStep()
                        }
                    }) {
                        Text("[ Skip ]")
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.yellow.opacity(0.1))
                            .cornerRadius(2)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(Color(white: 0.06))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: 4) {
            ForEach(0..<interactionManager.totalSteps, id: \.self) { index in
                if index < interactionManager.completedSteps.count {
                    // Completed or skipped
                    let completion = interactionManager.completedSteps[index]
                    Text(completion.skipped ? "\u{25CB}" : "\u{25CF}")  // Empty or filled circle
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(completion.skipped ? .yellow : .green)
                } else if index == interactionManager.currentStepIndex {
                    // Current step
                    Text("\u{25CF}")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white)
                } else {
                    // Pending
                    Text("\u{25CB}")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.3))
                }
            }
        }
    }

    // MARK: - Completed View

    private var completedView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("ALL STEPS COMPLETE")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.green)
            }

            // Summary
            Text("// \(interactionManager.completedStepsCount) done, \(interactionManager.skippedStepsCount) skipped")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(Color(white: 0.35))
        }
    }

    // MARK: - Border Color

    private var borderColor: Color {
        if isComplete {
            return .green.opacity(0.5)
        } else if interactionManager.skippedStepsCount > 0 {
            return .yellow.opacity(0.3)
        }
        return Color(white: 0.15)
    }
}

