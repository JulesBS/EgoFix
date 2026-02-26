import Foundation

protocol FixCompletionRepository {
    func getAll() async throws -> [FixCompletion]
    func getById(_ id: UUID) async throws -> FixCompletion?
    func getForUser(_ userId: UUID) async throws -> [FixCompletion]
    func getForFix(_ fixId: UUID) async throws -> [FixCompletion]
    func getPending(for userId: UUID) async throws -> FixCompletion?
    func getCompletedFixIds(for userId: UUID) async throws -> [UUID]
    func save(_ completion: FixCompletion) async throws
    func delete(_ id: UUID) async throws
}
