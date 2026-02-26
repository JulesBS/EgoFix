import Foundation
@testable import EgoFix

@MainActor
final class MockAnalyticsEventRepository: AnalyticsEventRepository {
    private var events: [UUID: AnalyticsEvent] = [:]

    func getAll() async throws -> [AnalyticsEvent] {
        Array(events.values)
    }

    func getById(_ id: UUID) async throws -> AnalyticsEvent? {
        events[id]
    }

    func getForUser(_ userId: UUID) async throws -> [AnalyticsEvent] {
        events.values.filter { $0.userId == userId }
    }

    func getForBug(_ bugId: UUID) async throws -> [AnalyticsEvent] {
        events.values.filter { $0.bugId == bugId }
    }

    func getByType(_ type: EventType, for userId: UUID) async throws -> [AnalyticsEvent] {
        events.values.filter {
            $0.eventType == type && $0.userId == userId
        }
    }

    func getInDateRange(from: Date, to: Date, for userId: UUID) async throws -> [AnalyticsEvent] {
        events.values.filter {
            $0.userId == userId &&
            $0.timestamp >= from &&
            $0.timestamp <= to
        }
    }

    func save(_ event: AnalyticsEvent) async throws {
        events[event.id] = event
    }

    func delete(_ id: UUID) async throws {
        events.removeValue(forKey: id)
    }
}
