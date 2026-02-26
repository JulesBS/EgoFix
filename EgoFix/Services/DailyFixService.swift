import Foundation

final class DailyFixService {
    private let fixRepository: FixRepository
    private let fixCompletionRepository: FixCompletionRepository
    private let userRepository: UserRepository
    private let analyticsEventRepository: AnalyticsEventRepository

    init(
        fixRepository: FixRepository,
        fixCompletionRepository: FixCompletionRepository,
        userRepository: UserRepository,
        analyticsEventRepository: AnalyticsEventRepository
    ) {
        self.fixRepository = fixRepository
        self.fixCompletionRepository = fixCompletionRepository
        self.userRepository = userRepository
        self.analyticsEventRepository = analyticsEventRepository
    }

    func getTodaysFix() async throws -> FixCompletion? {
        guard let user = try await userRepository.get() else { return nil }

        // Check if there's already a pending fix for today
        if let pending = try await fixCompletionRepository.getPending(for: user.id) {
            if Calendar.current.isDateInToday(pending.assignedAt) {
                return pending
            }
        }

        return nil
    }

    func assignDailyFix() async throws -> FixCompletion? {
        guard let user = try await userRepository.get() else { return nil }

        // Check for bug priorities first, fall back to legacy primaryBugId
        let priorities = user.bugPriorities
        guard !priorities.isEmpty || user.primaryBugId != nil else { return nil }

        // Don't assign if there's already a pending fix for today
        if let existingFix = try await getTodaysFix() {
            return existingFix
        }

        // Get completed fix IDs to exclude
        let completedIds = try await fixCompletionRepository.getCompletedFixIds(for: user.id)

        // Get a fix using weighted priorities or legacy single-bug approach
        let fix: Fix?
        if !priorities.isEmpty {
            fix = try await fixRepository.getWeightedDailyFix(priorities: priorities, excluding: completedIds)
        } else if let primaryBugId = user.primaryBugId {
            fix = try await fixRepository.getDailyFix(for: primaryBugId, excluding: completedIds)
        } else {
            fix = nil
        }

        guard let selectedFix = fix else { return nil }

        // Create the completion record
        let completion = FixCompletion(
            fixId: selectedFix.id,
            userId: user.id
        )
        try await fixCompletionRepository.save(completion)

        // Log analytics event
        let calendar = Calendar.current
        let event = AnalyticsEvent(
            userId: user.id,
            eventType: .fixAssigned,
            bugId: selectedFix.bugId,
            fixId: selectedFix.id,
            dayOfWeek: calendar.component(.weekday, from: Date()),
            hourOfDay: calendar.component(.hour, from: Date())
        )
        try await analyticsEventRepository.save(event)

        return completion
    }

    func markOutcome(_ completionId: UUID, outcome: FixOutcome, outcomeData: Data? = nil) async throws {
        guard let completion = try await fixCompletionRepository.getById(completionId),
              let user = try await userRepository.get() else { return }

        completion.outcome = outcome
        completion.outcomeData = outcomeData
        completion.completedAt = Date()
        completion.updatedAt = Date()
        try await fixCompletionRepository.save(completion)

        // Log analytics event (skip if still pending)
        guard outcome != .pending else { return }

        let calendar = Calendar.current
        let eventType: EventType
        switch outcome {
        case .applied: eventType = .fixApplied
        case .skipped: eventType = .fixSkipped
        case .failed: eventType = .fixFailed
        case .pending: return // Should not reach here due to guard
        }

        let event = AnalyticsEvent(
            userId: user.id,
            eventType: eventType,
            fixId: completion.fixId,
            dayOfWeek: calendar.component(.weekday, from: Date()),
            hourOfDay: calendar.component(.hour, from: Date())
        )
        try await analyticsEventRepository.save(event)
    }
}
