//
//  EgoFixWidget.swift
//  EgoFixWidget
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct EgoFixProvider: TimelineProvider {
    private let storage = WidgetStorageManager.shared

    func placeholder(in context: Context) -> EgoFixEntry {
        EgoFixEntry(date: Date(), state: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (EgoFixEntry) -> Void) {
        let entry = createEntry(from: storage.loadFixState())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EgoFixEntry>) -> Void) {
        let entry = createEntry(from: storage.loadFixState())

        // Refresh every 15 minutes, or at mission end for state transition
        var nextUpdate = Date().addingTimeInterval(15 * 60)

        if let timerState = entry.timerState, !timerState.isPaused && !timerState.isCompleted {
            nextUpdate = min(nextUpdate, timerState.endDate)
        }

        if let missionEnd = entry.missionEndDate, entry.missionState == "active" {
            nextUpdate = min(nextUpdate, missionEnd)
        }

        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func createEntry(from state: SharedFixState?) -> EgoFixEntry {
        guard let state = state, state.hasFixToday else {
            return EgoFixEntry(date: Date(), state: .noFix)
        }

        return EgoFixEntry(
            date: Date(),
            fixPrompt: state.fixPrompt,
            fixNumber: state.fixNumber,
            outcome: state.outcome,
            timerState: state.timer,
            missionState: state.missionState,
            bugSlug: state.bugSlug,
            typeLabel: state.typeLabel,
            severity: state.severity,
            missionEndDate: state.missionEndDate,
            inlineComment: state.inlineComment,
            educationTeaser: state.educationTeaser
        )
    }
}

// MARK: - Timeline Entry

struct EgoFixEntry: TimelineEntry {
    let date: Date
    var fixPrompt: String?
    var fixNumber: String?
    var outcome: String?
    var timerState: SharedTimerState?
    var missionState: String?
    var bugSlug: String?
    var typeLabel: String?
    var severity: String?
    var missionEndDate: Date?
    var inlineComment: String?
    var educationTeaser: String?

    enum DisplayState {
        case placeholder
        case noFix
        case waiting       // pre-accept: bug + type + severity
        case active        // accepted: prompt + countdown
        case checkIn       // wind-down: time to check in
        case done          // outcome marked
        case timer         // timed interaction (legacy)
    }

    var displayState: DisplayState {
        if missionState == "waiting" { return .waiting }
        if missionState == "checkIn" { return .checkIn }
        if missionState == "done" || (outcome != nil && outcome != "pending") { return .done }
        if missionState == "active" {
            // Check if mission time has passed
            if let endDate = missionEndDate, Date() > endDate {
                return .checkIn
            }
            return .active
        }
        if timerState != nil { return .timer }
        if fixPrompt != nil { return .active }
        return .noFix
    }

    // Convenience for placeholder init
    init(date: Date, state: DisplayState) {
        self.date = date
        switch state {
        case .placeholder:
            self.fixPrompt = "Loading..."
            self.fixNumber = "0000"
        default:
            break
        }
    }

    // Full init
    init(
        date: Date,
        fixPrompt: String? = nil,
        fixNumber: String? = nil,
        outcome: String? = nil,
        timerState: SharedTimerState? = nil,
        missionState: String? = nil,
        bugSlug: String? = nil,
        typeLabel: String? = nil,
        severity: String? = nil,
        missionEndDate: Date? = nil,
        inlineComment: String? = nil,
        educationTeaser: String? = nil
    ) {
        self.date = date
        self.fixPrompt = fixPrompt
        self.fixNumber = fixNumber
        self.outcome = outcome
        self.timerState = timerState
        self.missionState = missionState
        self.bugSlug = bugSlug
        self.typeLabel = typeLabel
        self.severity = severity
        self.missionEndDate = missionEndDate
        self.inlineComment = inlineComment
        self.educationTeaser = educationTeaser
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
        .description("Your daily mission at a glance.")
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

// MARK: - Small Widget (4 mission states)

struct SmallWidgetView: View {
    let entry: EgoFixEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
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

            switch entry.displayState {
            case .waiting:
                VStack(alignment: .leading, spacing: 4) {
                    if let type = entry.typeLabel {
                        Text(type)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    if let slug = entry.bugSlug {
                        Text(slug)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    Text("// Mission waiting.")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.gray)
                        .italic()
                }

            case .active:
                VStack(alignment: .leading, spacing: 4) {
                    if let endDate = entry.missionEndDate {
                        Text(endDate, style: .relative)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.green)
                            .monospacedDigit()
                    }
                    Text("ACTIVE")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.green)
                }

            case .checkIn:
                VStack(alignment: .leading, spacing: 4) {
                    Text("CHECK IN")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.yellow)
                    Text("// How'd it go?")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.gray)
                        .italic()
                }

            case .done:
                VStack(alignment: .leading, spacing: 4) {
                    Text(outcomeSymbol)
                        .font(.title2)
                        .foregroundColor(outcomeColor)
                    Text(outcomeLabel)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(outcomeColor)
                }

            case .timer:
                if let timer = entry.timerState, !timer.isCompleted {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(timer.endDate, style: .timer)
                            .font(.system(.title2, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(timer.isPaused ? .yellow : .green)
                            .monospacedDigit()
                        Text(timer.isPaused ? "PAUSED" : "TIMER")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(timer.isPaused ? .yellow : .green)
                    }
                }

            case .noFix, .placeholder:
                Text("// No fix today")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.gray)
                    .italic()
            }
        }
        .padding()
    }

    private var outcomeSymbol: String {
        switch entry.outcome {
        case "applied": return "+"
        case "skipped": return "~"
        case "failed": return "x"
        default: return "·"
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
        case "applied": return "// System stable."
        case "skipped": return "// No judgment."
        case "failed": return "// Bug won. Data logged."
        default: return "// Logged."
        }
    }
}

