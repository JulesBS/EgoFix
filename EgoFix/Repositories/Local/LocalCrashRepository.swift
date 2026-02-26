import Foundation
import SwiftData

final class LocalCrashRepository: CrashRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getAll() async throws -> [Crash] {
        let descriptor = FetchDescriptor<Crash>(
            predicate: #Predicate { $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor)
    }

    func getById(_ id: UUID) async throws -> Crash? {
        let descriptor = FetchDescriptor<Crash>(
            predicate: #Predicate { $0.id == id && $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor).first
    }

    func getForUser(_ userId: UUID) async throws -> [Crash] {
        let descriptor = FetchDescriptor<Crash>(
            predicate: #Predicate { $0.userId == userId && $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor)
    }

    func getUnrebooted(for userId: UUID) async throws -> [Crash] {
        let crashes = try await getForUser(userId)
        return crashes.filter { $0.rebootedAt == nil }
    }

    func save(_ crash: Crash) async throws {
        modelContext.insert(crash)
        try modelContext.save()
    }

    func delete(_ id: UUID) async throws {
        if let crash = try await getById(id) {
            crash.deletedAt = Date()
            crash.updatedAt = Date()
            try modelContext.save()
        }
    }
}
