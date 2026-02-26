import Foundation
@testable import EgoFix

@MainActor
final class MockFixRepository: FixRepository {
    private var fixes: [UUID: Fix] = [:]

    func getAll() async throws -> [Fix] {
        Array(fixes.values)
    }

    func getById(_ id: UUID) async throws -> Fix? {
        fixes[id]
    }

    func getForBug(_ bugId: UUID) async throws -> [Fix] {
        fixes.values.filter { $0.bugId == bugId }
    }

    func getDailyFix(for bugId: UUID, excluding: [UUID]) async throws -> Fix? {
        fixes.values.first {
            $0.bugId == bugId &&
            $0.type == .daily &&
            !excluding.contains($0.id)
        }
    }

    func getQuickFix(for bugId: UUID) async throws -> Fix? {
        fixes.values.first {
            $0.bugId == bugId && $0.type == .quickFix
        }
    }

    func getWeightedDailyFix(priorities: [BugPriority], excluding: [UUID]) async throws -> Fix? {
        let bugIds = Set(priorities.map { $0.bugId })
        return fixes.values.first {
            bugIds.contains($0.bugId) &&
            $0.type == .daily &&
            !excluding.contains($0.id)
        }
    }

    func save(_ fix: Fix) async throws {
        fixes[fix.id] = fix
    }

    func delete(_ id: UUID) async throws {
        fixes.removeValue(forKey: id)
    }
}
