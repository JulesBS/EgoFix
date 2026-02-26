import Foundation
@testable import EgoFix

@MainActor
final class MockBugRepository: BugRepository {
    private var bugs: [UUID: Bug] = [:]

    func getAll() async throws -> [Bug] {
        Array(bugs.values)
    }

    func getById(_ id: UUID) async throws -> Bug? {
        bugs[id]
    }

    func getBySlug(_ slug: String) async throws -> Bug? {
        bugs.values.first { $0.slug == slug }
    }

    func getActive() async throws -> [Bug] {
        bugs.values.filter { $0.isActive }
    }

    func save(_ bug: Bug) async throws {
        bugs[bug.id] = bug
    }

    func delete(_ id: UUID) async throws {
        bugs.removeValue(forKey: id)
    }
}
