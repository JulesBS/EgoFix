import SwiftUI

struct ObservationInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("OBSERVATION")
                    .font(EgoTheme.label())
                    .foregroundColor(.yellow)
                Spacer()
                Text("Notice & report")
                    .font(EgoTheme.label())
                    .foregroundColor(EgoTheme.textMuted)
            }

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
                    )
                    .shadow(color: isTextFieldFocused ? .yellow.opacity(0.3) : .clear, radius: 4, x: 0, y: 0)
                    .focused($isTextFieldFocused)
            }

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
