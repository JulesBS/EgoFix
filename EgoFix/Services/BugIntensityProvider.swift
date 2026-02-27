import Foundation

/// Determines the current visual intensity for a bug based on diagnostic + crash data.
/// Used by soul views to decide animation speed and visual weight.
class BugIntensityProvider {
    private let weeklyDiagnosticRepository: WeeklyDiagnosticRepository
    private let crashRepository: CrashRepository

    init(
        weeklyDiagnosticRepository: WeeklyDiagnosticRepository,
        crashRepository: CrashRepository
    ) {
        self.weeklyDiagnosticRepository = weeklyDiagnosticRepository
        self.crashRepository = crashRepository
    }

    /// Returns current intensity for a bug, based on most recent diagnostic + crash frequency.
    ///
    /// Rules:
    /// - If diagnostic said "loud" OR 3+ crashes this week -> .loud
    /// - If diagnostic said "present" OR 1-2 crashes this week -> .present
    /// - If diagnostic said "quiet" AND 0 crashes this week -> .quiet
    /// - Default (no data): .present (we don't assume calm)
    func currentIntensity(for bugId: UUID, userId: UUID) async throws -> BugIntensity {
        let diagnosticIntensity = try await latestDiagnosticIntensity(for: bugId, userId: userId)
        let crashCount = try await recentCrashCount(for: bugId, userId: userId)

        // Loud: diagnostic says loud, or heavy crash week
        if diagnosticIntensity == .loud || crashCount >= 3 {
            return .loud
        }

        // Present: diagnostic says present, or some crashes
        if diagnosticIntensity == .present || crashCount >= 1 {
            return .present
        }

        // Quiet: diagnostic explicitly said quiet AND zero crashes
        if diagnosticIntensity == .quiet {
            return .quiet
        }

        // No data at all — default to present
        return .present
    }

    // MARK: - Private helpers

    /// Finds the most recent weekly diagnostic that includes a response for this bug.
    private func latestDiagnosticIntensity(for bugId: UUID, userId: UUID) async throws -> BugIntensity? {
        let recents = try await weeklyDiagnosticRepository.getRecent(for: userId, limit: 4)
        for diagnostic in recents {
            if let response = diagnostic.responses.first(where: { $0.bugId == bugId }) {
                return response.intensity
            }
        }
        return nil
    }

    /// Counts crashes for this bug in the last 7 days.
    private func recentCrashCount(for bugId: UUID, userId: UUID) async throws -> Int {
        let allCrashes = try await crashRepository.getForUser(userId)
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return allCrashes.filter { crash in
            crash.bugId == bugId && crash.crashedAt >= sevenDaysAgo
        }.count
    }
}
