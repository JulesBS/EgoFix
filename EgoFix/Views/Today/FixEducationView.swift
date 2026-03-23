import SwiftUI

/// Shown after fix acceptance, before going into the day.
/// Surfaces the WHY behind the pattern — primes the user to notice it.
struct FixEducationView: View {
    let fix: Fix
    let bugTitle: String?
    let educationBody: String
    let onContinue: () -> Void

    @State private var showBody = false
    @State private var showButton = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Glass card: education content
            VStack(alignment: .leading, spacing: 0) {
                Text("// Before you go:")
                    .font(EgoTheme.label())
                    .foregroundColor(EgoTheme.textMuted)
                    .padding(.bottom, 16)

                Text(educationBody)
                    .font(EgoTheme.mono(.callout))
                    .foregroundColor(EgoTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
                    .opacity(showBody ? 1 : 0)
                    .offset(y: showBody ? 0 : 8)
            }
            .padding(24)
            .glassCard()
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Before you go: \(educationBody)")

            // CTA: Ready
            FigmaCTAButton(label: "READY", action: onContinue)
                .opacity(showButton ? 1 : 0)
                .accessibilityHint("Dismiss education and start today's fix")
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showBody = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(1.0)) {
                showButton = true
            }
        }
    }
}