// MARK: - Medium Widget (4 mission states)

struct MediumWidgetView: View {
    let entry: EgoFixEntry

    var body: some View {
        HStack(spacing: 12) {
            // Left side
            VStack(alignment: .leading, spacing: 6) {
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

                switch entry.displayState {
                case .waiting:
                    if let slug = entry.bugSlug {
                        Text(slug)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    if let type = entry.typeLabel {
                        Text(type)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    Text("// Mission waiting.")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.gray)
                        .italic()

                case .active:
                    if let prompt = entry.fixPrompt {
                        Text(prompt)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.white)
                            .lineLimit(3)
                    }
                    if let comment = entry.inlineComment {
                        Text("// \(comment)")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .italic()
                    }

                case .checkIn:
                    if let prompt = entry.fixPrompt {
                        Text(prompt)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    Text("Time to check in.")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.yellow)

                case .done:
                    Text(outcomeLabel)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(outcomeColor)
                    Text(statusLine)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.gray)
                        .italic()

                case .timer:
                    if let prompt = entry.fixPrompt {
                        Text(prompt)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.white)
                            .lineLimit(3)
                    }

                case .noFix, .placeholder:
                    Text("No fix assigned today")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)
                }

                Spacer()
            }

            Spacer()

            // Right side: countdown or status
            VStack(alignment: .trailing, spacing: 4) {
                if entry.displayState == .active, let endDate = entry.missionEndDate {
                    Text(endDate, style: .relative)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.green)
                        .monospacedDigit()
                    Text("remaining")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.gray)
                } else if entry.displayState == .timer, let timer = entry.timerState, !timer.isCompleted {
                    Text(timer.endDate, style: .timer)
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(timer.isPaused ? .yellow : .green)
                        .monospacedDigit()
                } else if entry.displayState == .done {
                    Text(outcomeSymbol)
                        .font(.title)
                        .foregroundColor(outcomeColor)
                } else if entry.displayState == .waiting {
                    Text(severityDots)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(severityColor)
                }

                Spacer()
            }
        }
        .padding()
    }

    private var outcomeSymbol: String {
        switch entry.outcome {
        case "applied": return "+"
        case "skipped": return "~"
        case "failed": return "x"
        default: return "·"
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
        case "applied": return "+ applied"
        case "skipped": return "~ didn't try"
        case "failed": return "x tried, couldn't"
        default: return "· pending"
        }
    }

    private var statusLine: String {
        switch entry.outcome {
        case "applied": return "// System stable."
        case "skipped": return "// No judgment."
        case "failed": return "// Bug won. Data logged."
        default: return "// Logged."
        }
    }

    private var severityDots: String {
        switch entry.severity {
        case "low": return "█░░"
        case "medium": return "██░"
        case "high": return "███"
        default: return "░░░"
        }
    }

    private var severityColor: Color {
        switch entry.severity {
        case "low": return .green
        case "medium": return .yellow
        case "high": return .red
        default: return .gray
        }
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

                if entry.displayState == .active, let endDate = entry.missionEndDate {
                    Text(endDate, style: .relative)
                        .font(.system(.caption2, design: .monospaced))
                        .monospacedDigit()
                } else if entry.displayState == .timer,
                          let timer = entry.timerState, !timer.isCompleted && !timer.isPaused {
                    Text(timer.endDate, style: .timer)
                        .font(.system(.caption, design: .monospaced))
                        .monospacedDigit()
                }
            }

            switch entry.displayState {
            case .waiting:
                Text(entry.typeLabel ?? "Mission waiting")
                    .font(.system(.caption2, design: .monospaced))
                    .lineLimit(1)
            case .active:
                if let prompt = entry.fixPrompt {
                    Text(prompt)
                        .font(.system(.caption2, design: .monospaced))
                        .lineLimit(2)
                }
            case .checkIn:
                Text("Time to check in")
                    .font(.system(.caption2, design: .monospaced))
            case .done:
                Text(doneLabel)
                    .font(.system(.caption, design: .monospaced))
            default:
                Text("No fix today")
                    .font(.system(.caption2, design: .monospaced))
            }
        }
    }

    private var doneLabel: String {
        switch entry.outcome {
        case "applied": return "+ Applied"
        case "skipped": return "~ Skipped"
        case "failed": return "x Failed"
        default: return "Pending"
        }
    }
}

