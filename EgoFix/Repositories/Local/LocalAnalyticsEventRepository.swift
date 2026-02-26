import Foundation
import SwiftData

final class LocalAnalyticsEventRepository: AnalyticsEventRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getAll() async throws -> [AnalyticsEvent] {
        let descriptor = FetchDescriptor<AnalyticsEvent>(
            predicate: #Predicate { $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor)
    }

    func getById(_ id: UUID) async throws -> AnalyticsEvent? {
        let descriptor = FetchDescriptor<AnalyticsEvent>(
            predicate: #Predicate { $0.id == id && $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor).first
    }

    func getForUser(_ userId: UUID) async throws -> [AnalyticsEvent] {
        let descriptor = FetchDescriptor<AnalyticsEvent>(
            predicate: #Predicate { $0.userId == userId && $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor)
    }

    func getForBug(_ bugId: UUID) async throws -> [AnalyticsEvent] {
        let descriptor = FetchDescriptor<AnalyticsEvent>(
            predicate: #Predicate { $0.bugId == bugId && $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor)
    }

    func getByType(_ type: EventType, for userId: UUID) async throws -> [AnalyticsEvent] {
        let events = try await getForUser(userId)
        return events.filter { $0.eventType == type }
    }

    func getInDateRange(from: Date, to: Date, for userId: UUID) async throws -> [AnalyticsEvent] {
        let descriptor = FetchDescriptor<AnalyticsEvent>(
            predicate: #Predicate {
                $0.userId == userId &&
                $0.deletedAt == nil &&
                $0.timestamp >= from &&
                $0.timestamp <= to
            }
        )
        return try modelContext.fetch(descriptor)
    }

    func save(_ event: AnalyticsEvent) async throws {
        modelContext.insert(event)
        try modelContext.save()
    }

    func delete(_ id: UUID) async throws {
        if let event = try await getById(id) {
            event.deletedAt = Date()
            try modelContext.save()
        }
    }
}
