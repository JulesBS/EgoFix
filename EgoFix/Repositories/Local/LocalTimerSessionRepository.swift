import Foundation
import SwiftData

final class LocalTimerSessionRepository: TimerSessionRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getAll() async throws -> [TimerSession] {
        let descriptor = FetchDescriptor<TimerSession>()
        return try modelContext.fetch(descriptor)
    }

    func getById(_ id: UUID) async throws -> TimerSession? {
        let descriptor = FetchDescriptor<TimerSession>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func getForFixCompletion(_ fixCompletionId: UUID) async throws -> TimerSession? {
        let descriptor = FetchDescriptor<TimerSession>(
            predicate: #Predicate { $0.fixCompletionId == fixCompletionId }
        )
        return try modelContext.fetch(descriptor).first
    }

    func getActive() async throws -> TimerSession? {
        // Get all sessions and filter for running or paused
        let allSessions = try await getAll()
        return allSessions.first { $0.status == .running || $0.status == .paused }
    }

    func save(_ session: TimerSession) async throws {
        modelContext.insert(session)
        try modelContext.save()
    }

    func delete(_ id: UUID) async throws {
        if let session = try await getById(id) {
            modelContext.delete(session)
            try modelContext.save()
        }
    }
}
