import SwiftUI

struct AuditInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            InteractionHeader(type: "AUDIT", status: "End-of-day review", typeColor: EgoTheme.textMuted)

            Text(fix.prompt)
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textPrimary)
                .lineSpacing(4)

            if let config = fix.auditConfig {
                Text(config.auditPrompt)
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(EgoTheme.textPrimary)

                ForEach(config.categories) { category in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.label.uppercased())
                            .font(EgoTheme.label())
                            .foregroundColor(EgoTheme.textMuted)

                        let binding = Binding<String>(
                            get: { interactionManager.auditItems[category.id] ?? "" },
                            set: { interactionManager.auditItems[category.id] = $0 }
                        )

                        TextField("Note...", text: binding, axis: .vertical)
                            .font(EgoTheme.mono(.caption))
                            .foregroundColor(EgoTheme.textPrimary)
                            .lineLimit(1...3)
                            .padding(6)
                            .background(EgoTheme.surface)
                            .cornerRadius(2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(EgoTheme.border, lineWidth: 1)
                            )
                    }
                }
            }

            InlineCommentView(comment: fix.inlineComment)
        }
        .interactionCard()
    }
}
