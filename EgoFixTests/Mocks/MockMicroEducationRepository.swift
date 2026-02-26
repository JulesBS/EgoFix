import Foundation
@testable import EgoFix

@MainActor
final class MockMicroEducationRepository: MicroEducationRepository {
    private var items: [UUID: MicroEducation] = [:]

    func getAll() async throws -> [MicroEducation] {
        Array(items.values).filter { $0.deletedAt == nil }
    }

    func getById(_ id: UUID) async throws -> MicroEducation? {
        items[id]
    }

    func getByBugSlug(_ bugSlug: String) async throws -> [MicroEducation] {
        items.values.filter { $0.bugSlug == bugSlug && $0.deletedAt == nil }
    }

    func getByBugSlugAndTrigger(_ bugSlug: String, trigger: EducationTrigger) async throws -> [MicroEducation] {
        items.values.filter { $0.bugSlug == bugSlug && $0.trigger == trigger && $0.deletedAt == nil }
    }

    func save(_ education: MicroEducation) async throws {
        items[education.id] = education
    }

    func delete(_ id: UUID) async throws {
        items[id]?.deletedAt = Date()
    }
}
