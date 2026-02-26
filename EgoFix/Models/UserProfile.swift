import Foundation
import SwiftData

/// Represents a bug's priority ranking for weighted fix delivery
struct BugPriority: Codable, Equatable {
    let bugId: UUID
    let rank: Int  // 1 = highest priority, higher numbers = lower priority

    /// Weight for fix selection (higher rank = higher weight)
    var weight: Double {
        // Inverse exponential: rank 1 gets ~4x weight of rank 10
        return 1.0 / pow(Double(rank), 0.5)
    }
}

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var currentVersion: String

    /// Ranked list of bug priorities (stored as JSON)
    var bugPrioritiesData: Data?

    /// Legacy field - kept for migration
    var primaryBugId: UUID?

    var createdAt: Date
    var updatedAt: Date

    // Streak tracking
    var currentStreak: Int
    var longestStreak: Int
    var lastEngagementDate: Date?
    var streakFreezeAvailable: Bool
    var lastFreezeResetDate: Date?

    // Diagnostic tracking
    var lastDiagnosticsRunAt: Date?

    // Pattern surfacing
    var lastPatternShownAt: Date?

    // Sync-ready
    var syncToken: String?
    var lastSyncedAt: Date?

    /// Computed property to access bug priorities
    var bugPriorities: [BugPriority] {
        get {
            guard let data = bugPrioritiesData else { return [] }
            return (try? JSONDecoder().decode([BugPriority].self, from: data)) ?? []
        }
        set {
            bugPrioritiesData = try? JSONEncoder().encode(newValue)
            updatedAt = Date()
        }
    }

    init(
        id: UUID = UUID(),
        currentVersion: String = "1.0",
        bugPriorities: [BugPriority] = [],
        primaryBugId: UUID? = nil,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastEngagementDate: Date? = nil,
        streakFreezeAvailable: Bool = true,
        lastFreezeResetDate: Date? = nil,
        lastDiagnosticsRunAt: Date? = nil,
        lastPatternShownAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncToken: String? = nil,
        lastSyncedAt: Date? = nil
    ) {
        self.id = id
        self.currentVersion = currentVersion
        self.primaryBugId = primaryBugId
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastEngagementDate = lastEngagementDate
        self.streakFreezeAvailable = streakFreezeAvailable
        self.lastFreezeResetDate = lastFreezeResetDate
        self.lastDiagnosticsRunAt = lastDiagnosticsRunAt
        self.lastPatternShownAt = lastPatternShownAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncToken = syncToken
        self.lastSyncedAt = lastSyncedAt
        self.bugPrioritiesData = try? JSONEncoder().encode(bugPriorities)
    }
}
