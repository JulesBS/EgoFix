import SwiftUI

struct TimedInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("TIMER")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.green)

                Spacer()

                Text(interactionManager.formattedTime)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(timerColor)
                    .monospacedDigit()
            }

            // Progress bar (ASCII style)
            Text(interactionManager.progressBarString)
                .font(.system(.caption, design: .monospaced))
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
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Color(white: 0.35))
            }
        }
        .padding(16)
        .background(Color(white: 0.06))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    // MARK: - Timer Button

    @ViewBuilder
    private var timerButton: some View {
        switch interactionManager.timerStatus {
        case .idle:
            Button(action: { Task { await interactionManager.startTimer() } }) {
                Text("[ Start ]")
                    .font(.system(.subheadline, design: .monospaced))
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
                    .font(.system(.subheadline, design: .monospaced))
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
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.green)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(2)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: { Task { await interactionManager.resetTimer() } }) {
                    Text("[ Reset ]")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.5))
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
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.green)
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Computed Properties

    private var timerColor: Color {
        switch interactionManager.timerStatus {
        case .idle:
            return Color(white: 0.6)
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
            return Color(white: 0.3)
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
            return Color(white: 0.15)
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

