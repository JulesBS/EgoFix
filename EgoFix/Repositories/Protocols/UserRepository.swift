import Foundation

protocol UserRepository {
    func get() async throws -> UserProfile?
    func getById(_ id: UUID) async throws -> UserProfile?
    func save(_ user: UserProfile) async throws
    func delete(_ id: UUID) async throws
}
