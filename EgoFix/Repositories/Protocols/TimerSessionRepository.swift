import Foundation

protocol TimerSessionRepository {
    func getAll() async throws -> [TimerSession]
    func getById(_ id: UUID) async throws -> TimerSession?
    func getForFixCompletion(_ fixCompletionId: UUID) async throws -> TimerSession?
    func getActive() async throws -> TimerSession?  // Running or paused session
    func save(_ session: TimerSession) async throws
    func delete(_ id: UUID) async throws
}
