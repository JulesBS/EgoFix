import SwiftUI

/// Post-outcome debrief screen with personalized insight.
struct DebriefView: View {
    let content: DebriefContent
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 24) {
            Text(content.title)
                .font(.system(.headline, design: .monospaced))
                .foregroundColor(.green)
                .opacity(appeared ? 1 : 0)

            Text(content.body)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

            Text(content.comment)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(Color(white: 0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

            Button(action: onDismiss) {
                Text("[ Continue \u{2192} ]")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.gray)
                    .padding(.vertical, 12)
            }
            .opacity(appeared ? 1 : 0)
        }
        .padding(.top, 16)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }
        }
    }
}
