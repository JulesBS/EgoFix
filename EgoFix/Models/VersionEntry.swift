import Foundation
import SwiftData

enum VersionChangeType: String, Codable {
    case majorUpdate
    case minorUpdate
    case crash
    case reboot
}

@Model
final class VersionEntry {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var version: String
    var changeType: VersionChangeType
    var entryDescription: String
    var createdAt: Date
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        userId: UUID,
        version: String,
        changeType: VersionChangeType,
        description: String,
        createdAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.version = version
        self.changeType = changeType
        self.entryDescription = description
        self.createdAt = createdAt
        self.deletedAt = deletedAt
    }
}
