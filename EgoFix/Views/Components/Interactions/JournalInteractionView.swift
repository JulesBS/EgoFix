import SwiftUI

struct JournalInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            InteractionHeader(type: "JOURNAL", status: "2-3 sentences", typeColor: .blue)

            Text(fix.prompt)
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textPrimary)
                .lineSpacing(4)

            TextField("Write here...", text: $interactionManager.journalText, axis: .vertical)
                .font(EgoTheme.mono(.caption))
                .foregroundColor(EgoTheme.textPrimary)
                .lineLimit(3...8)
                .padding(8)
                .background(EgoTheme.surface)
                .cornerRadius(2)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(isTextFieldFocused ? Color.blue.opacity(0.5) : Color(white: 0.2), lineWidth: 1)
                        .accessibilityHidden(true)
                )
                .shadow(color: isTextFieldFocused ? .blue.opacity(0.3) : .clear, radius: 4, x: 0, y: 0)
                .focused($isTextFieldFocused)
                .accessibilityLabel("Journal entry")
                .accessibilityHint("Write your reflection, 2 to 3 sentences")

            InlineCommentView(comment: fix.inlineComment)
        }
        .interactionCard()
        .accessibilityLabel("Journal interaction")
    }
}
