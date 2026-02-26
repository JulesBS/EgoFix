import Foundation
import SwiftData

final class LocalFixCompletionRepository: FixCompletionRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getAll() async throws -> [FixCompletion] {
        let descriptor = FetchDescriptor<FixCompletion>(
            predicate: #Predicate { $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor)
    }

    func getById(_ id: UUID) async throws -> FixCompletion? {
        let descriptor = FetchDescriptor<FixCompletion>(
            predicate: #Predicate { $0.id == id && $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor).first
    }

    func getForUser(_ userId: UUID) async throws -> [FixCompletion] {
        let descriptor = FetchDescriptor<FixCompletion>(
            predicate: #Predicate { $0.userId == userId && $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor)
    }

    func getForFix(_ fixId: UUID) async throws -> [FixCompletion] {
        let descriptor = FetchDescriptor<FixCompletion>(
            predicate: #Predicate { $0.fixId == fixId && $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor)
    }

    func getPending(for userId: UUID) async throws -> FixCompletion? {
        let completions = try await getForUser(userId)
        return completions.first { $0.outcome == .pending }
    }

    func getCompletedFixIds(for userId: UUID) async throws -> [UUID] {
        let completions = try await getForUser(userId)
        return completions
            .filter { $0.outcome == .applied || $0.outcome == .skipped || $0.outcome == .failed }
            .map { $0.fixId }
    }

    func save(_ completion: FixCompletion) async throws {
        modelContext.insert(completion)
        try modelContext.save()
    }

    func delete(_ id: UUID) async throws {
        if let completion = try await getById(id) {
            completion.deletedAt = Date()
            completion.updatedAt = Date()
            try modelContext.save()
        }
    }
}
