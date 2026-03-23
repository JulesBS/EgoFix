import SwiftUI

struct TimerSectionView: View {
    @ObservedObject var timerManager: FixTimerManager

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("TIMER")
                    .font(EgoTheme.label())
                    .foregroundColor(EgoTheme.green)

                Spacer()

                Text(timerManager.formattedTime)
                    .font(EgoTheme.mono(.title2))
                    .fontWeight(.bold)
                    .foregroundColor(timerColor)
                    .monospacedDigit()
            }

            // Progress bar (ASCII style)
            Text(timerManager.progressBarString)
                .font(EgoTheme.mono(.caption))
                .foregroundColor(progressColor)

            // Control button
            HStack {
                Spacer()
                timerButton
                Spacer()
            }
        }
        .padding(16)
        .background(EgoTheme.surface.opacity(0.3))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var timerButton: some View {
        switch timerManager.status {
        case .idle:
            Button(action: { Task { await timerManager.startTimer() } }) {
                Text("[ Start ]")
                    .font(EgoTheme.mono(.callout))
                    .foregroundColor(EgoTheme.green)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(2)
            }

        case .running:
            Button(action: { Task { await timerManager.pauseTimer() } }) {
                Text("[ Pause ]")
                    .font(EgoTheme.mono(.callout))
                    .foregroundColor(EgoTheme.amber)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(2)
            }

        case .paused:
            HStack(spacing: 12) {
                Button(action: { Task { await timerManager.resumeTimer() } }) {
                    Text("[ Resume ]")
                        .font(EgoTheme.mono(.callout))
                        .foregroundColor(EgoTheme.green)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(2)
                }

                Button(action: { Task { await timerManager.resetTimer() } }) {
                    Text("[ Reset ]")
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textMuted)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
            }

        case .completed:
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(EgoTheme.green)
                Text("COMPLETE")
                    .font(EgoTheme.mono(.callout))
                    .foregroundColor(EgoTheme.green)
            }
            .padding(.vertical, 8)
        }
    }

    private var timerColor: Color {
        switch timerManager.status {
        case .idle:
            return EgoTheme.textPrimary
        case .running:
            // Pulse effect when low time
            if timerManager.remainingSeconds <= 10 {
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
        switch timerManager.status {
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
        switch timerManager.status {
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
}

// MARK: - Compact Timer View (for inline display)

struct CompactTimerView: View {
    @ObservedObject var timerManager: FixTimerManager

    var body: some View {
        HStack(spacing: 8) {
            statusIndicator

            Text(timerManager.formattedTime)
                .font(EgoTheme.mono(.caption))
                .fontWeight(.medium)
                .foregroundColor(statusColor)
                .monospacedDigit()

            if timerManager.isRunning {
                // Animated dots
                TypingIndicator()
            }
        }
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch timerManager.status {
        case .idle:
            Circle()
                .fill(EgoTheme.textMuted)
                .frame(width: 6, height: 6)
        case .running:
            Circle()
                .fill(Color.green)
                .frame(width: 6, height: 6)
        case .paused:
            Circle()
                .fill(Color.yellow)
                .frame(width: 6, height: 6)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 10))
                .foregroundColor(EgoTheme.green)
        }
    }

    private var statusColor: Color {
        switch timerManager.status {
        case .idle: return EgoTheme.textMuted
        case .running: return .green
        case .paused: return .yellow
        case .completed: return .green
        }
    }
}

// MARK: - Compact Timer View (for FixInteractionManager)

struct CompactInteractionTimerView: View {
    @ObservedObject var interactionManager: FixInteractionManager

    var body: some View {
        HStack(spacing: 8) {
            statusIndicator

            Text(interactionManager.formattedTime)
                .font(EgoTheme.mono(.caption))
                .fontWeight(.medium)
                .foregroundColor(statusColor)
                .monospacedDigit()

            if interactionManager.isTimerRunning {
                TypingIndicator()
            }
        }
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch interactionManager.timerStatus {
        case .idle:
            Circle()
                .fill(EgoTheme.textMuted)
                .frame(width: 6, height: 6)
        case .running:
            Circle()
                .fill(Color.green)
                .frame(width: 6, height: 6)
        case .paused:
            Circle()
                .fill(Color.yellow)
                .frame(width: 6, height: 6)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 10))
                .foregroundColor(EgoTheme.green)
        }
    }

    private var statusColor: Color {
        switch interactionManager.timerStatus {
        case .idle: return EgoTheme.textMuted
        case .running: return .green
        case .paused: return .yellow
        case .completed: return .green
        }
    }
}

// MARK: - Typing Indicator Animation

struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.green.opacity(0.5))
                    .frame(width: 3, height: 3)
                    .opacity(animating ? 1 : 0.3)
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(index) * 0.15),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}
