import Foundation

final class TimerService {
    private let timerSessionRepository: TimerSessionRepository

    init(timerSessionRepository: TimerSessionRepository) {
        self.timerSessionRepository = timerSessionRepository
    }

    // MARK: - Time Parsing

    /// Parse a fix prompt to extract timer duration in seconds
    /// Returns nil if no time reference is found
    func parseTimerDuration(from prompt: String) -> Int? {
        let lowercased = prompt.lowercased()

        // Patterns to match various time formats
        let patterns: [(regex: String, multiplier: Int)] = [
            // Minutes: "5 min", "5-min", "5 minute", "5 minutes", "5-minute"
            (#"(\d+)[- ]?min(?:ute)?s?"#, 60),
            // Seconds: "30 sec", "30 second", "30 seconds", "30-second"
            (#"(\d+)[- ]?sec(?:ond)?s?"#, 1),
            // Hours: "1 hour", "2 hours", "1-hour"
            (#"(\d+)[- ]?hours?"#, 3600),
        ]

        for (pattern, multiplier) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: lowercased, range: NSRange(lowercased.startIndex..., in: lowercased)),
               let numberRange = Range(match.range(at: 1), in: lowercased),
               let number = Int(lowercased[numberRange]) {
                return number * multiplier
            }
        }

        return nil
    }

    /// Check if a fix requires a timer based on its prompt
    func fixRequiresTimer(_ fix: Fix) -> Bool {
        return parseTimerDuration(from: fix.prompt) != nil
    }

    // MARK: - Timer Operations

    /// Get or create a timer session for a fix completion
    func getOrCreateSession(for fixCompletionId: UUID, durationSeconds: Int) async throws -> TimerSession {
        // Check for existing session
        if let existing = try await timerSessionRepository.getForFixCompletion(fixCompletionId) {
            return existing
        }

        // Create new session
        let session = TimerSession(
            fixCompletionId: fixCompletionId,
            durationSeconds: durationSeconds
        )
        try await timerSessionRepository.save(session)
        return session
    }

    /// Start or resume a timer session
    func startTimer(_ session: TimerSession) async throws {
        guard session.status == .idle || session.status == .paused else { return }

        if session.status == .paused, let pausedAt = session.pausedAt, let startedAt = session.startedAt {
            // Resuming: accumulate elapsed time before pause
            let elapsedBeforePause = Int(pausedAt.timeIntervalSince(startedAt))
            session.accumulatedSeconds += elapsedBeforePause
        }

        session.startedAt = Date()
        session.pausedAt = nil
        session.status = .running
        session.updatedAt = Date()
        try await timerSessionRepository.save(session)
    }

    /// Pause a running timer
    func pauseTimer(_ session: TimerSession) async throws {
        guard session.status == .running else { return }

        session.pausedAt = Date()
        session.status = .paused
        session.updatedAt = Date()
        try await timerSessionRepository.save(session)
    }

    /// Complete a timer (called when timer reaches zero)
    func completeTimer(_ session: TimerSession) async throws {
        session.completedAt = Date()
        session.status = .completed
        session.updatedAt = Date()
        try await timerSessionRepository.save(session)
    }

    /// Reset a timer to initial state
    func resetTimer(_ session: TimerSession) async throws {
        session.startedAt = nil
        session.pausedAt = nil
        session.completedAt = nil
        session.accumulatedSeconds = 0
        session.status = .idle
        session.updatedAt = Date()
        try await timerSessionRepository.save(session)
    }

    /// Get any active timer session (running or paused)
    func getActiveSession() async throws -> TimerSession? {
        return try await timerSessionRepository.getActive()
    }

    /// Get timer session for a specific fix completion
    func getSession(for fixCompletionId: UUID) async throws -> TimerSession? {
        return try await timerSessionRepository.getForFixCompletion(fixCompletionId)
    }
}
