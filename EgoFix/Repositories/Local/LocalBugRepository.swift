import Foundation
import SwiftData

final class LocalBugRepository: BugRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getAll() async throws -> [Bug] {
        let descriptor = FetchDescriptor<Bug>(
            predicate: #Predicate { $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor)
    }

    func getById(_ id: UUID) async throws -> Bug? {
        let descriptor = FetchDescriptor<Bug>(
            predicate: #Predicate { $0.id == id && $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor).first
    }

    func getBySlug(_ slug: String) async throws -> Bug? {
        let descriptor = FetchDescriptor<Bug>(
            predicate: #Predicate { $0.slug == slug && $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor).first
    }

    func getActive() async throws -> [Bug] {
        let descriptor = FetchDescriptor<Bug>(
            predicate: #Predicate { $0.isActive && $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor)
    }

    func save(_ bug: Bug) async throws {
        modelContext.insert(bug)
        try modelContext.save()
    }

    func delete(_ id: UUID) async throws {
        if let bug = try await getById(id) {
            bug.deletedAt = Date()
            bug.updatedAt = Date()
            try modelContext.save()
        }
    }
}
