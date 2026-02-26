import Foundation

protocol CrashRepository {
    func getAll() async throws -> [Crash]
    func getById(_ id: UUID) async throws -> Crash?
    func getForUser(_ userId: UUID) async throws -> [Crash]
    func getUnrebooted(for userId: UUID) async throws -> [Crash]
    func save(_ crash: Crash) async throws
    func delete(_ id: UUID) async throws
}
