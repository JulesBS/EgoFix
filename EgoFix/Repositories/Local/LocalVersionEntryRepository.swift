import Foundation
import SwiftData

final class LocalVersionEntryRepository: VersionEntryRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getAll() async throws -> [VersionEntry] {
        let descriptor = FetchDescriptor<VersionEntry>(
            predicate: #Predicate { $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor)
    }

    func getById(_ id: UUID) async throws -> VersionEntry? {
        let descriptor = FetchDescriptor<VersionEntry>(
            predicate: #Predicate { $0.id == id && $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor).first
    }

    func getForUser(_ userId: UUID) async throws -> [VersionEntry] {
        let descriptor = FetchDescriptor<VersionEntry>(
            predicate: #Predicate { $0.userId == userId && $0.deletedAt == nil },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func getLatest(for userId: UUID) async throws -> VersionEntry? {
        let entries = try await getForUser(userId)
        return entries.first
    }

    func save(_ entry: VersionEntry) async throws {
        modelContext.insert(entry)
        try modelContext.save()
    }

    func delete(_ id: UUID) async throws {
        if let entry = try await getById(id) {
            entry.deletedAt = Date()
            try modelContext.save()
        }
    }
}
