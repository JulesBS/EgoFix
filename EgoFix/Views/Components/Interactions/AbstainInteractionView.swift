import SwiftUI

struct AbstainInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            InteractionHeader(type: "ABSTAIN", status: statusText, typeColor: .red)

            Text(fix.prompt)
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textPrimary)
                .lineSpacing(4)

            if interactionManager.abstainTimerMode {
                timerSection
            } else {
                toggleSection
            }

            slipSection

            InlineCommentView(comment: fix.inlineComment)
        }
        .interactionCard(borderColor: borderColor)
        .accessibilityLabel("Abstain interaction, \(statusText)")
    }

    // MARK: - Timer Section

    @ViewBuilder
    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Time display
            HStack {
                Text(interactionManager.abstainFormattedTime)
                    .font(EgoTheme.heading(28))
                    .foregroundColor(timerColor)
                    .monospacedDigit()

                Spacer()

                if interactionManager.abstainCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(EgoTheme.green)
                        Text("COMPLETE")
                            .font(EgoTheme.label())
                            .foregroundColor(EgoTheme.green)
                            .tracking(1.5)
                    }
                }
            }

            // Progress bar
            Text(interactionManager.abstainProgressBarString)
                .font(EgoTheme.mono(.caption))
                .foregroundColor(progressColor)

            // Start button
            if !interactionManager.abstainTimerRunning && !interactionManager.abstainCompleted {
                HStack {
                    Spacer()
                    Button(action: { interactionManager.startAbstainTimer() }) {
                        Text("[ START ]")
                            .font(EgoTheme.mono(.callout))
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Start abstain timer")
                    Spacer()
                }
            }

            // Duration comment
            if let config = interactionManager.abstainConfig {
                Text("// \(config.durationDescription)")
                    .font(EgoTheme.mono(.caption2))
                    .foregroundColor(EgoTheme.textMuted)
                    .italic()
            }
        }
    }

    // MARK: - Toggle Section (fallback, no timer)

    @ViewBuilder
    private var toggleSection: some View {
        if let config = interactionManager.abstainConfig {
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(.red)
                Text(config.durationDescription)
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(EgoTheme.textPrimary)
            }

            Toggle(isOn: $interactionManager.abstainCompleted) {
                Text("Period completed without slipping")
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(EgoTheme.textPrimary)
            }
            .toggleStyle(SwitchToggleStyle(tint: .red))
            .accessibilityHint("Mark whether you completed the abstain period without slipping")
        }
    }

    // MARK: - Slip Section

    @ViewBuilder
    private var slipSection: some View {
        HStack(spacing: 8) {
            Button(action: { interactionManager.logAbstainSlip() }) {
                Text("[ SLIP ]")
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.08))
                    .cornerRadius(2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Log a slip")
            .accessibilityHint("Records that you slipped. The timer keeps going.")

            if !interactionManager.abstainSlips.isEmpty {
                Text("x\(interactionManager.abstainSlips.count)")
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(.red)
            }

            Spacer()
        }

        // Slip history
        if !interactionManager.abstainSlips.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(interactionManager.abstainSlips.enumerated()), id: \.offset) { index, slip in
                    Text("// slip \(index + 1) at \(formatSlipTime(slip.timestamp))")
                        .font(EgoTheme.mono(.caption2))
                        .foregroundColor(EgoTheme.textMuted)
                        .italic()
                }
            }
        }
    }

    // MARK: - Helpers

    private var statusText: String {
        if interactionManager.abstainCompleted { return "Completed" }
        if interactionManager.abstainTimerRunning { return "In progress" }
        if interactionManager.abstainTimerMode { return "Ready" }
        return "Don't do the thing"
    }

    private var timerColor: Color {
        if interactionManager.abstainCompleted { return EgoTheme.green }
        if interactionManager.abstainRemainingSeconds < 60 && interactionManager.abstainTimerRunning { return .red }
        return EgoTheme.textPrimary
    }

    private var progressColor: Color {
        if interactionManager.abstainCompleted { return EgoTheme.green }
        return .red.opacity(0.7)
    }

    private var borderColor: Color {
        if interactionManager.abstainCompleted { return EgoTheme.green.opacity(0.5) }
        if interactionManager.abstainTimerRunning { return Color.red.opacity(0.3) }
        return EgoTheme.border
    }

    private func formatSlipTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