// MARK: - Lock Screen Circular

struct CircularLockScreenView: View {
    let entry: EgoFixEntry

    var body: some View {
        ZStack {
            switch entry.displayState {
            case .waiting:
                Image(systemName: "terminal")
                    .font(.title2)

            case .active:
                if let endDate = entry.missionEndDate {
                    // Mission countdown gauge
                    let total = max(1, endDate.timeIntervalSince(entry.date.addingTimeInterval(-12 * 3600)))
                    let remaining = max(0, endDate.timeIntervalSince(Date()))
                    let progress = 1.0 - (remaining / total)
                    Gauge(value: min(1, progress)) {
                        Text("FIX")
                            .font(.system(.caption2, design: .monospaced))
                    }
                    .gaugeStyle(.accessoryCircular)
                } else {
                    Image(systemName: "terminal.fill")
                        .font(.title2)
                }

            case .checkIn:
                Image(systemName: "exclamationmark.circle")
                    .font(.title2)

            case .done:
                Image(systemName: outcomeIcon)
                    .font(.title2)

            case .timer:
                if let timer = entry.timerState, !timer.isCompleted {
                    Gauge(value: timer.progress) {
                        Text("FIX")
                            .font(.system(.caption2, design: .monospaced))
                    }
                    .gaugeStyle(.accessoryCircular)
                }

            case .noFix, .placeholder:
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

#Preview(as: .systemMedium) {
    EgoFixWidget()
} timeline: {
    EgoFixEntry(
        date: Date(),
        fixNumber: "0042",
        missionState: "waiting",
        bugSlug: "need-to-be-right",
        typeLabel: "Something to notice",
        severity: "medium"
    )
    EgoFixEntry(
        date: Date(),
        fixPrompt: "Let someone finish a point you disagree with. Count to 5 before responding.",
        fixNumber: "0042",
        outcome: "pending",
        missionState: "active",
        bugSlug: "need-to-be-right",
        missionEndDate: Date().addingTimeInterval(6 * 3600),
        inlineComment: "The pause is the practice."
    )
    EgoFixEntry(
        date: Date(),
        fixPrompt: "Let someone finish a point you disagree with.",
        fixNumber: "0042",
        outcome: "applied",
        missionState: "done"
    )
}
