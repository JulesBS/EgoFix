import Foundation
import SwiftData

final class LocalMicroEducationRepository: MicroEducationRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getAll() async throws -> [MicroEducation] {
        let descriptor = FetchDescriptor<MicroEducation>(
            predicate: #Predicate { $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor)
    }

    func getById(_ id: UUID) async throws -> MicroEducation? {
        let descriptor = FetchDescriptor<MicroEducation>(
            predicate: #Predicate { $0.id == id && $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor).first
    }

    func getByBugSlug(_ bugSlug: String) async throws -> [MicroEducation] {
        let descriptor = FetchDescriptor<MicroEducation>(
            predicate: #Predicate { $0.bugSlug == bugSlug && $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor)
    }

    func getByBugSlugAndTrigger(_ bugSlug: String, trigger: EducationTrigger) async throws -> [MicroEducation] {
        let triggerRaw = trigger.rawValue
        let descriptor = FetchDescriptor<MicroEducation>(
            predicate: #Predicate { $0.bugSlug == bugSlug && $0.trigger.rawValue == triggerRaw && $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor)
    }

    func save(_ education: MicroEducation) async throws {
        modelContext.insert(education)
        try modelContext.save()
    }

    func delete(_ id: UUID) async throws {
        if let education = try await getById(id) {
            education.deletedAt = Date()
            try modelContext.save()
        }
    }
}
