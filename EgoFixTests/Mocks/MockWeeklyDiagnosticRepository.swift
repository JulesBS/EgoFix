import Foundation
@testable import EgoFix

@MainActor
final class MockWeeklyDiagnosticRepository: WeeklyDiagnosticRepository {
    private var diagnostics: [UUID: WeeklyDiagnostic] = [:]

    func getAll() async throws -> [WeeklyDiagnostic] {
        Array(diagnostics.values)
    }

    func getById(_ id: UUID) async throws -> WeeklyDiagnostic? {
        diagnostics[id]
    }

    func getForUser(_ userId: UUID) async throws -> [WeeklyDiagnostic] {
        diagnostics.values.filter { $0.userId == userId }
    }

    func getForWeek(starting: Date, userId: UUID) async throws -> WeeklyDiagnostic? {
        let calendar = Calendar.current
        return diagnostics.values.first {
            $0.userId == userId &&
            calendar.isDate($0.weekStarting, inSameDayAs: starting)
        }
    }

    func getRecent(for userId: UUID, limit: Int) async throws -> [WeeklyDiagnostic] {
        Array(
            diagnostics.values
                .filter { $0.userId == userId }
                .sorted { $0.completedAt > $1.completedAt }
                .prefix(limit)
        )
    }

    func save(_ diagnostic: WeeklyDiagnostic) async throws {
        diagnostics[diagnostic.id] = diagnostic
    }

    func delete(_ id: UUID) async throws {
        diagnostics.removeValue(forKey: id)
    }
}
