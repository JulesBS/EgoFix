import SwiftUI

struct AbstainInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            InteractionHeader(type: "ABSTAIN", status: "Don't do the thing", typeColor: .red)

            Text(fix.prompt)
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textPrimary)
                .lineSpacing(4)

            if let config = fix.abstainConfig {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(.red)
                    Text(config.durationDescription)
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textPrimary)
                }

                Toggle(isOn: $interactionManager.abstainCompleted) {
                    Text("Period completed without slipping")
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textPrimary)
                }
                .toggleStyle(SwitchToggleStyle(tint: .red))
                .accessibilityHint("Mark whether you completed the abstain period without slipping")
            }

            InlineCommentView(comment: fix.inlineComment)
        }
        .interactionCard()
        .accessibilityLabel("Abstain interaction, \(interactionManager.abstainCompleted ? "completed" : "in progress")")
    }
}
