import SwiftUI

/// Post-outcome debrief screen with personalized insight.
struct DebriefView: View {
    let content: DebriefContent
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Text(content.title)
                    .font(.system(size: 18, weight: .light, design: .monospaced))
                    .foregroundColor(EgoTheme.green)
                    .greenGlow()
                    .padding(.bottom, 16)

                Text(content.body)
                    .font(EgoTheme.mono())
                    .foregroundColor(EgoTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
                    .padding(.bottom, 12)

                Text(content.comment)
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(EgoTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(24)
            .glassCard()
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)

            FigmaCTAButton(label: "CONTINUE", action: onDismiss)
                .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }
        }
    }
}
