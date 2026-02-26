import Foundation

protocol BugRepository {
    func getAll() async throws -> [Bug]
    func getById(_ id: UUID) async throws -> Bug?
    func getBySlug(_ slug: String) async throws -> Bug?
    func getActive() async throws -> [Bug]
    func save(_ bug: Bug) async throws
    func delete(_ id: UUID) async throws
}
