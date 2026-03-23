import SwiftUI

struct BodyInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            InteractionHeader(type: "BODY", status: "Somatic awareness", typeColor: .mint)

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
    }
}
