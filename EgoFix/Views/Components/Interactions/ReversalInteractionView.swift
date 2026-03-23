import SwiftUI

struct ReversalInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("REVERSAL")
                    .font(EgoTheme.label())
                    .foregroundColor(.purple)
                Spacer()
                Text("Do the opposite")
                    .font(EgoTheme.label())
                    .foregroundColor(EgoTheme.textMuted)
            }

            Text(fix.prompt)
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textPrimary)
                .lineSpacing(4)

            Text(fix.validation)
                .font(EgoTheme.mono(.caption))
                .foregroundColor(EgoTheme.textPrimary)

            if let comment = fix.inlineComment {
                Text("// \(comment)")
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(EgoTheme.textMuted)
                    .italic()
            }
        }
        .padding(16)
        .background(EgoTheme.surface.opacity(0.3))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(EgoTheme.border, lineWidth: 1)
        )
    }
}
