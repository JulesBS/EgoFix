import Foundation

final class VersionService {
    private let userRepository: UserRepository
    private let versionEntryRepository: VersionEntryRepository
    private let fixCompletionRepository: FixCompletionRepository

    private let fixesForMinorUpdate = 7
    private let minorUpdatesForMajor = 10

    init(
        userRepository: UserRepository,
        versionEntryRepository: VersionEntryRepository,
        fixCompletionRepository: FixCompletionRepository
    ) {
        self.userRepository = userRepository
        self.versionEntryRepository = versionEntryRepository
        self.fixCompletionRepository = fixCompletionRepository
    }

    func getCurrentVersion() async throws -> String {
        guard let user = try await userRepository.get() else {
            return "1.0"
        }
        return user.currentVersion
    }

    func checkAndIncrementVersion() async throws -> VersionEntry? {
        guard let user = try await userRepository.get() else { return nil }

        let completions = try await fixCompletionRepository.getForUser(user.id)
        let appliedCount = completions.filter { $0.outcome == .applied }.count

        // Calculate expected version based on applied fixes
        let expectedMinorUpdates = appliedCount / fixesForMinorUpdate
        let expectedMajor = (expectedMinorUpdates / minorUpdatesForMajor) + 1
        let expectedMinor = expectedMinorUpdates % minorUpdatesForMajor

        let expectedVersion = "\(expectedMajor).\(expectedMinor)"

        // If version needs updating
        if expectedVersion != user.currentVersion {
            let changeType: VersionChangeType = expectedMinor == 0 && expectedMajor > 1 ? .majorUpdate : .minorUpdate

            let entry = VersionEntry(
                userId: user.id,
                version: expectedVersion,
                changeType: changeType,
                description: changeType == .majorUpdate
                    ? "Major update: Significant progress made"
                    : "Minor update: \(fixesForMinorUpdate) fixes applied"
            )
            try await versionEntryRepository.save(entry)

            user.currentVersion = expectedVersion
            user.updatedAt = Date()
            try await userRepository.save(user)

            return entry
        }

        return nil
    }

    func incrementVersion(major: Int, minor: Int) -> String {
        var newMinor = minor + 1
        var newMajor = major

        if newMinor >= minorUpdatesForMajor {
            newMinor = 0
            newMajor += 1
        }

        return "\(newMajor).\(newMinor)"
    }

    func parseVersion(_ version: String) -> (major: Int, minor: Int) {
        let components = version.split(separator: ".").compactMap { Int($0) }
        guard components.count >= 2 else {
            return (1, 0)
        }
        return (components[0], components[1])
    }
}
