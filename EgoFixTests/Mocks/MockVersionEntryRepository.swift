import Foundation
@testable import EgoFix

@MainActor
final class MockVersionEntryRepository: VersionEntryRepository {
    private var entries: [UUID: VersionEntry] = [:]

    func getAll() async throws -> [VersionEntry] {
        Array(entries.values)
    }

    func getById(_ id: UUID) async throws -> VersionEntry? {
        entries[id]
    }

    func getForUser(_ userId: UUID) async throws -> [VersionEntry] {
        entries.values.filter { $0.userId == userId }
    }

    func getLatest(for userId: UUID) async throws -> VersionEntry? {
        entries.values
            .filter { $0.userId == userId }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }

    func save(_ entry: VersionEntry) async throws {
        entries[entry.id] = entry
    }

    func delete(_ id: UUID) async throws {
        entries.removeValue(forKey: id)
    }
}
