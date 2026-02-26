import Foundation
import SwiftData

enum BugStatus: String, Codable {
    case identified
    case active
    case stable
    case resolved
}

@Model
final class Bug {
    @Attribute(.unique) var id: UUID
    var slug: String
    var title: String
    var bugDescription: String
    var isActive: Bool
    var status: BugStatus
    var activatedAt: Date?
    var stableAt: Date?
    var resolvedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        slug: String,
        title: String,
        description: String,
        isActive: Bool = false,
        status: BugStatus = .identified,
        activatedAt: Date? = nil,
        stableAt: Date? = nil,
        resolvedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.slug = slug
        self.title = title
        self.bugDescription = description
        self.isActive = isActive
        self.status = status
        self.activatedAt = activatedAt
        self.stableAt = stableAt
        self.resolvedAt = resolvedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}
