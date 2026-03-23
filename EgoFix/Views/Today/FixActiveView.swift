import SwiftUI

/// Active mission screen: prompt revealed, countdown timer, inline education,
/// interaction UI for interactive types, and 2-step outcome buttons.
struct FixActiveView: View {
    let fix: Fix
    let bugTitle: String?
    var missionEndDate: Date?
    var educationTeaser: String?
    var educationDeepDive: String?
    @ObservedObject var interactionManager: FixInteractionManager
    let onApplied: () -> Void
    let onSkipped: () -> Void
    let onFailed: () -> Void

    @State private var promptRevealed = false
    @State private var showDeepDive = false
    @State private var showDidntStep2 = false
    @State private var pulseOpacity: Double = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Primary glass card: mission content
            VStack(alignment: .leading, spacing: 0) {
                // Header: status + countdown
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(EgoTheme.green)
                            .frame(width: 6, height: 6)
                            .opacity(pulseOpacity)
                            .accessibilityHidden(true)

                        Text("MISSION / ACTIVE")
                            .font(EgoTheme.label())
                            .tracking(1.5)
                            .foregroundColor(EgoTheme.green)
                            .greenGlow()
                            .opacity(pulseOpacity)
                    }

                    Spacer()

                    // Countdown to mission end
                    if let endDate = missionEndDate {
                        TimelineView(.periodic(from: .now, by: 60)) { _ in
                            Text("⏱ \(formatRemaining(until: endDate))")
                                .font(EgoTheme.mono(.caption))
                                .foregroundColor(EgoTheme.textMuted)
                                .monospacedDigit()
                        }
                    }
                }
                .padding(.bottom, 16)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        pulseOpacity = 0.4
                    }
                }

                // Prompt (revealed with animation)
                Text(fix.prompt)
                    .font(.system(size: 18, weight: .light, design: .monospaced))
                    .foregroundColor(EgoTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(promptRevealed ? 1 : 0)
                    .offset(y: promptRevealed ? 0 : 8)

                // Inline comment
                if let comment = fix.inlineComment {
                    Rectangle()
                        .fill(EgoTheme.borderSubtle)
                        .frame(height: 0.5)
                        .padding(.vertical, 12)
                        .accessibilityHidden(true)

                    Text("// \(comment)")
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(promptRevealed ? 1 : 0)
                }
            }
            .padding(24)
            .glassCard()
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Active mission: \(fix.prompt)")

            // Interaction UI for interactive types
            interactionSection

            // Education section
            if educationTeaser != nil || educationDeepDive != nil {
                educationSection
            }

            // 2-step outcome buttons
            outcomeSection
        }
        .onAppear {
            // Animate prompt reveal
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                promptRevealed = true
            }
        }
    }

    // MARK: - Interaction Section

    @ViewBuilder
    private var interactionSection: some View {
        switch fix.interactionType {
        case .counter:
            FixInteractionView(fix: fix, interactionManager: interactionManager)
        case .substitute:
            FixInteractionView(fix: fix, interactionManager: interactionManager)
        case .body:
            FixInteractionView(fix: fix, interactionManager: interactionManager)
        case .abstain:
            FixInteractionView(fix: fix, interactionManager: interactionManager)
        default:
            EmptyView()
        }
    }

    // MARK: - Education Section

    @ViewBuilder
    private var educationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Teaser — always visible
            if let teaser = educationTeaser {
                Text(teaser)
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(EgoTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }

            // Read more toggle
            if let deepDive = educationDeepDive, !deepDive.isEmpty {
                Button(action: {
                    withAnimation(.easeOut(duration: 0.25)) {
                        showDeepDive.toggle()
                    }
                }) {
                    Text(showDeepDive ? "[ collapse ]" : "[ read more ]")
                        .font(EgoTheme.mono(.caption2))
                        .foregroundColor(EgoTheme.green.opacity(0.7))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showDeepDive ? "Collapse deep dive" : "Read more about this pattern")

                if showDeepDive {
                    Text(deepDive)
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textMuted.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - 2-Step Outcome Section

    @ViewBuilder
    private var outcomeSection: some View {
        VStack(spacing: 10) {
            if !showDidntStep2 {
                // Step 1: Applied / Didn't
                HStack(spacing: 10) {
                    Button(action: onApplied) {
                        Text("APPLIED")
                            .font(EgoTheme.mono(.callout))
                            .tracking(2)
                            .foregroundColor(EgoTheme.green)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(EgoTheme.surface)
                            .overlay(Rectangle().stroke(EgoTheme.green.opacity(0.4), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(!interactionManager.canMarkApplied)
                    .opacity(interactionManager.canMarkApplied ? 1 : 0.4)
                    .accessibilityLabel("Fix applied")

                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showDidntStep2 = true
                        }
                    }) {
                        Text("DIDN'T")
                            .font(EgoTheme.mono(.callout))
                            .tracking(1.4)
                            .foregroundColor(EgoTheme.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(EgoTheme.surface)
                            .overlay(Rectangle().stroke(EgoTheme.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Didn't apply fix")
                }
            } else {
                // Step 2: Didn't try / Tried, couldn't
                Text("// Both are data. Only one means the bug was active.")
                    .font(EgoTheme.mono(.caption2))
                    .foregroundColor(EgoTheme.textMuted)
                    .italic()
                    .padding(.bottom, 4)

                HStack(spacing: 10) {
                    Button(action: onSkipped) {
                        Text("DIDN'T TRY")
                            .font(EgoTheme.mono(.callout))
                            .tracking(1.4)
                            .foregroundColor(EgoTheme.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(EgoTheme.surface)
                            .overlay(Rectangle().stroke(EgoTheme.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Didn't try")
                    .accessibilityHint("Skipped this fix today")

                    Button(action: onFailed) {
                        Text("TRIED, COULDN'T")
                            .font(EgoTheme.mono(.callout))
                            .tracking(1.4)
                            .foregroundColor(.red.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(EgoTheme.surface)
                            .overlay(Rectangle().stroke(.red.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Tried but couldn't")
                    .accessibilityHint("The bug won this round")
                }

                // Back button
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showDidntStep2 = false
                    }
                }) {
                    Text("[ back ]")
                        .font(EgoTheme.mono(.caption2))
                        .foregroundColor(EgoTheme.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helpers

    private func formatRemaining(until date: Date) -> String {
        let interval = date.timeIntervalSince(Date())
        guard interval > 0 else { return "0m" }
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
