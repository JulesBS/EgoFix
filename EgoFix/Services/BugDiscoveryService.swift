import Foundation

/// Manages progressive bug discovery through crashes, debriefs, and patterns.
/// Bugs surface through behavior, not a quiz.
final class BugDiscoveryService {
    private let bugRepository: BugRepository
    private let userRepository: UserRepository
    private let fixCompletionRepository: FixCompletionRepository

    /// Hardcoded related bug pairings for debrief-based suggestions.
    static let relatedPairings: [String: String] = [
        "need-to-be-right": "need-to-control",
        "need-to-control": "need-to-be-right",
        "need-to-be-liked": "need-to-impress",
        "need-to-impress": "need-to-be-liked",
        "need-to-compare": "need-to-narrate",
        "need-to-narrate": "need-to-compare",
        "need-to-deflect": "need-to-be-liked",
    ]

    init(
        bugRepository: BugRepository,
        userRepository: UserRepository,
        fixCompletionRepository: FixCompletionRepository
    ) {
        self.bugRepository = bugRepository
        self.userRepository = userRepository
        self.fixCompletionRepository = fixCompletionRepository
    }

    // MARK: - Crash-Based Discovery (Day 4+)

    /// Get identified (inactive) bugs that could be activated during crash logging.
    func getIdentifiedBugs() async throws -> [Bug] {
        let allBugs = try await bugRepository.getAll()
        return allBugs.filter { $0.status == .identified && !$0.isActive }
    }

    /// Activate a previously identified bug (user taps it during crash).
    func activateBug(_ bugId: UUID) async throws {
        guard let bug = try await bugRepository.getById(bugId),
              let user = try await userRepository.get() else { return }

        bug.isActive = true
        bug.status = .active
        bug.activatedAt = Date()
        bug.updatedAt = Date()
        try await bugRepository.save(bug)

        // Add to user's bug priorities at the end
        var priorities = user.bugPriorities
        let nextRank = (priorities.map(\.rank).max() ?? 0) + 1
        priorities.append(BugPriority(bugId: bugId, rank: nextRank))
        user.bugPriorities = priorities
        try await userRepository.save(user)
    }

    // MARK: - Debrief-Based Suggestion (Day 7-8)

    /// Check if a related bug should be suggested based on completion history.
    /// Returns the suggested bug if conditions are met (7+ completions, < 2 active bugs).
    func checkForBugSuggestion(currentBugSlug: String) async throws -> Bug? {
        guard let user = try await userRepository.get() else { return nil }

        // Only suggest if user has < 2 active bugs
        let activeBugs = try await bugRepository.getAll().filter { $0.isActive }
        guard activeBugs.count < 2 else { return nil }

        // Need 7+ completed fixes
        let completions = try await fixCompletionRepository.getForUser(user.id)
        let completed = completions.filter { $0.outcome != .pending }
        guard completed.count >= 7 else { return nil }

        // Find the related bug
        guard let relatedSlug = Self.relatedPairings[currentBugSlug] else { return nil }

        let allBugs = try await bugRepository.getAll()
        let relatedBug = allBugs.first { $0.slug == relatedSlug && !$0.isActive }

        return relatedBug
    }

    // MARK: - Pattern-Based Discovery (Day 10+)

    /// Check if any identified bugs should be surfaced based on pattern detection.
    /// Called after pattern detection runs — if a pattern involves an identified bug,
    /// it can be offered for activation.
    func getActivatableBugsFromPatterns(patternBugIds: [UUID]) async throws -> [Bug] {
        var activatable: [Bug] = []
        for bugId in patternBugIds {
            if let bug = try await bugRepository.getById(bugId),
               bug.status == .identified && !bug.isActive {
                activatable.append(bug)
            }
        }
        return activatable
    }
}
