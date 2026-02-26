import Foundation

protocol MicroEducationRepository {
    func getAll() async throws -> [MicroEducation]
    func getById(_ id: UUID) async throws -> MicroEducation?
    func getByBugSlug(_ bugSlug: String) async throws -> [MicroEducation]
    func getByBugSlugAndTrigger(_ bugSlug: String, trigger: EducationTrigger) async throws -> [MicroEducation]
    func save(_ education: MicroEducation) async throws
    func delete(_ id: UUID) async throws
}
