import Foundation

protocol WeeklyDiagnosticRepository {
    func getAll() async throws -> [WeeklyDiagnostic]
    func getById(_ id: UUID) async throws -> WeeklyDiagnostic?
    func getForUser(_ userId: UUID) async throws -> [WeeklyDiagnostic]
    func getForWeek(starting: Date, userId: UUID) async throws -> WeeklyDiagnostic?
    func getRecent(for userId: UUID, limit: Int) async throws -> [WeeklyDiagnostic]
    func save(_ diagnostic: WeeklyDiagnostic) async throws
    func delete(_ id: UUID) async throws
}
