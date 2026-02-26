import Foundation

protocol FixRepository {
    func getAll() async throws -> [Fix]
    func getById(_ id: UUID) async throws -> Fix?
    func getForBug(_ bugId: UUID) async throws -> [Fix]
    func getDailyFix(for bugId: UUID, excluding: [UUID]) async throws -> Fix?
    func getQuickFix(for bugId: UUID) async throws -> Fix?

    /// Get a daily fix weighted by bug priorities
    /// - Parameters:
    ///   - priorities: User's bug priority rankings
    ///   - excluding: Fix IDs to exclude (already completed)
    /// - Returns: A weighted random fix from available fixes
    func getWeightedDailyFix(priorities: [BugPriority], excluding: [UUID]) async throws -> Fix?

    func save(_ fix: Fix) async throws
    func delete(_ id: UUID) async throws
}
