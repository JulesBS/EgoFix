//
//  EgoFixWidgetLiveActivity.swift
//  EgoFixWidget
//
//  Created by Jules Bertron-Simpson on 28/01/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

// EgoFixWidgetAttributes is defined in Shared/LiveActivityAttributes.swift
// That file must be added to BOTH targets (EgoFix and EgoFixWidgetExtension)

// MARK: - Live Activity Widget

struct EgoFixWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EgoFixWidgetAttributes.self) { context in
            // Lock Screen / Banner view
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.8))
                .activitySystemActionForegroundColor(Color.green)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded regions
                DynamicIslandExpandedRegion(.leading) {
                    ExpandedLeadingView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ExpandedTrailingView(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(context: context)
                }
                DynamicIslandExpandedRegion(.center) {
                    ExpandedCenterView(context: context)
                }
            } compactLeading: {
                // Compact leading (left of notch)
                CompactLeadingView(context: context)
            } compactTrailing: {
                // Compact trailing (right of notch)
                CompactTrailingView(context: context)
            } minimal: {
                // Minimal view (when multiple activities)
                MinimalView(context: context)
            }
            .keylineTint(Color.green)
        }
    }
}

// MARK: - Lock Screen View

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<EgoFixWidgetAttributes>

    var body: some View {
        HStack(spacing: 16) {
            // Left: Fix info
            VStack(alignment: .leading, spacing: 4) {
                Text("FIX #\(context.attributes.fixNumber)")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.green)

                Text(context.attributes.fixPrompt)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(2)
            }

            Spacer()

            // Right: Timer
            VStack(alignment: .trailing, spacing: 4) {
                if context.state.isPaused {
                    Text("PAUSED")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.yellow)

                    Text(formatTime(context.state.remainingSeconds))
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                } else {
                    Text("TIMER")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.green)

                    Text(context.state.timerEndDate, style: .timer)
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .monospacedDigit()
                }
            }
        }
        .padding()
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Dynamic Island Expanded Views

struct ExpandedLeadingView: View {
    let context: ActivityViewContext<EgoFixWidgetAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("EGOFIX")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.green)

            Text("#\(context.attributes.fixNumber)")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.gray)
        }
    }
}

struct ExpandedTrailingView: View {
    let context: ActivityViewContext<EgoFixWidgetAttributes>

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if context.state.isPaused {
                Text("PAUSED")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.yellow)

                Text(formatTime(context.state.remainingSeconds))
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
            } else {
                Text(context.state.timerEndDate, style: .timer)
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .monospacedDigit()
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

struct ExpandedCenterView: View {
    let context: ActivityViewContext<EgoFixWidgetAttributes>

    var body: some View {
        // Progress indicator
        ProgressView(value: context.state.progress)
            .tint(context.state.isPaused ? .yellow : .green)
            .scaleEffect(y: 2)
    }
}

struct ExpandedBottomView: View {
    let context: ActivityViewContext<EgoFixWidgetAttributes>

    var body: some View {
        Text(context.attributes.fixPrompt)
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(.white)
            .lineLimit(2)
            .multilineTextAlignment(.center)
    }
}

// MARK: - Dynamic Island Compact Views

struct CompactLeadingView: View {
    let context: ActivityViewContext<EgoFixWidgetAttributes>

    var body: some View {
        Image(systemName: "terminal.fill")
            .font(.caption2)
            .foregroundColor(.green)
    }
}

struct CompactTrailingView: View {
    let context: ActivityViewContext<EgoFixWidgetAttributes>

    var body: some View {
        if context.state.isPaused {
            Text(formatTime(context.state.remainingSeconds))
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.yellow)
                .monospacedDigit()
        } else {
            Text(context.state.timerEndDate, style: .timer)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.green)
                .monospacedDigit()
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Dynamic Island Minimal View

struct MinimalView: View {
    let context: ActivityViewContext<EgoFixWidgetAttributes>

    var body: some View {
        // Show a simple timer or pause indicator
        if context.state.isPaused {
            Image(systemName: "pause.circle.fill")
                .font(.caption2)
                .foregroundColor(.yellow)
        } else {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)

                Circle()
                    .trim(from: 0, to: context.state.progress)
                    .stroke(Color.green, lineWidth: 2)
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 14, height: 14)
        }
    }
}

// MARK: - Preview

extension EgoFixWidgetAttributes {
    fileprivate static var preview: EgoFixWidgetAttributes {
        EgoFixWidgetAttributes(
            fixNumber: "1234",
            fixPrompt: "Let someone finish their point before responding. Count to 5.",
            totalDurationSeconds: 300
        )
    }
}

extension EgoFixWidgetAttributes.ContentState {
    fileprivate static var running: EgoFixWidgetAttributes.ContentState {
        EgoFixWidgetAttributes.ContentState(
            timerEndDate: Date().addingTimeInterval(180),
            isPaused: false,
            remainingSeconds: 180,
            progress: 0.4
        )
    }

    fileprivate static var paused: EgoFixWidgetAttributes.ContentState {
        EgoFixWidgetAttributes.ContentState(
            timerEndDate: Date(),
            isPaused: true,
            remainingSeconds: 120,
            progress: 0.6
        )
    }
}

#Preview("Notification", as: .content, using: EgoFixWidgetAttributes.preview) {
    EgoFixWidgetLiveActivity()
} contentStates: {
    EgoFixWidgetAttributes.ContentState.running
    EgoFixWidgetAttributes.ContentState.paused
}
