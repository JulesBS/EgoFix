import Foundation
@testable import EgoFix

@MainActor
final class MockPatternRepository: PatternRepository {
    private var patterns: [UUID: DetectedPattern] = [:]

    func getAll() async throws -> [DetectedPattern] {
        Array(patterns.values)
    }

    func getById(_ id: UUID) async throws -> DetectedPattern? {
        patterns[id]
    }

    func getForUser(_ userId: UUID) async throws -> [DetectedPattern] {
        patterns.values.filter { $0.userId == userId }
    }

    func getUnviewed(for userId: UUID) async throws -> [DetectedPattern] {
        patterns.values.filter {
            $0.userId == userId && $0.viewedAt == nil
        }
    }

    func getByType(_ type: PatternType, for userId: UUID) async throws -> [DetectedPattern] {
        patterns.values.filter {
            $0.patternType == type && $0.userId == userId
        }
    }

    func getRecentByType(_ type: PatternType, for userId: UUID, within days: Int) async throws -> [DetectedPattern] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return patterns.values.filter {
            $0.patternType == type &&
            $0.userId == userId &&
            $0.detectedAt >= cutoff
        }
    }

    func save(_ pattern: DetectedPattern) async throws {
        patterns[pattern.id] = pattern
    }

    func delete(_ id: UUID) async throws {
        patterns.removeValue(forKey: id)
    }
}
