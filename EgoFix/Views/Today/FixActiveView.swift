import SwiftUI

/// Shown when the user reopens the app while a fix is active.
/// Minimal reminder with option to check in or log a crash.
struct FixActiveView: View {
    let fix: Fix
    let bugTitle: String?
    let onCheckIn: () -> Void
    let onCrash: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("FIX ACTIVE")
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
                Button(action: onCheckIn) {
                    Text("[ Check in ]")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.green)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(2)
                }

                Button(action: onCrash) {
                    Text("[ ! crash ]")
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 12)
                }
            }
        }
        .padding(.top, 8)
    }
}
