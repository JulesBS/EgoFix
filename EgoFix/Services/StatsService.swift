import Foundation

protocol StatsServiceProtocol {
    func calculateStreak(for userId: UUID) async throws -> StreakData
    func calculateStats(for userId: UUID) async throws -> UserStats
    func getCalendarActivity(for userId: UUID, months: Int) async throws -> [CalendarMonth]
}

final class StatsService: StatsServiceProtocol {
    private let fixCompletionRepository: FixCompletionRepository
    private let timerSessionRepository: TimerSessionRepository
    private let userRepository: UserRepository

    init(
        fixCompletionRepository: FixCompletionRepository,
        timerSessionRepository: TimerSessionRepository,
        userRepository: UserRepository
    ) {
        self.fixCompletionRepository = fixCompletionRepository
        self.timerSessionRepository = timerSessionRepository
        self.userRepository = userRepository
    }

    // MARK: - StatsServiceProtocol

    func calculateStreak(for userId: UUID) async throws -> StreakData {
        let completions = try await fixCompletionRepository.getForUser(userId)

        // Filter to only applied completions with a completedAt date
        let appliedDates = completions
            .filter { $0.outcome == .applied && $0.completedAt != nil }
            .compactMap { $0.completedAt }

        guard !appliedDates.isEmpty else {
            return .empty
        }

        let calendar = Calendar.current

        // Get unique dates (start of day) sorted descending
        let uniqueDates = Set(appliedDates.map { calendar.startOfDay(for: $0) })
            .sorted(by: >)

        let lastActiveDate = uniqueDates.first
        let today = calendar.startOfDay(for: Date())

        // Calculate current streak
        // Must start from today or yesterday to count as current
        var currentStreak = 0
        var streakStartDate: Date?

        if let firstDate = uniqueDates.first {
            // Check if first date is today or yesterday
            let daysSinceFirst = calendar.dateComponents([.day], from: firstDate, to: today).day ?? 0

            if daysSinceFirst <= 1 {
                // Start counting streak
                var checkDate = daysSinceFirst == 0 ? today : firstDate
                var dateIndex = 0

                while dateIndex < uniqueDates.count {
                    let date = uniqueDates[dateIndex]

                    if calendar.isDate(date, inSameDayAs: checkDate) {
                        currentStreak += 1
                        streakStartDate = date
                        dateIndex += 1

                        // Move to previous day
                        if let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) {
                            checkDate = previousDay
                        } else {
                            break
                        }
                    } else if date < checkDate {
                        // Gap in streak - stop counting
                        break
                    } else {
                        // Date is after check date - skip
                        dateIndex += 1
                    }
                }
            }
        }

        // Calculate longest streak by scanning all dates
        let sortedAscending = uniqueDates.reversed()
        var longestStreak = 0
        var tempStreak = 0
        var previousDate: Date?

        for date in sortedAscending {
            if let previous = previousDate {
                let daysBetween = calendar.dateComponents([.day], from: previous, to: date).day ?? 0

                if daysBetween == 1 {
                    tempStreak += 1
                } else {
                    longestStreak = max(longestStreak, tempStreak)
                    tempStreak = 1
                }
            } else {
                tempStreak = 1
            }
            previousDate = date
        }
        longestStreak = max(longestStreak, tempStreak)

        return StreakData(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastActiveDate: lastActiveDate,
            streakStartDate: streakStartDate
        )
    }

    func calculateStats(for userId: UUID) async throws -> UserStats {
        let completions = try await fixCompletionRepository.getForUser(userId)
        let timerSessions = try await timerSessionRepository.getAll()

        // Count by outcome
        var appliedCount = 0
        var skippedCount = 0
        var failedCount = 0

        for completion in completions {
            switch completion.outcome {
            case .applied: appliedCount += 1
            case .skipped: skippedCount += 1
            case .failed: failedCount += 1
            case .pending: break
            }
        }

        // Calculate days active (unique days with any completed fix)
        let calendar = Calendar.current
        let completedDates = completions
            .filter { $0.completedAt != nil }
            .compactMap { $0.completedAt }

        let uniqueDays = Set(completedDates.map { calendar.startOfDay(for: $0) })
        let daysActive = uniqueDays.count

        // Calculate peak hour and day from completedAt dates
        var hourCounts: [Int: Int] = [:]
        var dayOfWeekCounts: [Int: Int] = [:]

        for date in completedDates {
            let hour = calendar.component(.hour, from: date)
            let dayOfWeek = calendar.component(.weekday, from: date)

            hourCounts[hour, default: 0] += 1
            dayOfWeekCounts[dayOfWeek, default: 0] += 1
        }

        let peakHour = hourCounts.max(by: { $0.value < $1.value })?.key
        let peakDayOfWeek = dayOfWeekCounts.max(by: { $0.value < $1.value })?.key

        // Calculate total timer minutes from completed sessions
        let totalTimerSeconds = timerSessions
            .filter { $0.status == .completed }
            .reduce(0) { $0 + $1.durationSeconds }
        let totalTimerMinutes = totalTimerSeconds / 60

        return UserStats(
            totalFixesAssigned: completions.count,
            totalFixesApplied: appliedCount,
            totalFixesSkipped: skippedCount,
            totalFixesFailed: failedCount,
            totalTimerMinutes: totalTimerMinutes,
            daysActive: daysActive,
            peakHour: peakHour,
            peakDayOfWeek: peakDayOfWeek
        )
    }

    func getCalendarActivity(for userId: UUID, months: Int) async throws -> [CalendarMonth] {
        let completions = try await fixCompletionRepository.getForUser(userId)
        let calendar = Calendar.current

        // Get date range for requested months
        let today = Date()
        guard let startDate = calendar.date(byAdding: .month, value: -(months - 1), to: today) else {
            return []
        }
        let startOfFirstMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: startDate))!

        // Group completions by day
        var dayActivity: [Date: (applied: Int, skipped: Int, failed: Int)] = [:]

        for completion in completions {
            guard let completedAt = completion.completedAt else { continue }
            let dayStart = calendar.startOfDay(for: completedAt)

            var activity = dayActivity[dayStart] ?? (applied: 0, skipped: 0, failed: 0)
            switch completion.outcome {
            case .applied: activity.applied += 1
            case .skipped: activity.skipped += 1
            case .failed: activity.failed += 1
            case .pending: break
            }
            dayActivity[dayStart] = activity
        }

        // Build calendar months
        var calendarMonths: [CalendarMonth] = []
        var currentMonthStart = startOfFirstMonth

        for _ in 0..<months {
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonthStart) else { break }
            let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonthStart)!

            var days: [CalendarDay] = []
            for dayNumber in daysInMonth {
                guard let dayDate = calendar.date(byAdding: .day, value: dayNumber - 1, to: currentMonthStart) else { continue }
                let dayStart = calendar.startOfDay(for: dayDate)

                if let activity = dayActivity[dayStart] {
                    days.append(CalendarDay(
                        id: dayStart,
                        fixesApplied: activity.applied,
                        fixesSkipped: activity.skipped,
                        fixesFailed: activity.failed,
                        crashes: 0  // TODO: Add crash data if needed
                    ))
                } else {
                    days.append(.empty(for: dayStart))
                }
            }

            calendarMonths.append(CalendarMonth(id: currentMonthStart, days: days))
            currentMonthStart = nextMonth
        }

        return calendarMonths
    }
}
