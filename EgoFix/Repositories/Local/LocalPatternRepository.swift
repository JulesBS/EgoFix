import Foundation
import SwiftData

final class LocalPatternRepository: PatternRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getAll() async throws -> [DetectedPattern] {
        let descriptor = FetchDescriptor<DetectedPattern>(
            predicate: #Predicate { $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor)
    }

    func getById(_ id: UUID) async throws -> DetectedPattern? {
        let descriptor = FetchDescriptor<DetectedPattern>(
            predicate: #Predicate { $0.id == id && $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor).first
    }

    func getForUser(_ userId: UUID) async throws -> [DetectedPattern] {
        let descriptor = FetchDescriptor<DetectedPattern>(
            predicate: #Predicate { $0.userId == userId && $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor)
    }

    func getUnviewed(for userId: UUID) async throws -> [DetectedPattern] {
        let patterns = try await getForUser(userId)
        return patterns.filter { $0.viewedAt == nil }
    }

    func getByType(_ type: PatternType, for userId: UUID) async throws -> [DetectedPattern] {
        let patterns = try await getForUser(userId)
        return patterns.filter { $0.patternType == type }
    }

    func getRecentByType(_ type: PatternType, for userId: UUID, within days: Int) async throws -> [DetectedPattern] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let patterns = try await getByType(type, for: userId)
        return patterns.filter { $0.detectedAt >= cutoffDate }
    }

    func save(_ pattern: DetectedPattern) async throws {
        modelContext.insert(pattern)
        try modelContext.save()
    }

    func delete(_ id: UUID) async throws {
        if let pattern = try await getById(id) {
            pattern.deletedAt = Date()
            try modelContext.save()
        }
    }
}
