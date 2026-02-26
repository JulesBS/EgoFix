import Foundation
import SwiftData

final class LocalFixRepository: FixRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getAll() async throws -> [Fix] {
        let descriptor = FetchDescriptor<Fix>(
            predicate: #Predicate { $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor)
    }

    func getById(_ id: UUID) async throws -> Fix? {
        let descriptor = FetchDescriptor<Fix>(
            predicate: #Predicate { $0.id == id && $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor).first
    }

    func getForBug(_ bugId: UUID) async throws -> [Fix] {
        let descriptor = FetchDescriptor<Fix>(
            predicate: #Predicate { $0.bugId == bugId && $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor)
    }

    func getDailyFix(for bugId: UUID, excluding: [UUID]) async throws -> Fix? {
        let allFixes = try await getForBug(bugId)
        let dailyFixes = allFixes.filter { $0.type == .daily && !excluding.contains($0.id) }
        return dailyFixes.randomElement()
    }

    func getQuickFix(for bugId: UUID) async throws -> Fix? {
        let allFixes = try await getForBug(bugId)
        let quickFixes = allFixes.filter { $0.type == .quickFix }
        return quickFixes.randomElement()
    }

    func getWeightedDailyFix(priorities: [BugPriority], excluding: [UUID]) async throws -> Fix? {
        guard !priorities.isEmpty else { return nil }

        let allFixes = try await getAll()
        let dailyFixes = allFixes.filter { $0.type == .daily && !excluding.contains($0.id) }

        guard !dailyFixes.isEmpty else { return nil }

        // Create weighted pool of fixes
        var weightedFixes: [(fix: Fix, weight: Double)] = []

        for fix in dailyFixes {
            if let priority = priorities.first(where: { $0.bugId == fix.bugId }) {
                weightedFixes.append((fix, priority.weight))
            }
        }

        guard !weightedFixes.isEmpty else { return nil }

        // Weighted random selection
        let totalWeight = weightedFixes.reduce(0) { $0 + $1.weight }
        var randomValue = Double.random(in: 0..<totalWeight)

        for (fix, weight) in weightedFixes {
            randomValue -= weight
            if randomValue <= 0 {
                return fix
            }
        }

        return weightedFixes.last?.fix
    }

    func save(_ fix: Fix) async throws {
        modelContext.insert(fix)
        try modelContext.save()
    }

    func delete(_ id: UUID) async throws {
        if let fix = try await getById(id) {
            fix.deletedAt = Date()
            fix.updatedAt = Date()
            try modelContext.save()
        }
    }
}
