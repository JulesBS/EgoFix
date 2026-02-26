import Foundation

protocol PatternRepository {
    func getAll() async throws -> [DetectedPattern]
    func getById(_ id: UUID) async throws -> DetectedPattern?
    func getForUser(_ userId: UUID) async throws -> [DetectedPattern]
    func getUnviewed(for userId: UUID) async throws -> [DetectedPattern]
    func getByType(_ type: PatternType, for userId: UUID) async throws -> [DetectedPattern]
    func getRecentByType(_ type: PatternType, for userId: UUID, within days: Int) async throws -> [DetectedPattern]
    func save(_ pattern: DetectedPattern) async throws
    func delete(_ id: UUID) async throws
}
