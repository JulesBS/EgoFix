import SwiftUI

struct AbstainInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ABSTAIN")
                    .font(EgoTheme.label())
                    .foregroundColor(.red)
                Spacer()
                Text("Don't do the thing")
                    .font(EgoTheme.label())
                    .foregroundColor(EgoTheme.textMuted)
            }

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
