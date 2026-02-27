import Foundation

/// Provides randomized status lines for the Today view.
/// One line is picked per session and stays stable.
enum StatusLineProvider {

    enum StatusContext {
        case normal
        case postCrash
        case longStreak(Int)
        case firstDay
    }

    /// Returns a random status line appropriate for the given intensity, bug, and context.
    static func line(for intensity: BugIntensity, bugTitle: String, context: StatusContext) -> String {
        let pool: [String]

        switch context {
        case .postCrash:
            pool = postCrashLines(bugTitle: bugTitle)
        case .firstDay:
            pool = firstDayLines()
        case .longStreak(let days):
            pool = longStreakLines(days: days, bugTitle: bugTitle, intensity: intensity)
        case .normal:
            pool = normalLines(for: intensity, bugTitle: bugTitle)
        }

        return pool.randomElement() ?? "// System running."
    }

    // MARK: - Line pools

    private static func normalLines(for intensity: BugIntensity, bugTitle: String) -> [String] {
        switch intensity {
        case .quiet:
            return [
                "// \(bugTitle) is dormant. Enjoy the silence.",
                "// System running clean.",
                "// No crashes. Suspicious.",
                "// Low activity on this pattern.",
                "// Quiet doesn't mean gone.",
            ]
        case .present:
            return [
                "// \(bugTitle) is present. Watch for it today.",
                "// Running in the background.",
                "// Active but contained.",
                "// The pattern is warm. Not hot.",
                "// Detectable levels. Nothing alarming.",
            ]
        case .loud:
            return [
                "// \(bugTitle) is loud today.",
                "// High CPU usage on this pattern.",
                "// This is when the fixes matter most.",
                "// Elevated activity. The fix is calibrated for this.",
                "// Your ego is noisy. That's why you're here.",
            ]
        }
    }

    private static func postCrashLines(bugTitle: String) -> [String] {
        [
            "// Crash logged. Recovery mode.",
            "// \(bugTitle) won that round.",
            "// System restarting.",
        ]
    }

    private static func longStreakLines(days: Int, bugTitle: String, intensity: BugIntensity) -> [String] {
        // Mix streak-aware lines with normal intensity lines
        var lines = [
            "// \(days) days. Still here.",
            "// Day \(days). The work continues.",
        ]
        lines.append(contentsOf: normalLines(for: intensity, bugTitle: bugTitle))
        return lines
    }

    private static func firstDayLines() -> [String] {
        [
            "// First scan complete. Let's see what you're working with.",
            "// Day one. No data yet. That changes now.",
            "// System initialized. Monitoring begins.",
        ]
    }

    // MARK: - Streak milestone comments

    /// Returns a brief self-aware comment for specific streak milestones, or nil.
    static func streakMilestoneComment(for days: Int) -> String? {
        switch days {
        case 7: return "// This metric is meaningless."
        case 14: return "// You're still here."
        case 21: return "// Consistency is just a pattern. Like the others."
        case 30: return "// The app should be getting quieter by now."
        case 60: return "// Two months. You've outlasted most."
        case 90: return "// At this point, you're debugging the debugger."
        default: return nil
        }
    }

    /// Formats streak count for display.
    static func formatStreak(_ count: Int) -> String {
        switch count {
        case 0:
            return "\u{2219} 0"
        case 1...6:
            let dots = String(repeating: "\u{2219}", count: count)
            return "\(dots) \(count)"
        default:
            return "\(count) days"
        }
    }
}
