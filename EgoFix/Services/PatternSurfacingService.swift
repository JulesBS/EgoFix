import Foundation

final class PatternSurfacingService {
    private let diagnosticEngine: DiagnosticEngine
    private let analyticsEventRepository: AnalyticsEventRepository
    private let userRepository: UserRepository

    private var sessionPatternShown = false

    init(
        diagnosticEngine: DiagnosticEngine,
        analyticsEventRepository: AnalyticsEventRepository,
        userRepository: UserRepository
    ) {
        self.diagnosticEngine = diagnosticEngine
        self.analyticsEventRepository = analyticsEventRepository
        self.userRepository = userRepository
    }

    func resetSession() {
        sessionPatternShown = false
    }

    func shouldShowPatternBeforeFix() async throws -> DetectedPattern? {
        guard !sessionPatternShown else { return nil }

        guard let pattern = try await diagnosticEngine.getPatternToSurface(
            for: try await getCurrentUserId()
        ) else { return nil }

        // Only show alerts before the daily fix
        guard pattern.severity == .alert else { return nil }

        return pattern
    }

    func shouldShowPatternAfterFix() async throws -> DetectedPattern? {
        guard !sessionPatternShown else { return nil }

        guard let pattern = try await diagnosticEngine.getPatternToSurface(
            for: try await getCurrentUserId()
        ) else { return nil }

        // Show insights after fix outcome
        guard pattern.severity == .insight else { return nil }

        return pattern
    }

    func markPatternShown(_ patternId: UUID) async throws {
        sessionPatternShown = true
        try await diagnosticEngine.markPatternViewed(patternId)

        // Log analytics event
        let userId = try await getCurrentUserId()
        let calendar = Calendar.current
        let event = AnalyticsEvent(
            userId: userId,
            eventType: .patternViewed,
            dayOfWeek: calendar.component(.weekday, from: Date()),
            hourOfDay: calendar.component(.hour, from: Date())
        )
        try await analyticsEventRepository.save(event)
    }

    func dismissPattern(_ patternId: UUID) async throws {
        try await diagnosticEngine.dismissPattern(patternId)

        // Log analytics event
        let userId = try await getCurrentUserId()
        let calendar = Calendar.current
        let event = AnalyticsEvent(
            userId: userId,
            eventType: .patternDismissed,
            dayOfWeek: calendar.component(.weekday, from: Date()),
            hourOfDay: calendar.component(.hour, from: Date())
        )
        try await analyticsEventRepository.save(event)
    }

    private func getCurrentUserId() async throws -> UUID {
        guard let user = try await userRepository.get() else {
            throw ServiceError.noUser
        }
        return user.id
    }
}

enum ServiceError: Error {
    case noUser
}
