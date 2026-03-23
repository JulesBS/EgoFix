import SwiftUI

struct PredictInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            InteractionHeader(type: "PREDICT", status: interactionManager.predictPhase == .predicting ? "Phase 1: Predict" : "Phase 2: Observe")

            Text(fix.prompt)
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textPrimary)
                .lineSpacing(4)

            if let config = fix.predictConfig {
                if interactionManager.predictPhase == .predicting {
                    Text(config.predictionPrompt)
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textPrimary)

                    TextField("Your prediction...", text: $interactionManager.predictionText, axis: .vertical)
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textPrimary)
                        .lineLimit(2...4)
                        .padding(8)
                        .background(EgoTheme.surface)
                        .cornerRadius(2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(EgoTheme.border, lineWidth: 1)
                                .accessibilityHidden(true)
                        )
                        .accessibilityLabel("Prediction entry")
                        .accessibilityHint("Write what you predict will happen")

                    if !interactionManager.predictionText.isEmpty {
                        Button("Lock prediction & observe") {
                            interactionManager.predictPhase = .observing
                        }
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2).stroke(.green, lineWidth: 1)
                                .accessibilityHidden(true)
                        )
                        .accessibilityHint("Locks your prediction and moves to the observation phase")
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PREDICTED:")
                            .font(EgoTheme.label())
                            .foregroundColor(EgoTheme.textMuted)
                        Text(interactionManager.predictionText)
                            .font(EgoTheme.mono(.caption))
                            .foregroundColor(EgoTheme.textPrimary)
                    }
                    .padding(8)
                    .background(EgoTheme.surface)
                    .cornerRadius(2)

                    Text(config.observationPrompt)
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textPrimary)

                    TextField("What actually happened...", text: $interactionManager.observationText, axis: .vertical)
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textPrimary)
                        .lineLimit(2...4)
                        .padding(8)
                        .background(EgoTheme.surface)
                        .cornerRadius(2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(EgoTheme.border, lineWidth: 1)
                                .accessibilityHidden(true)
                        )
                        .accessibilityLabel("Observation entry")
                        .accessibilityHint("Describe what actually happened")
                }
            }

            InlineCommentView(comment: fix.inlineComment)
        }
        .interactionCard()
        .accessibilityLabel("Predict interaction, \(interactionManager.predictPhase == .predicting ? "prediction phase" : "observation phase")")
    }
}
