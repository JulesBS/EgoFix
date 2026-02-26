import Foundation

protocol VersionEntryRepository {
    func getAll() async throws -> [VersionEntry]
    func getById(_ id: UUID) async throws -> VersionEntry?
    func getForUser(_ userId: UUID) async throws -> [VersionEntry]
    func getLatest(for userId: UUID) async throws -> VersionEntry?
    func save(_ entry: VersionEntry) async throws
    func delete(_ id: UUID) async throws
}
