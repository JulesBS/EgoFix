import SwiftUI

struct SubstituteInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            InteractionHeader(type: "SUBSTITUTE", status: "Replace the pattern", typeColor: .orange)

            Text(fix.prompt)
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textPrimary)
                .lineSpacing(4)

            if let config = fix.substituteConfig {
                VStack(alignment: .leading, spacing: 6) {
                    Text("WHEN: \(config.triggerBehavior)")
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(.red)
                    Text("DO: \(config.replacementBehavior)")
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(.green)
                }
                .padding(8)
                .background(EgoTheme.surface)
                .cornerRadius(2)

                HStack(spacing: 16) {
                    VStack {
                        Text("\(interactionManager.substituteCount)")
                            .font(EgoTheme.mono(.title2))
                            .foregroundColor(.green)
                        Text("substituted")
                            .font(EgoTheme.label())
                            .foregroundColor(EgoTheme.textMuted)
                    }

                    VStack {
                        Text("\(interactionManager.urgeCount)")
                            .font(EgoTheme.mono(.title2))
                            .foregroundColor(.orange)
                        Text("urges")
                            .font(EgoTheme.label())
                            .foregroundColor(EgoTheme.textMuted)
                    }
                }

                HStack(spacing: 8) {
                    Button("+urge") {
                        interactionManager.urgeCount += 1
                    }
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2).stroke(.orange, lineWidth: 1)
                            .accessibilityHidden(true)
                    )
                    .accessibilityLabel("Record urge")
                    .accessibilityHint("Logs an urge occurrence, current count: \(interactionManager.urgeCount)")

                    Button("+substituted") {
                        interactionManager.substituteCount += 1
                    }
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2).stroke(.green, lineWidth: 1)
                            .accessibilityHidden(true)
                    )
                    .accessibilityLabel("Record substitution")
                    .accessibilityHint("Logs a successful substitution, current count: \(interactionManager.substituteCount)")
                }
            }

            InlineCommentView(comment: fix.inlineComment)
        }
        .interactionCard()
        .accessibilityLabel("Substitute interaction, \(interactionManager.substituteCount) substituted, \(interactionManager.urgeCount) urges")
    }
}
