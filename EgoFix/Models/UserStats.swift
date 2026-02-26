import Foundation

/// Aggregated statistics for a user's fix completion history
struct UserStats {
    /// Total fixes assigned to the user
    let totalFixesAssigned: Int

    /// Total fixes marked as applied
    let totalFixesApplied: Int

    /// Total fixes marked as skipped
    let totalFixesSkipped: Int

    /// Total fixes marked as failed
    let totalFixesFailed: Int

    /// Total minutes spent on timed fixes
    let totalTimerMinutes: Int

    /// Number of unique days with activity
    let daysActive: Int

    /// Hour of day with most activity (0-23)
    let peakHour: Int?

    /// Day of week with most activity (1=Sunday, 7=Saturday)
    let peakDayOfWeek: Int?

    // MARK: - Computed Properties

    /// Success rate (applied / completed, excluding pending)
    var successRate: Double {
        let completed = totalFixesApplied + totalFixesSkipped + totalFixesFailed
        guard completed > 0 else { return 0 }
        return Double(totalFixesApplied) / Double(completed)
    }

    /// Success rate as percentage string
    var successRateFormatted: String {
        String(format: "%.0f%%", successRate * 100)
    }

    /// Total timer hours formatted
    var totalTimerFormatted: String {
        let hours = Double(totalTimerMinutes) / 60.0
        if hours < 1 {
            return "\(totalTimerMinutes) min"
        } else {
            return String(format: "%.1f hrs", hours)
        }
    }

    /// Peak time formatted (e.g., "Tue @ 08:00")
    var peakTimeFormatted: String? {
        guard let hour = peakHour, let day = peakDayOfWeek else { return nil }

        let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let dayName = dayNames[day]
        let hourFormatted = String(format: "%02d:00", hour)

        return "\(dayName) @ \(hourFormatted)"
    }

    /// Empty state
    static let empty = UserStats(
        totalFixesAssigned: 0,
        totalFixesApplied: 0,
        totalFixesSkipped: 0,
        totalFixesFailed: 0,
        totalTimerMinutes: 0,
        daysActive: 0,
        peakHour: nil,
        peakDayOfWeek: nil
    )
}
