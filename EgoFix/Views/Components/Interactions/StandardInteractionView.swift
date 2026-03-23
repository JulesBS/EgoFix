import SwiftUI

struct StandardInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager

    @State private var showValidation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("STANDARD")
                    .font(EgoTheme.label())
                    .foregroundColor(.green)

                Spacer()

                Text("Ready")
                    .font(EgoTheme.label())
                    .foregroundColor(EgoTheme.textMuted)
            }

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

                        Text("VALIDATION")
                            .font(EgoTheme.label())
                            .foregroundColor(.green)
                    }
                }
                .buttonStyle(PlainButtonStyle())

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

