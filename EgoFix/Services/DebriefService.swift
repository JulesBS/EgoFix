import Foundation

final class DebriefService {
    private let fixCompletionRepository: FixCompletionRepository
    private let bugRepository: BugRepository

    init(
        fixCompletionRepository: FixCompletionRepository,
        bugRepository: BugRepository
    ) {
        self.fixCompletionRepository = fixCompletionRepository
        self.bugRepository = bugRepository
    }

    /// Generate a debrief based on the user's history and current outcome.
    func generateDebrief(
        bugSlug: String,
        bugLabel: String,
        userId: UUID,
        lastOutcome: FixOutcome
    ) async -> DebriefContent? {
        let completions = (try? await fixCompletionRepository.getForUser(userId)) ?? []
        let completedCompletions = completions.filter { $0.outcome != .pending }
        let totalCompleted = completedCompletions.count

        // 1. Milestone?
        if let milestone = milestoneDebrief(fixCount: totalCompleted) {
            return milestone
        }

        // 2. Comparison to self (5+ completions for this bug)
        let bugCompletions = await bugCompletionCount(
            userId: userId,
            bugSlug: bugSlug,
            completions: completions
        )
        if bugCompletions >= 5 {
            let applied = await bugApplyCount(userId: userId, bugSlug: bugSlug, completions: completions)
            return DebriefContent(
                title: "DEBRIEF",
                body: "\(outcomeVerb(lastOutcome)) today. Your apply rate on \(bugLabel) is \(applied)/\(bugCompletions).",
                comment: applied > bugCompletions / 2
                    ? "// That's trending up."
                    : "// The data doesn't judge. It just counts.",
                template: .comparisonToSelf
            )
        }

        // 3. Tomorrow preview (default)
        return DebriefContent(
            title: "DEBRIEF",
            body: "\(outcomeVerb(lastOutcome)) today. Tomorrow's fix will account for this.",
            comment: "// One day at a time.",
            template: .tomorrowPreview
        )
    }

    // MARK: - Templates

    private func milestoneDebrief(fixCount: Int) -> DebriefContent? {
        let milestones = [5, 10, 14, 21, 30, 50, 75, 100]
        guard milestones.contains(fixCount) else { return nil }

        let body: String
        let comment: String

        switch fixCount {
        case 5:
            body = "Fix #5. First week."
            comment = "// Most people quit by now."
        case 10:
            body = "Fix #10. Double digits."
            comment = "// The patterns are starting to notice you too."
        case 14:
            body = "Fix #14. Two weeks."
            comment = "// The app should be getting quieter by now. Is it?"
        case 21:
            body = "Fix #21. Three weeks."
            comment = "// At this point, you're not fixing the bugs. You're seeing them."
        case 30:
            body = "Fix #30. One month."
            comment = "// That's a lot of looking at yourself."
        case 50:
            body = "Fix #50."
            comment = "// You're still here. That says something."
        case 75:
            body = "Fix #75."
            comment = "// No badge. No trophy. Just you, slightly different."
        case 100:
            body = "Fix #100."
            comment = "// v2.0 territory."
        default:
            return nil
        }

        return DebriefContent(
            title: "DEBRIEF",
            body: body,
            comment: comment,
            template: .milestone
        )
    }

    private func bugCompletionCount(
        userId: UUID,
        bugSlug: String,
        completions: [FixCompletion]
    ) async -> Int {
        var count = 0
        for completion in completions where completion.outcome != .pending {
            if let _ = try? await fixCompletionRepository.getById(completion.id),
               let bugId = try? await resolveBugId(fixId: completion.fixId),
               let bug = try? await bugRepository.getById(bugId),
               bug.slug == bugSlug {
                count += 1
            }
        }
        return count
    }

    private func bugApplyCount(
        userId: UUID,
        bugSlug: String,
        completions: [FixCompletion]
    ) async -> Int {
        var count = 0
        for completion in completions where completion.outcome == .applied {
            if let bugId = try? await resolveBugId(fixId: completion.fixId),
               let bug = try? await bugRepository.getById(bugId),
               bug.slug == bugSlug {
                count += 1
            }
        }
        return count
    }

    private func resolveBugId(fixId: UUID) async throws -> UUID? {
        // We don't have direct access to FixRepository here, so this is a simplified approach.
        // In production, the bugId could be stored on the completion or passed in.
        return nil
    }

    private func outcomeVerb(_ outcome: FixOutcome) -> String {
        switch outcome {
        case .applied: return "Applied"
        case .skipped: return "Skipped"
        case .failed: return "Crashed"
        case .pending: return "Logged"
        }
    }
}
