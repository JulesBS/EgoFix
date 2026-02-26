import Foundation
import SwiftData

final class LocalUserRepository: UserRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func get() async throws -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>()
        return try modelContext.fetch(descriptor).first
    }

    func getById(_ id: UUID) async throws -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func save(_ user: UserProfile) async throws {
        modelContext.insert(user)
        try modelContext.save()
    }

    func delete(_ id: UUID) async throws {
        if let user = try await getById(id) {
            modelContext.delete(user)
            try modelContext.save()
        }
    }
}
