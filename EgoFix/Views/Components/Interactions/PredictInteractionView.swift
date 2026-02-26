import SwiftUI

struct PredictInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PREDICT")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.green)
                Spacer()
                Text(interactionManager.predictPhase == .predicting ? "Phase 1: Predict" : "Phase 2: Observe")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(Color(white: 0.5))
            }

            Text(fix.prompt)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)
                .lineSpacing(4)

            if let config = fix.predictConfig {
                if interactionManager.predictPhase == .predicting {
                    Text(config.predictionPrompt)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.6))

                    TextField("Your prediction...", text: $interactionManager.predictionText, axis: .vertical)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(2...4)
                        .padding(8)
                        .background(Color(white: 0.08))
                        .cornerRadius(2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color(white: 0.2), lineWidth: 1)
                        )

                    if !interactionManager.predictionText.isEmpty {
                        Button("Lock prediction & observe") {
                            interactionManager.predictPhase = .observing
                        }
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .overlay(RoundedRectangle(cornerRadius: 2).stroke(.green, lineWidth: 1))
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PREDICTED:")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(Color(white: 0.4))
                        Text(interactionManager.predictionText)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(Color(white: 0.6))
                    }
                    .padding(8)
                    .background(Color(white: 0.08))
                    .cornerRadius(2)

                    Text(config.observationPrompt)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.6))

                    TextField("What actually happened...", text: $interactionManager.observationText, axis: .vertical)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(2...4)
                        .padding(8)
                        .background(Color(white: 0.08))
                        .cornerRadius(2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color(white: 0.2), lineWidth: 1)
                        )
                }
            }

            if let comment = fix.inlineComment {
                Text("// \(comment)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Color(white: 0.35))
                    .italic()
            }
        }
        .padding(16)
        .background(Color(white: 0.06))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color(white: 0.15), lineWidth: 1)
        )
    }
}
