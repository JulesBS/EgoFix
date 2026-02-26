import Foundation

/// Outcome-based color for contribution graph
enum OutcomeColor: String {
    case applied  // Green — fix applied
    case skipped  // Yellow — fix skipped
    case crash    // Red — crash or failed
    case opened   // Gray outline — opened but no action
    case empty    // No activity
}

/// Activity intensity level for a calendar day
enum ActivityIntensity: Int, Comparable {
    case none = 0
    case low = 1
    case medium = 2
    case high = 3

    static func < (lhs: ActivityIntensity, rhs: ActivityIntensity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Activity data for a single calendar day
struct CalendarDay: Identifiable {
    let id: Date  // Start of day (midnight)
    let fixesApplied: Int
    let fixesSkipped: Int
    let fixesFailed: Int
    let crashes: Int

    /// Total activity count
    var totalActivity: Int {
        fixesApplied + fixesSkipped + fixesFailed + crashes
    }

    /// Calculated intensity based on activity
    var intensity: ActivityIntensity {
        let total = totalActivity
        if total == 0 { return .none }
        if total <= 1 { return .low }
        if total <= 3 { return .medium }
        return .high
    }

    /// Whether day has any applied fixes
    var hasApplied: Bool {
        fixesApplied > 0
    }

    /// Primary outcome color for the day.
    /// Green = applied, Yellow = skipped, Red = crash/failed, Gray = opened but no action.
    var outcomeColor: OutcomeColor {
        if crashes > 0 || fixesFailed > 0 { return .crash }
        if fixesApplied > 0 { return .applied }
        if fixesSkipped > 0 { return .skipped }
        return .empty
    }

    /// Empty day
    static func empty(for date: Date) -> CalendarDay {
        CalendarDay(
            id: Calendar.current.startOfDay(for: date),
            fixesApplied: 0,
            fixesSkipped: 0,
            fixesFailed: 0,
            crashes: 0
        )
    }
}

/// Activity data for a calendar month
struct CalendarMonth: Identifiable {
    let id: Date  // First day of month
    let days: [CalendarDay]

    /// Month name (e.g., "January")
    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: id)
    }

    /// Year (e.g., 2026)
    var year: Int {
        Calendar.current.component(.year, from: id)
    }

    /// Short label (e.g., "Jan 2026")
    var shortLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: id)
    }
}
