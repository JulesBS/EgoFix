import Foundation
@testable import EgoFix

@MainActor
final class MockUserRepository: UserRepository {
    private var users: [UUID: UserProfile] = [:]

    func get() async throws -> UserProfile? {
        users.values.first
    }

    func getById(_ id: UUID) async throws -> UserProfile? {
        users[id]
    }

    func save(_ user: UserProfile) async throws {
        users[user.id] = user
    }

    func delete(_ id: UUID) async throws {
        users.removeValue(forKey: id)
    }
}
