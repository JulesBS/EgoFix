import Foundation

protocol AnalyticsEventRepository {
    func getAll() async throws -> [AnalyticsEvent]
    func getById(_ id: UUID) async throws -> AnalyticsEvent?
    func getForUser(_ userId: UUID) async throws -> [AnalyticsEvent]
    func getForBug(_ bugId: UUID) async throws -> [AnalyticsEvent]
    func getByType(_ type: EventType, for userId: UUID) async throws -> [AnalyticsEvent]
    func getInDateRange(from: Date, to: Date, for userId: UUID) async throws -> [AnalyticsEvent]
    func save(_ event: AnalyticsEvent) async throws
    func delete(_ id: UUID) async throws
}
