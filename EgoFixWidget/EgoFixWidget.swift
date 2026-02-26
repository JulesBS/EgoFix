//
//  EgoFixWidget.swift
//  EgoFixWidget
//
//  Created by Jules Bertron-Simpson on 28/01/2026.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct EgoFixProvider: TimelineProvider {
    private let storage = WidgetStorageManager.shared

    func placeholder(in context: Context) -> EgoFixEntry {
        EgoFixEntry(
            date: Date(),
            fixPrompt: "Loading your daily fix...",
            fixNumber: "0000",
            outcome: nil,
            timerState: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (EgoFixEntry) -> Void) {
        let entry = createEntry(from: storage.loadFixState())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EgoFixEntry>) -> Void) {
        let entry = createEntry(from: storage.loadFixState())

        // Refresh every 15 minutes or when timer would complete
        var nextUpdate = Date().addingTimeInterval(15 * 60)

        if let timerState = entry.timerState, !timerState.isPaused && !timerState.isCompleted {
            // Update more frequently during active timer
            nextUpdate = min(nextUpdate, timerState.endDate)
        }

        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func createEntry(from state: SharedFixState?) -> EgoFixEntry {
        guard let state = state, state.hasFixToday else {
            return EgoFixEntry(
                date: Date(),
                fixPrompt: nil,
                fixNumber: nil,
                outcome: nil,
                timerState: nil
            )
        }

        return EgoFixEntry(
            date: Date(),
            fixPrompt: state.fixPrompt,
            fixNumber: state.fixNumber,
            outcome: state.outcome,
            timerState: state.timer
        )
    }
}

// MARK: - Timeline Entry

struct EgoFixEntry: TimelineEntry {
    let date: Date
    let fixPrompt: String?
    let fixNumber: String?
    let outcome: String?
    let timerState: SharedTimerState?

    var hasActiveFix: Bool {
        fixPrompt != nil && outcome == "pending"
    }

    var isCompleted: Bool {
        outcome != nil && outcome != "pending"
    }

    var hasActiveTimer: Bool {
        guard let timer = timerState else { return false }
        return !timer.isCompleted && !timer.isPaused
    }
}

// MARK: - Widget

struct EgoFixWidget: Widget {
    let kind: String = "EgoFixWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EgoFixProvider()) { entry in
            EgoFixWidgetView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("EgoFix")
        .description("Track your daily fix and timer progress.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
    }
}

// MARK: - Widget Views

