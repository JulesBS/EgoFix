import SwiftUI

/// Morning briefing: shows today's fix for the user to accept or skip.
struct FixBriefingView: View {
    let fix: Fix
    let bugTitle: String?
    let onAccept: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("TODAY'S FIX")
                .font(.system(.headline, design: .monospaced))
                .foregroundColor(.green)

            Text(fix.prompt)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            if let comment = fix.inlineComment {
                Text("// \(comment)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Color(white: 0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            HStack(spacing: 24) {
                Button(action: onAccept) {
                    Text("[ Accept fix ]")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.green)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(2)
                }

                Button(action: onSkip) {
                    Text("[ Skip ]")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.gray)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                }
            }
        }
        .padding(.top, 8)
    }
}
