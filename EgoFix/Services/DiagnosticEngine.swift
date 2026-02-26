import Foundation

final class DiagnosticEngine {
    private let analyticsEventRepository: AnalyticsEventRepository
    private let weeklyDiagnosticRepository: WeeklyDiagnosticRepository
    private let patternRepository: PatternRepository
    private let bugRepository: BugRepository
    private let userRepository: UserRepository
    private let detectors: [PatternDetector]

    /// Days since last run before triggering diagnostics on app launch
    private let daysSinceLastRunThreshold = 7

    init(
        analyticsEventRepository: AnalyticsEventRepository,
        weeklyDiagnosticRepository: WeeklyDiagnosticRepository,
        patternRepository: PatternRepository,
        bugRepository: BugRepository,
        userRepository: UserRepository,
        detectors: [PatternDetector]
    ) {
        self.analyticsEventRepository = analyticsEventRepository
        self.weeklyDiagnosticRepository = weeklyDiagnosticRepository
        self.patternRepository = patternRepository
        self.bugRepository = bugRepository
        self.userRepository = userRepository
        self.detectors = detectors
    }

    /// Check if diagnostics should run based on time since last run.
    /// Returns true if never run or >7 days since last run.
    func shouldRunDiagnostics(for userId: UUID) async throws -> Bool {
        guard let user = try await userRepository.get() else { return false }

        guard let lastRun = user.lastDiagnosticsRunAt else {
            // Never run before
            return true
        }

        let calendar = Calendar.current
        let daysSinceLastRun = calendar.dateComponents([.day], from: lastRun, to: Date()).day ?? 0

        return daysSinceLastRun >= daysSinceLastRunThreshold
    }

    func runDiagnostics(for userId: UUID) async throws -> [DetectedPattern] {
        let events = try await analyticsEventRepository.getForUser(userId)
        let diagnostics = try await weeklyDiagnosticRepository.getForUser(userId)

        // Build bug names dictionary for personal copy
        let bugs = try await bugRepository.getAll()
        let bugNames: [UUID: String] = Dictionary(uniqueKeysWithValues: bugs.map { ($0.id, $0.title) })

        var detectedPatterns: [DetectedPattern] = []

        for detector in detectors {
            // Check if we have enough data points
            guard events.count >= detector.minimumDataPoints else { continue }

            // Check cooldown - don't surface same pattern type within 14 days
            let recentPatterns = try await patternRepository.getRecentByType(
                detector.patternType,
                for: userId,
                within: 14
            )
            guard recentPatterns.isEmpty else { continue }

            // Run detector
            if let pattern = detector.analyze(events: events, diagnostics: diagnostics, userId: userId, bugNames: bugNames) {
                detectedPatterns.append(pattern)
                try await patternRepository.save(pattern)
            }
        }

        // Update last diagnostics run timestamp
        if let user = try await userRepository.get() {
            user.lastDiagnosticsRunAt = Date()
            user.updatedAt = Date()
            try await userRepository.save(user)
        }

        return detectedPatterns
    }

    func getPatternToSurface(for userId: UUID) async throws -> DetectedPattern? {
        let unviewedPatterns = try await patternRepository.getUnviewed(for: userId)

        // Priority: alert > insight > observation
        let sortedPatterns = unviewedPatterns.sorted { p1, p2 in
            severityPriority(p1.severity) > severityPriority(p2.severity)
        }

        return sortedPatterns.first
    }

    func markPatternViewed(_ patternId: UUID) async throws {
        guard let pattern = try await patternRepository.getById(patternId) else { return }
        pattern.viewedAt = Date()
        try await patternRepository.save(pattern)
    }

    func dismissPattern(_ patternId: UUID) async throws {
        guard let pattern = try await patternRepository.getById(patternId) else { return }
        pattern.dismissedAt = Date()
        try await patternRepository.save(pattern)
    }

    private func severityPriority(_ severity: PatternSeverity) -> Int {
        switch severity {
        case .alert: return 3
        case .insight: return 2
        case .observation: return 1
        }
    }
}
