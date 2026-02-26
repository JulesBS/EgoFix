import Foundation

/// Service for managing bug lifecycle transitions.
/// - Identified -> Active: User selects bug during onboarding
/// - Active -> Stable: 4+ consecutive weeks of quiet diagnostics
/// - Stable -> Resolved: Manual user action
/// - Resolved -> Active: Regression detected (crash spike)
final class BugLifecycleService {
    private let bugRepository: BugRepository
    private let weeklyDiagnosticRepository: WeeklyDiagnosticRepository
    private let crashRepository: CrashRepository

    /// Number of consecutive quiet weeks required for Active -> Stable transition
    private let weeksForStable = 4

    /// Number of crashes in recent window to trigger regression
    private let crashThresholdForRegression = 3

    /// Days to look back for crash regression detection
    private let regressionWindowDays = 14

    init(
        bugRepository: BugRepository,
        weeklyDiagnosticRepository: WeeklyDiagnosticRepository,
        crashRepository: CrashRepository
    ) {
        self.bugRepository = bugRepository
        self.weeklyDiagnosticRepository = weeklyDiagnosticRepository
        self.crashRepository = crashRepository
    }

    // MARK: - Status Transitions

    /// Activate a bug (Identified -> Active). Called during onboarding.
    func activate(_ bugId: UUID) async throws {
        guard let bug = try await bugRepository.getById(bugId) else { return }
        guard bug.status == .identified else { return }

        bug.status = .active
        bug.isActive = true
        bug.activatedAt = Date()
        bug.updatedAt = Date()
        try await bugRepository.save(bug)
    }

    /// Mark a bug as resolved (Stable -> Resolved). Manual user action.
    func resolve(_ bugId: UUID) async throws {
        guard let bug = try await bugRepository.getById(bugId) else { return }
        guard bug.status == .stable else { return }

        bug.status = .resolved
        bug.isActive = false
        bug.resolvedAt = Date()
        bug.updatedAt = Date()
        try await bugRepository.save(bug)
    }

    /// Reactivate a resolved bug (Resolved -> Active). Called on regression detection.
    func reactivate(_ bugId: UUID) async throws {
        guard let bug = try await bugRepository.getById(bugId) else { return }
        guard bug.status == .resolved else { return }

        bug.status = .active
        bug.isActive = true
        bug.resolvedAt = nil
        bug.stableAt = nil
        bug.updatedAt = Date()
        try await bugRepository.save(bug)
    }

    /// Deactivate a bug (puts back to identified, clears timestamps)
    func deactivate(_ bugId: UUID) async throws {
        guard let bug = try await bugRepository.getById(bugId) else { return }

        bug.status = .identified
        bug.isActive = false
        bug.activatedAt = nil
        bug.stableAt = nil
        bug.resolvedAt = nil
        bug.updatedAt = Date()
        try await bugRepository.save(bug)
    }

    // MARK: - Lifecycle Checks

    /// Check if an active bug should transition to stable.
    /// Requires 4+ consecutive weeks of quiet diagnostics.
    func checkForStabilityTransition(bugId: UUID, userId: UUID) async throws -> Bool {
        guard let bug = try await bugRepository.getById(bugId) else { return false }
        guard bug.status == .active else { return false }

        let diagnostics = try await weeklyDiagnosticRepository.getRecent(for: userId, limit: weeksForStable)

        // Need at least 4 weeks of data
        guard diagnostics.count >= weeksForStable else { return false }

        // Check if all recent diagnostics show quiet intensity for this bug
        for diagnostic in diagnostics.prefix(weeksForStable) {
            guard let response = diagnostic.responses.first(where: { $0.bugId == bugId }) else {
                // Bug wasn't assessed this week - doesn't count as quiet
                return false
            }
            if response.intensity != .quiet {
                return false
            }
        }

        // Transition to stable
        bug.status = .stable
        bug.stableAt = Date()
        bug.updatedAt = Date()
        try await bugRepository.save(bug)
        return true
    }

