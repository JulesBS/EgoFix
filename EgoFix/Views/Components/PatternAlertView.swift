import SwiftUI

struct PatternAlertView: View {
    let pattern: DetectedPattern
    let onAcknowledge: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("PATTERN DETECTED")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(severityColor)

            Text(pattern.title)
                .font(.system(.title3, design: .monospaced))
                .foregroundColor(.white)

            Text(pattern.body)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            HStack(spacing: 24) {
                Button(action: onAcknowledge) {
                    Text("[ Noted ]")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.gray)
                }

                Button(action: onDismiss) {
                    Text("[ Dismiss ]")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }

            Spacer()
        }
        .padding()
    }

    private var severityColor: Color {
        switch pattern.severity {
        case .alert: return .red
        case .insight: return .yellow
        case .observation: return .gray
        }
    }
}