struct EgoFixWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: EgoFixEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .accessoryRectangular:
            RectangularLockScreenView(entry: entry)
        case .accessoryCircular:
            CircularLockScreenView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: EgoFixEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("EGOFIX")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.green)
                Spacer()
                if let number = entry.fixNumber {
                    Text("#\(number)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            if entry.isCompleted {
                completedView
            } else if entry.hasActiveFix {
                activeFixView
            } else {
                noFixView
            }
        }
        .padding()
    }

    private var completedView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: outcomeIcon)
                .font(.title2)
                .foregroundColor(outcomeColor)

            Text(outcomeLabel)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(outcomeColor)
        }
    }

    private var activeFixView: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let timer = entry.timerState, !timer.isCompleted {
                timerView(timer)
            } else {
                Text("FIX PENDING")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.yellow)
            }
        }
    }

    private var noFixView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("No fix today")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.gray)
        }
    }

    @ViewBuilder
    private func timerView(_ timer: SharedTimerState) -> some View {
        if timer.isPaused {
            VStack(alignment: .leading, spacing: 4) {
                Text("PAUSED")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.yellow)

                Text(formatTime(timer.remainingSeconds))
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text("TIMER")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.green)

                Text(timer.endDate, style: .timer)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .monospacedDigit()
            }
        }
    }

    private var outcomeIcon: String {
        switch entry.outcome {
        case "applied": return "checkmark.circle.fill"
        case "skipped": return "arrow.right.circle.fill"
        case "failed": return "xmark.circle.fill"
        default: return "circle"
        }
    }

    private var outcomeColor: Color {
        switch entry.outcome {
        case "applied": return .green
        case "skipped": return .yellow
        case "failed": return .red
        default: return .gray
        }
    }

    private var outcomeLabel: String {
        switch entry.outcome {
        case "applied": return "APPLIED"
        case "skipped": return "SKIPPED"
        case "failed": return "FAILED"
        default: return "PENDING"
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: EgoFixEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left side: Fix info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("EGOFIX")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.green)

                    if let number = entry.fixNumber {
                        Text("#\(number)")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }

                if let prompt = entry.fixPrompt {
                    Text(prompt)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(3)
                } else {
                    Text("No fix assigned today")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)
                }

                Spacer()
            }

            Spacer()

            // Right side: Status
            VStack(alignment: .trailing, spacing: 8) {
                if entry.isCompleted {
                    statusBadge
                } else if let timer = entry.timerState, !timer.isCompleted {
                    timerDisplay(timer)
                } else if entry.hasActiveFix {
                    Text("PENDING")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(4)
                }

                Spacer()
            }
        }
        .padding()
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: outcomeIcon)
                .font(.caption2)
            Text(outcomeLabel)
                .font(.system(.caption2, design: .monospaced))
        }
        .foregroundColor(outcomeColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(outcomeColor.opacity(0.2))
        .cornerRadius(4)
    }

    @ViewBuilder
    private func timerDisplay(_ timer: SharedTimerState) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            if timer.isPaused {
                Text("PAUSED")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.yellow)

                Text(formatTime(timer.remainingSeconds))
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
            } else {
                Text("TIMER")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.green)

                Text(timer.endDate, style: .timer)
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .monospacedDigit()
            }
        }
    }

    private var outcomeIcon: String {
        switch entry.outcome {
        case "applied": return "checkmark.circle.fill"
        case "skipped": return "arrow.right.circle.fill"
        case "failed": return "xmark.circle.fill"
        default: return "circle"
        }
    }

    private var outcomeColor: Color {
        switch entry.outcome {
        case "applied": return .green
        case "skipped": return .yellow
        case "failed": return .red
        default: return .gray
        }
    }

    private var outcomeLabel: String {
        switch entry.outcome {
        case "applied": return "APPLIED"
        case "skipped": return "SKIPPED"
        case "failed": return "FAILED"
        default: return "PENDING"
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Lock Screen Rectangular

struct RectangularLockScreenView: View {
    let entry: EgoFixEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("EGOFIX")
                    .font(.system(.caption2, design: .monospaced))
                    .fontWeight(.bold)

                Spacer()

                if let timer = entry.timerState, !timer.isCompleted && !timer.isPaused {
                    Text(timer.endDate, style: .timer)
                        .font(.system(.caption, design: .monospaced))
                        .monospacedDigit()
                }
            }

            if entry.isCompleted {
                Text(outcomeLabel)
                    .font(.system(.caption, design: .monospaced))
            } else if let prompt = entry.fixPrompt {
                Text(prompt)
                    .font(.system(.caption2, design: .monospaced))
                    .lineLimit(2)
            } else {
                Text("No fix today")
                    .font(.system(.caption2, design: .monospaced))
            }
        }
    }

    private var outcomeLabel: String {
        switch entry.outcome {
        case "applied": return "✓ Applied"
        case "skipped": return "→ Skipped"
        case "failed": return "✗ Failed"
        default: return "Pending"
        }
    }
}

// MARK: - Lock Screen Circular

struct CircularLockScreenView: View {
    let entry: EgoFixEntry

    var body: some View {
        ZStack {
            if let timer = entry.timerState, !timer.isCompleted {
                // Show timer progress
                Gauge(value: timer.progress) {
                    Text("FIX")
                        .font(.system(.caption2, design: .monospaced))
                }
                .gaugeStyle(.accessoryCircular)
            } else if entry.isCompleted {
                // Show outcome
                Image(systemName: outcomeIcon)
                    .font(.title2)
            } else if entry.hasActiveFix {
                // Show pending indicator
                Image(systemName: "terminal")
                    .font(.title2)
            } else {
                // No fix
                Image(systemName: "moon.zzz")
                    .font(.title2)
            }
        }
    }

    private var outcomeIcon: String {
        switch entry.outcome {
        case "applied": return "checkmark.circle.fill"
        case "skipped": return "arrow.right.circle.fill"
        case "failed": return "xmark.circle.fill"
        default: return "circle"
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    EgoFixWidget()
} timeline: {
    EgoFixEntry(
        date: Date(),
        fixPrompt: "Let someone finish their point before responding.",
        fixNumber: "1234",
        outcome: "pending",
        timerState: SharedTimerState(
            endDate: Date().addingTimeInterval(300),
            isPaused: false,
            isCompleted: false,
            durationSeconds: 600,
            remainingSeconds: 300
        )
    )
    EgoFixEntry(
        date: Date(),
        fixPrompt: "Notice when you compare yourself to others.",
        fixNumber: "5678",
        outcome: "applied",
        timerState: nil
    )
}
