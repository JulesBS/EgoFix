import SwiftUI

struct StandardInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager

    @State private var showValidation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            InteractionHeader(type: "STANDARD", status: "Ready")

            // Prompt display
            Text(fix.prompt)
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textPrimary)
                .lineSpacing(4)

            // Validation toggle
            VStack(alignment: .leading, spacing: 8) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showValidation.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(showValidation ? "v" : ">")
                            .font(EgoTheme.label())
                            .foregroundColor(.green)
                            .frame(width: 12)
                            .accessibilityHidden(true)

                        Text("VALIDATION")
                            .font(EgoTheme.label())
                            .foregroundColor(.green)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(showValidation ? "Hide validation" : "Show validation")
                .accessibilityHint("Toggles the validation criteria display")

                if showValidation {
                    Text(fix.validation)
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textMuted)
                        .lineSpacing(4)
                        .padding(.leading, 18)
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            // Inline comment
            InlineCommentView(comment: fix.inlineComment)
        }
        .interactionCard()
        .accessibilityLabel("Standard interaction")
    }
}

