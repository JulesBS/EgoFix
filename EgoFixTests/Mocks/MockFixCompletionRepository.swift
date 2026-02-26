import Foundation
@testable import EgoFix

@MainActor
final class MockFixCompletionRepository: FixCompletionRepository {
    private var completions: [UUID: FixCompletion] = [:]

    func getAll() async throws -> [FixCompletion] {
        Array(completions.values)
    }

    func getById(_ id: UUID) async throws -> FixCompletion? {
        completions[id]
    }

    func getForUser(_ userId: UUID) async throws -> [FixCompletion] {
        completions.values.filter { $0.userId == userId }
    }

    func getForFix(_ fixId: UUID) async throws -> [FixCompletion] {
        completions.values.filter { $0.fixId == fixId }
    }

    func getPending(for userId: UUID) async throws -> FixCompletion? {
        completions.values.first {
            $0.userId == userId && $0.outcome == .pending
        }
    }

    func getCompletedFixIds(for userId: UUID) async throws -> [UUID] {
        completions.values
            .filter { $0.userId == userId && $0.outcome != .pending }
            .map { $0.fixId }
    }

    func save(_ completion: FixCompletion) async throws {
        completions[completion.id] = completion
    }

    func delete(_ id: UUID) async throws {
        completions.removeValue(forKey: id)
    }
}
