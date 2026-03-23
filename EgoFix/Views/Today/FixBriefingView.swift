import SwiftUI

/// Morning briefing: shows today's fix for the user to accept or skip.
struct FixBriefingView: View {
    let fix: Fix
    let bugTitle: String?
    let onAccept: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Glass card: fix prompt + comment
            VStack(alignment: .leading, spacing: 0) {
                // Node label
                Text("FIX / #\(String(format: "%04d", abs(fix.id.hashValue) % 10000))")
                    .font(EgoTheme.label())
                    .tracking(1)
                    .foregroundColor(EgoTheme.textMuted)
                    .padding(.bottom, 16)

                // Prompt
                Text(fix.prompt)
                    .font(.system(size: 18, weight: .light, design: .monospaced))
                    .foregroundColor(EgoTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 16)

                // Divider
                if fix.inlineComment != nil {
                    Rectangle()
                        .fill(EgoTheme.borderSubtle)
                        .frame(height: 0.5)
                        .padding(.bottom, 12)
                        .accessibilityHidden(true)
                }

                // Inline comment
                if let comment = fix.inlineComment {
                    Text("// \(comment)")
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(24)
            .glassCard()
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Today's fix: \(fix.prompt)\(fix.inlineComment.map { ". \($0)" } ?? "")")

            // CTA: Accept
            FigmaCTAButton(label: "ACCEPT FIX", action: onAccept)
                .accessibilityHint("Accept today's fix and begin working on it")

            // Secondary: Skip
            FigmaSecondaryButton(label: "SKIP", action: onSkip)
                .accessibilityLabel("Skip fix")
                .accessibilityHint("Skip today's fix without attempting it")
        }
    }
}
