import SwiftUI

struct TimedInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("TIMER")
                    .font(EgoTheme.label())
                    .foregroundColor(EgoTheme.green)
                Spacer()
                Text(interactionManager.formattedTime)
                    .font(EgoTheme.mono(.title2))
                    .fontWeight(.bold)
                    .foregroundColor(timerColor)
                    .monospacedDigit()
            }

            // Progress bar (ASCII style)
            Text(interactionManager.progressBarString)
                .font(EgoTheme.mono(.caption))
                .foregroundColor(progressColor)

            // Control buttons
            HStack {
                Spacer()
                timerButton
                Spacer()
            }

            // Inline comment for duration
            if let config = fix.timedConfig {
                Text("// \(formatDuration(config.durationSeconds)) session")
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(EgoTheme.textMuted)
            }
        }
        .interactionCard(borderColor: borderColor)
    }

    // MARK: - Timer Button

    @ViewBuilder
    private var timerButton: some View {
        switch interactionManager.timerStatus {
        case .idle:
            Button(action: { Task { await interactionManager.startTimer() } }) {
                Text("[ Start ]")
                    .font(EgoTheme.mono(.callout))
                    .foregroundColor(.green)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(2)
            }
            .buttonStyle(PlainButtonStyle())

        case .running:
            Button(action: { Task { await interactionManager.pauseTimer() } }) {
                Text("[ Pause ]")
                    .font(EgoTheme.mono(.callout))
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(2)
            }
            .buttonStyle(PlainButtonStyle())

        case .paused:
            HStack(spacing: 12) {
                Button(action: { Task { await interactionManager.resumeTimer() } }) {
                    Text("[ Resume ]")
                        .font(EgoTheme.mono(.callout))
                        .foregroundColor(.green)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(2)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: { Task { await interactionManager.resetTimer() } }) {
                    Text("[ Reset ]")
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textMuted)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }

        case .completed:
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("COMPLETE")
                    .font(EgoTheme.mono(.callout))
                    .foregroundColor(.green)
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Computed Properties

    private var timerColor: Color {
        switch interactionManager.timerStatus {
        case .idle:
            return EgoTheme.textPrimary
        case .running:
            if interactionManager.remainingSeconds <= 10 {
                return .red
            }
            return .green
        case .paused:
            return .yellow
        case .completed:
            return .green
        }
    }

    private var progressColor: Color {
        switch interactionManager.timerStatus {
        case .idle:
            return EgoTheme.textMuted
        case .running:
            return .green.opacity(0.7)
        case .paused:
            return .yellow.opacity(0.7)
        case .completed:
            return .green
        }
    }

    private var borderColor: Color {
        switch interactionManager.timerStatus {
        case .idle:
            return EgoTheme.surface
        case .running:
            return .green.opacity(0.3)
        case .paused:
            return .yellow.opacity(0.3)
        case .completed:
            return .green.opacity(0.5)
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(remainingMinutes)m"
        }
        return "\(minutes)m"
    }
}

