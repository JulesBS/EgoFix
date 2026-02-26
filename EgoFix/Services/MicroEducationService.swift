import Foundation

final class MicroEducationService {
    private let repository: MicroEducationRepository
    private var lastShownId: UUID?

    init(repository: MicroEducationRepository) {
        self.repository = repository
    }

    /// Get a random micro-education tidbit for a bug and trigger.
    /// Avoids showing the same tidbit consecutively.
    func getRandomTidbit(bugSlug: String, trigger: EducationTrigger) async throws -> MicroEducation? {
        let tidbits = try await repository.getByBugSlugAndTrigger(bugSlug, trigger: trigger)

        guard !tidbits.isEmpty else {
            // Fall back to general trigger for this bug
            let general = try await repository.getByBugSlugAndTrigger(bugSlug, trigger: .general)
            return pickRandom(from: general)
        }

        return pickRandom(from: tidbits)
    }

    private func pickRandom(from tidbits: [MicroEducation]) -> MicroEducation? {
        guard !tidbits.isEmpty else { return nil }

        // Filter out the last shown tidbit to avoid consecutive repeats
        let candidates = tidbits.filter { $0.id != lastShownId }

        // If all were filtered out (only 1 tidbit), use the original list
        let pool = candidates.isEmpty ? tidbits : candidates

        let selected = pool.randomElement()
        lastShownId = selected?.id
        return selected
    }
}