    /// Check if a resolved bug should regress to active.
    /// Triggered by crash spike (3+ crashes in 14 days).
    func checkForRegression(bugId: UUID, userId: UUID) async throws -> Bool {
        guard let bug = try await bugRepository.getById(bugId) else { return false }
        guard bug.status == .resolved else { return false }

        let crashes = try await crashRepository.getForUser(userId)
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -regressionWindowDays, to: Date())!

        let recentCrashesForBug = crashes.filter { crash in
            crash.bugId == bugId && crash.crashedAt >= cutoffDate
        }

        if recentCrashesForBug.count >= crashThresholdForRegression {
            // Regression detected - reactivate
            bug.status = .active
            bug.isActive = true
            bug.resolvedAt = nil
            bug.stableAt = nil
            bug.updatedAt = Date()
            try await bugRepository.save(bug)
            return true
        }

        return false
    }

    /// Run all lifecycle checks for a user. Call after weekly diagnostic or crash logging.
    func runLifecycleChecks(userId: UUID) async throws -> [LifecycleTransition] {
        var transitions: [LifecycleTransition] = []

        let allBugs = try await bugRepository.getAll()

        // Check active bugs for stability
        let activeBugs = allBugs.filter { $0.status == .active }
        for bug in activeBugs {
            if try await checkForStabilityTransition(bugId: bug.id, userId: userId) {
                transitions.append(LifecycleTransition(
                    bugId: bug.id,
                    bugSlug: bug.slug,
                    from: .active,
                    to: .stable
                ))
            }
        }

        // Check resolved bugs for regression
        let resolvedBugs = allBugs.filter { $0.status == .resolved }
        for bug in resolvedBugs {
            if try await checkForRegression(bugId: bug.id, userId: userId) {
                transitions.append(LifecycleTransition(
                    bugId: bug.id,
                    bugSlug: bug.slug,
                    from: .resolved,
                    to: .active
                ))
            }
        }

        return transitions
    }

    // MARK: - Bug Info

    /// Get lifecycle info for display
    func getLifecycleInfo(for bug: Bug) -> BugLifecycleInfo {
        BugLifecycleInfo(
            id: bug.id,
            slug: bug.slug,
            title: bug.title,
            description: bug.bugDescription,
            status: bug.status,
            activatedAt: bug.activatedAt,
            stableAt: bug.stableAt,
            resolvedAt: bug.resolvedAt
        )
    }
}

// MARK: - Supporting Types

struct LifecycleTransition {
    let bugId: UUID
    let bugSlug: String
    let from: BugStatus
    let to: BugStatus
}

struct BugLifecycleInfo {
    let id: UUID
    let slug: String
    let title: String
    let description: String
    let status: BugStatus
    let activatedAt: Date?
    let stableAt: Date?
    let resolvedAt: Date?

    var statusLabel: String {
        switch status {
        case .identified: return "IDENTIFIED"
        case .active: return "ACTIVE"
        case .stable: return "STABLE"
        case .resolved: return "RESOLVED"
        }
    }

    var statusComment: String {
        switch status {
        case .identified: return "// Not yet tracked"
        case .active: return "// Currently being worked on"
        case .stable: return "// Consistently quiet. Consider resolving."
        case .resolved: return "// No longer active"
        }
    }

    var durationLabel: String? {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated

        switch status {
        case .active:
            guard let date = activatedAt else { return nil }
            return "active \(formatter.localizedString(for: date, relativeTo: Date()))"
        case .stable:
            guard let date = stableAt else { return nil }
            return "stable \(formatter.localizedString(for: date, relativeTo: Date()))"
        case .resolved:
            guard let date = resolvedAt else { return nil }
            return "resolved \(formatter.localizedString(for: date, relativeTo: Date()))"
        case .identified:
            return nil
        }
    }
}
