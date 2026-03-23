import SwiftUI

/// Morning briefing: teaser card showing bug, type, severity, time — but NOT the prompt.
/// The prompt is revealed on accept, creating a curiosity gap.
struct FixBriefingView: View {
    let fix: Fix
    let bugTitle: String?
    let bugSlug: String?
    let fixNumber: String
    let version: String
    let isReturningFix: Bool
    let onAccept: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Glass card: mission teaser
            VStack(alignment: .leading, spacing: 0) {
                // Fix number + version
                HStack {
                    Text("FIX / #\(fixNumber)")
                        .font(EgoTheme.label())
                        .tracking(1)
                        .foregroundColor(EgoTheme.textMuted)

                    Spacer()

                    Text("v\(version)")
                        .font(EgoTheme.label())
                        .tracking(1)
                        .foregroundColor(EgoTheme.textMuted)
                }
                .padding(.bottom, 20)

                // Bug name
                HStack(spacing: 8) {
                    Text("BUG")
                        .font(EgoTheme.label())
                        .tracking(1.5)
                        .foregroundColor(EgoTheme.textMuted)
                        .frame(width: 52, alignment: .leading)

                    Text(bugSlug ?? "unknown")
                        .font(EgoTheme.mono(.callout))
                        .foregroundColor(EgoTheme.textPrimary)
                }
                .padding(.bottom, 8)

                // Type label
                HStack(spacing: 8) {
                    Text("TYPE")
                        .font(EgoTheme.label())
                        .tracking(1.5)
                        .foregroundColor(EgoTheme.textMuted)
                        .frame(width: 52, alignment: .leading)

                    Text(fix.interactionType.typeLabel)
                        .font(EgoTheme.mono(.callout))
                        .foregroundColor(EgoTheme.textPrimary)
                }
                .padding(.bottom, 8)

                // Severity
                HStack(spacing: 8) {
                    Text("LEVEL")
                        .font(EgoTheme.label())
                        .tracking(1.5)
                        .foregroundColor(EgoTheme.textMuted)
                        .frame(width: 52, alignment: .leading)

                    severityBar
                }
                .padding(.bottom, 8)

                // Estimated time
                HStack(spacing: 8) {
                    Text("TIME")
                        .font(EgoTheme.label())
                        .tracking(1.5)
                        .foregroundColor(EgoTheme.textMuted)
                        .frame(width: 52, alignment: .leading)

                    Text(fix.interactionType.estimatedTime)
                        .font(EgoTheme.mono(.callout))
                        .foregroundColor(EgoTheme.textPrimary)
                }
                .padding(.bottom, 16)

                // Divider
                Rectangle()
                    .fill(EgoTheme.borderSubtle)
                    .frame(height: 0.5)
                    .padding(.bottom, 12)
                    .accessibilityHidden(true)

                // Type-flavored teaser comment
                Text(fix.interactionType.teaserComment)
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(EgoTheme.textMuted)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)

                // Returning fix indicator
                if isReturningFix {
                    Text("// You've seen this one before. Different day, same pattern.")
                        .font(EgoTheme.mono(.caption2))
                        .foregroundColor(EgoTheme.textMuted)
                        .italic()
                        .padding(.top, 6)
                }
            }
            .padding(24)
            .glassCard()
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Mission briefing: \(fix.interactionType.typeLabel) for \(bugSlug ?? "unknown"), \(fix.severity.rawValue) difficulty")

            // CTA: Accept Mission
            FigmaCTAButton(label: "ACCEPT MISSION", action: onAccept)
                .accessibilityHint("Accept today's mission and reveal the fix")

            // Secondary: Skip
            Button(action: onSkip) {
                Text("SKIP")
                    .font(EgoTheme.mono(.callout))
                    .tracking(1.4)
                    .foregroundColor(EgoTheme.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .overlay(
                        Rectangle()
                            .stroke(EgoTheme.borderSubtle, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Skip mission")
            .accessibilityHint("Skip today's mission without attempting it")
        }
    }

    // MARK: - Severity Bar

    private var severityFilled: Int {
        switch fix.severity {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }

    @ViewBuilder
    private var severityBar: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
                Rectangle()
                    .fill(i < severityFilled ? severityColor : EgoTheme.surface)
                    .frame(width: 16, height: 8)
                    .overlay(
                        Rectangle()
                            .stroke(i < severityFilled ? severityColor.opacity(0.6) : EgoTheme.border, lineWidth: 1)
                    )
            }

            Text(fix.severity.rawValue)
                .font(EgoTheme.mono(.caption2))
                .foregroundColor(EgoTheme.textMuted)
                .padding(.leading, 4)
        }
        .accessibilityLabel("Severity: \(fix.severity.rawValue)")
    }

    private var severityColor: Color {
        switch fix.severity {
        case .low: return EgoTheme.green
        case .medium: return EgoTheme.amber
        case .high: return .red
        }
    }
}
