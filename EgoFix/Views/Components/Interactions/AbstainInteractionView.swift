import SwiftUI

struct AbstainInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ABSTAIN")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.red)
                Spacer()
                Text("Don't do the thing")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(Color(white: 0.5))
            }

            Text(fix.prompt)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)
                .lineSpacing(4)

            if let config = fix.abstainConfig {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.red)
                    Text(config.durationDescription)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.6))
                }

                Toggle(isOn: $interactionManager.abstainCompleted) {
                    Text("Period completed without slipping")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white)
                }
                .toggleStyle(SwitchToggleStyle(tint: .red))
            }

            if let comment = fix.inlineComment {
                Text("// \(comment)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Color(white: 0.35))
                    .italic()
            }
        }
        .padding(16)
        .background(Color(white: 0.06))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color(white: 0.15), lineWidth: 1)
        )
    }
}
