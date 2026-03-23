import SwiftUI

struct ReversalInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            InteractionHeader(type: "REVERSAL", status: "Do the opposite", typeColor: .purple)

            Text(fix.prompt)
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textPrimary)
                .lineSpacing(4)

            Text(fix.validation)
                .font(EgoTheme.mono(.caption))
                .foregroundColor(EgoTheme.textPrimary)

            InlineCommentView(comment: fix.inlineComment)
        }
        .interactionCard()
        .accessibilityLabel("Reversal interaction, do the opposite")
    }
}
