import Foundation

/// Computed streak data for a user's fix completion history
struct StreakData {
    /// Current consecutive days with at least one applied fix
    let currentStreak: Int

    /// Longest consecutive days streak ever achieved
    let longestStreak: Int

    /// Date of last applied fix
    let lastActiveDate: Date?

    /// Date when current streak started
    let streakStartDate: Date?

    /// Whether the user was active today
    var isActiveToday: Bool {
        guard let lastActive = lastActiveDate else { return false }
        return Calendar.current.isDateInToday(lastActive)
    }

    /// Whether streak is at risk (last active was yesterday, not today yet)
    var isStreakAtRisk: Bool {
        guard let lastActive = lastActiveDate else { return false }
        return Calendar.current.isDateInYesterday(lastActive)
    }

    /// Empty state
    static let empty = StreakData(
        currentStreak: 0,
        longestStreak: 0,
        lastActiveDate: nil,
        streakStartDate: nil
    )
}
