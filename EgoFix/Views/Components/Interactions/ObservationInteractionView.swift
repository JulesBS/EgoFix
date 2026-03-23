import SwiftUI

struct ObservationInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            InteractionHeader(type: "OBSERVATION", status: "Notice & report", typeColor: .yellow)

            Text(fix.prompt)
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textPrimary)
                .lineSpacing(4)

            if let config = fix.observationConfig {
                Text(config.reportPrompt)
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(EgoTheme.textPrimary)
                    .padding(.top, 4)

                TextField("Your observation...", text: $interactionManager.observationReport, axis: .vertical)
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(EgoTheme.textPrimary)
                    .lineLimit(3...6)
                    .padding(8)
                    .background(EgoTheme.surface)
                    .cornerRadius(2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(isTextFieldFocused ? Color.yellow.opacity(0.5) : Color(white: 0.2), lineWidth: 1)
                            .accessibilityHidden(true)
                    )
                    .shadow(color: isTextFieldFocused ? .yellow.opacity(0.3) : .clear, radius: 4, x: 0, y: 0)
                    .focused($isTextFieldFocused)
                    .accessibilityLabel("Observation report")
                    .accessibilityHint("Describe what you noticed")
            }

            InlineCommentView(comment: fix.inlineComment)
        }
        .interactionCard()
        .accessibilityLabel("Observation interaction")
    }
}
