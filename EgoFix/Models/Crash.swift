import Foundation
import SwiftData

@Model
final class Crash {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var bugId: UUID?
    var note: String?
    var crashedAt: Date
    var rebootedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        userId: UUID,
        bugId: UUID? = nil,
        note: String? = nil,
        crashedAt: Date = Date(),
        rebootedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.bugId = bugId
        self.note = note
        self.crashedAt = crashedAt
        self.rebootedAt = rebootedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}
