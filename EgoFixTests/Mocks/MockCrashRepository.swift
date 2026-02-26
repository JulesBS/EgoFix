import Foundation
@testable import EgoFix

@MainActor
final class MockCrashRepository: CrashRepository {
    private var crashes: [UUID: Crash] = [:]

    func getAll() async throws -> [Crash] {
        Array(crashes.values)
    }

    func getById(_ id: UUID) async throws -> Crash? {
        crashes[id]
    }

    func getForUser(_ userId: UUID) async throws -> [Crash] {
        crashes.values.filter { $0.userId == userId }
    }

    func getUnrebooted(for userId: UUID) async throws -> [Crash] {
        crashes.values.filter {
            $0.userId == userId && $0.rebootedAt == nil
        }
    }

    func save(_ crash: Crash) async throws {
        crashes[crash.id] = crash
    }

    func delete(_ id: UUID) async throws {
        crashes.removeValue(forKey: id)
    }
}
