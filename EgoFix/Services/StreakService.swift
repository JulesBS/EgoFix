import Foundation

final class StreakService {
    private let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    /// Record engagement for today. Increments streak if consecutive day,
    /// resets if missed a day (unless freeze available).
    func recordEngagement(userId: UUID, date: Date = Date()) async throws {
        guard let user = try await userRepository.getById(userId) else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)

        // Reset weekly freeze if a new week started
        resetFreezeIfNewWeek(user: user, today: today, calendar: calendar)

        guard let lastDate = user.lastEngagementDate else {
            // First engagement ever
            user.currentStreak = 1
            user.longestStreak = max(user.longestStreak, 1)
            user.lastEngagementDate = today
            user.updatedAt = Date()
            try await userRepository.save(user)
            return
        }

        let lastDay = calendar.startOfDay(for: lastDate)

        if calendar.isDate(today, inSameDayAs: lastDay) {
            // Already engaged today, no change
            return
        }

        let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

        if daysBetween == 1 {
            // Consecutive day — increment streak
            user.currentStreak += 1
            user.longestStreak = max(user.longestStreak, user.currentStreak)
        } else if daysBetween == 2 && user.streakFreezeAvailable {
            // Missed exactly one day — use freeze
            user.streakFreezeAvailable = false
            user.currentStreak += 1
            user.longestStreak = max(user.longestStreak, user.currentStreak)
        } else {
            // Missed more than one day (or missed one with no freeze) — silent reset
            user.currentStreak = 1
        }

        user.lastEngagementDate = today
        user.updatedAt = Date()
        try await userRepository.save(user)
    }

    /// Get current streak info for display.
    func getStreakInfo(userId: UUID) async throws -> StreakInfo? {
        guard let user = try await userRepository.getById(userId) else { return nil }

        return StreakInfo(
            currentStreak: user.currentStreak,
            longestStreak: user.longestStreak,
            lastEngagementDate: user.lastEngagementDate,
            freezeAvailable: user.streakFreezeAvailable
        )
    }

    // MARK: - Private

    private func resetFreezeIfNewWeek(user: UserProfile, today: Date, calendar: Calendar) {
        guard let lastReset = user.lastFreezeResetDate else {
            // Never reset — set initial reset date
            user.lastFreezeResetDate = today
            user.streakFreezeAvailable = true
            return
        }

        let weeksBetween = calendar.dateComponents([.weekOfYear], from: lastReset, to: today).weekOfYear ?? 0
        if weeksBetween >= 1 {
            user.streakFreezeAvailable = true
            user.lastFreezeResetDate = today
        }
    }
}

struct StreakInfo {
    let currentStreak: Int
    let longestStreak: Int
    let lastEngagementDate: Date?
    let freezeAvailable: Bool
}
