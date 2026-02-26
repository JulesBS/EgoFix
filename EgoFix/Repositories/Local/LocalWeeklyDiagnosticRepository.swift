import Foundation
import SwiftData

final class LocalWeeklyDiagnosticRepository: WeeklyDiagnosticRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getAll() async throws -> [WeeklyDiagnostic] {
        let descriptor = FetchDescriptor<WeeklyDiagnostic>(
            predicate: #Predicate { $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor)
    }

    func getById(_ id: UUID) async throws -> WeeklyDiagnostic? {
        let descriptor = FetchDescriptor<WeeklyDiagnostic>(
            predicate: #Predicate { $0.id == id && $0.deletedAt == nil }
        )
        return try modelContext.fetch(descriptor).first
    }

    func getForUser(_ userId: UUID) async throws -> [WeeklyDiagnostic] {
        let descriptor = FetchDescriptor<WeeklyDiagnostic>(
            predicate: #Predicate { $0.userId == userId && $0.deletedAt == nil },
            sortBy: [SortDescriptor(\.weekStarting, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func getForWeek(starting: Date, userId: UUID) async throws -> WeeklyDiagnostic? {
        let calendar = Calendar.current
        let startOfWeek = calendar.startOfDay(for: starting)
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? startOfWeek

        let descriptor = FetchDescriptor<WeeklyDiagnostic>(
            predicate: #Predicate {
                $0.userId == userId &&
                $0.deletedAt == nil &&
                $0.weekStarting >= startOfWeek &&
                $0.weekStarting < endOfWeek
            }
        )
        return try modelContext.fetch(descriptor).first
    }

    func getRecent(for userId: UUID, limit: Int) async throws -> [WeeklyDiagnostic] {
        var descriptor = FetchDescriptor<WeeklyDiagnostic>(
            predicate: #Predicate { $0.userId == userId && $0.deletedAt == nil },
            sortBy: [SortDescriptor(\.weekStarting, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    func save(_ diagnostic: WeeklyDiagnostic) async throws {
        modelContext.insert(diagnostic)
        try modelContext.save()
    }

    func delete(_ id: UUID) async throws {
        if let diagnostic = try await getById(id) {
            diagnostic.deletedAt = Date()
            try modelContext.save()
        }
    }
}
