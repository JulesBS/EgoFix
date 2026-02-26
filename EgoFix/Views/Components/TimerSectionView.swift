import SwiftUI

struct TimerSectionView: View {
    @ObservedObject var timerManager: FixTimerManager

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("TIMER")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.green)

                Spacer()

                Text(timerManager.formattedTime)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(timerColor)
                    .monospacedDigit()
            }

            // Progress bar (ASCII style)
            Text(timerManager.progressBarString)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(progressColor)

            // Control button
            HStack {
                Spacer()
                timerButton
                Spacer()
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

    @ViewBuilder
    private var timerButton: some View {
        switch timerManager.status {
        case .idle:
            Button(action: { Task { await timerManager.startTimer() } }) {
                Text("[ Start ]")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.green)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(2)
            }

        case .running:
            Button(action: { Task { await timerManager.pauseTimer() } }) {
                Text("[ Pause ]")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(2)
            }

        case .paused:
            HStack(spacing: 12) {
                Button(action: { Task { await timerManager.resumeTimer() } }) {
                    Text("[ Resume ]")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.green)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(2)
                }

                Button(action: { Task { await timerManager.resetTimer() } }) {
                    Text("[ Reset ]")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
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

    private var timerColor: Color {
        switch timerManager.status {
        case .idle:
            return Color(white: 0.6)
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
        switch timerManager.status {
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
}

// MARK: - Compact Timer View (for inline display)

struct CompactTimerView: View {
    @ObservedObject var timerManager: FixTimerManager

    var body: some View {
        HStack(spacing: 8) {
            statusIndicator

            Text(timerManager.formattedTime)
                .font(.system(.caption, design: .monospaced))
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
                .fill(Color(white: 0.4))
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
                .foregroundColor(.green)
        }
    }

    private var statusColor: Color {
        switch timerManager.status {
        case .idle: return Color(white: 0.5)
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
                .font(.system(.caption, design: .monospaced))
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
                .fill(Color(white: 0.4))
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
                .foregroundColor(.green)
        }
    }

    private var statusColor: Color {
        switch interactionManager.timerStatus {
        case .idle: return Color(white: 0.5)
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
