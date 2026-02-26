import Foundation

final class CrashService {
    private let crashRepository: CrashRepository
    private let fixRepository: FixRepository
    private let fixCompletionRepository: FixCompletionRepository
    private let userRepository: UserRepository
    private let analyticsEventRepository: AnalyticsEventRepository

    init(
        crashRepository: CrashRepository,
        fixRepository: FixRepository,
        fixCompletionRepository: FixCompletionRepository,
        userRepository: UserRepository,
        analyticsEventRepository: AnalyticsEventRepository
    ) {
        self.crashRepository = crashRepository
        self.fixRepository = fixRepository
        self.fixCompletionRepository = fixCompletionRepository
        self.userRepository = userRepository
        self.analyticsEventRepository = analyticsEventRepository
    }

    func logCrash(bugId: UUID?, note: String?) async throws -> Crash? {
        guard let user = try await userRepository.get() else { return nil }

        let crash = Crash(
            userId: user.id,
            bugId: bugId,
            note: note
        )
        try await crashRepository.save(crash)

        // Log analytics event
        let calendar = Calendar.current
        let event = AnalyticsEvent(
            userId: user.id,
            eventType: .crashLogged,
            bugId: bugId,
            dayOfWeek: calendar.component(.weekday, from: Date()),
            hourOfDay: calendar.component(.hour, from: Date())
        )
        try await analyticsEventRepository.save(event)

        return crash
    }

    func assignQuickFix(for crashId: UUID) async throws -> FixCompletion? {
        guard let crash = try await crashRepository.getById(crashId),
              let bugId = crash.bugId,
              let user = try await userRepository.get() else { return nil }

        // Get a quick fix for the bug
        guard let quickFix = try await fixRepository.getQuickFix(for: bugId) else {
            return nil
        }

        // Create completion record
        let completion = FixCompletion(
            fixId: quickFix.id,
            userId: user.id
        )
        try await fixCompletionRepository.save(completion)

        return completion
    }

    func reboot(crashId: UUID) async throws {
        guard let crash = try await crashRepository.getById(crashId),
              let user = try await userRepository.get() else { return }

        crash.rebootedAt = Date()
        crash.updatedAt = Date()
        try await crashRepository.save(crash)

        // Log analytics event
        let calendar = Calendar.current
        let event = AnalyticsEvent(
            userId: user.id,
            eventType: .crashRebooted,
            bugId: crash.bugId,
            dayOfWeek: calendar.component(.weekday, from: Date()),
            hourOfDay: calendar.component(.hour, from: Date())
        )
        try await analyticsEventRepository.save(event)
    }

    func getUnrebootedCrashes() async throws -> [Crash] {
        guard let user = try await userRepository.get() else { return [] }
        return try await crashRepository.getUnrebooted(for: user.id)
    }
}
