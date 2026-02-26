import SwiftUI

struct SubstituteInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SUBSTITUTE")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.orange)
                Spacer()
                Text("Replace the pattern")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(Color(white: 0.5))
            }

            Text(fix.prompt)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)
                .lineSpacing(4)

            if let config = fix.substituteConfig {
                VStack(alignment: .leading, spacing: 6) {
                    Text("WHEN: \(config.triggerBehavior)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.red)
                    Text("DO: \(config.replacementBehavior)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.green)
                }
                .padding(8)
                .background(Color(white: 0.08))
                .cornerRadius(2)

                HStack(spacing: 16) {
                    VStack {
                        Text("\(interactionManager.substituteCount)")
                            .font(.system(.title2, design: .monospaced))
                            .foregroundColor(.green)
                        Text("substituted")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(Color(white: 0.5))
                    }

                    VStack {
                        Text("\(interactionManager.urgeCount)")
                            .font(.system(.title2, design: .monospaced))
                            .foregroundColor(.orange)
                        Text("urges")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(Color(white: 0.5))
                    }
                }

                HStack(spacing: 8) {
                    Button("+urge") {
                        interactionManager.urgeCount += 1
                    }
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(.orange, lineWidth: 1))

                    Button("+substituted") {
                        interactionManager.substituteCount += 1
                    }
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(.green, lineWidth: 1))
                }
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
