import Foundation

final class DiagnosticEngine {
    private let analyticsEventRepository: AnalyticsEventRepository
    private let weeklyDiagnosticRepository: WeeklyDiagnosticRepository
    private let patternRepository: PatternRepository
    private let detectors: [PatternDetector]

    init(
        analyticsEventRepository: AnalyticsEventRepository,
        weeklyDiagnosticRepository: WeeklyDiagnosticRepository,
        patternRepository: PatternRepository,
        detectors: [PatternDetector]
    ) {
        self.analyticsEventRepository = analyticsEventRepository
        self.weeklyDiagnosticRepository = weeklyDiagnosticRepository
        self.patternRepository = patternRepository
        self.detectors = detectors
    }

    func runDiagnostics(for userId: UUID) async throws -> [DetectedPattern] {
        let events = try await analyticsEventRepository.getForUser(userId)
        let diagnostics = try await weeklyDiagnosticRepository.getForUser(userId)

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
            if let pattern = detector.analyze(events: events, diagnostics: diagnostics, userId: userId) {
                detectedPatterns.append(pattern)
                try await patternRepository.save(pattern)
            }
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
