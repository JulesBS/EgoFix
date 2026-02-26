import Foundation

final class WeeklyDiagnosticService {
    private let weeklyDiagnosticRepository: WeeklyDiagnosticRepository
    private let bugRepository: BugRepository
    private let userRepository: UserRepository
    private let analyticsEventRepository: AnalyticsEventRepository

    private let maxBugsPerDiagnostic = 3

    init(
        weeklyDiagnosticRepository: WeeklyDiagnosticRepository,
        bugRepository: BugRepository,
        userRepository: UserRepository,
        analyticsEventRepository: AnalyticsEventRepository
    ) {
        self.weeklyDiagnosticRepository = weeklyDiagnosticRepository
        self.bugRepository = bugRepository
        self.userRepository = userRepository
        self.analyticsEventRepository = analyticsEventRepository
    }

    func shouldPromptDiagnostic() async throws -> Bool {
        guard let user = try await userRepository.get() else { return false }

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())

        // Prompt on Sunday (1) or Monday (2)
        guard weekday == 1 || weekday == 2 else { return false }

        // Check if already completed this week
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!

        if let existing = try await weeklyDiagnosticRepository.getForWeek(starting: startOfWeek, userId: user.id) {
            return false
        }

        return true
    }

    func getBugsForDiagnostic() async throws -> [Bug] {
        guard let user = try await userRepository.get() else { return [] }

        let activeBugs = try await bugRepository.getActive()

        // If more than max, rotate based on recent diagnostics
        if activeBugs.count <= maxBugsPerDiagnostic {
            return activeBugs
        }

        // Get recent diagnostics to see which bugs were recently assessed
        let recentDiagnostics = try await weeklyDiagnosticRepository.getRecent(for: user.id, limit: 4)
        let recentlyAssessedBugIds = Set(recentDiagnostics.flatMap { $0.responses.map { $0.bugId } })

        // Prioritize bugs that haven't been recently assessed
        let unassessedBugs = activeBugs.filter { !recentlyAssessedBugIds.contains($0.id) }

        if unassessedBugs.count >= maxBugsPerDiagnostic {
            return Array(unassessedBugs.prefix(maxBugsPerDiagnostic))
        }

        // Fill remaining slots with recently assessed bugs
        var result = unassessedBugs
        let remaining = activeBugs.filter { recentlyAssessedBugIds.contains($0.id) }
        result.append(contentsOf: remaining.prefix(maxBugsPerDiagnostic - result.count))

        return Array(result.prefix(maxBugsPerDiagnostic))
    }

    func submitDiagnostic(responses: [BugDiagnosticResponse]) async throws {
        guard let user = try await userRepository.get() else { return }

        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!

        let diagnostic = WeeklyDiagnostic(
            userId: user.id,
            weekStarting: startOfWeek,
            responses: responses
        )
        try await weeklyDiagnosticRepository.save(diagnostic)

        // Log analytics event
        let event = AnalyticsEvent(
            userId: user.id,
            eventType: .weeklyCompleted,
            dayOfWeek: calendar.component(.weekday, from: Date()),
            hourOfDay: calendar.component(.hour, from: Date())
        )
        try await analyticsEventRepository.save(event)
    }

    func skipDiagnostic() async throws {
        // No action needed - user can always skip without guilt
    }
}
