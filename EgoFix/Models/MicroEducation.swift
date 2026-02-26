import Foundation
import SwiftData

enum EducationTrigger: String, Codable {
    case postApply
    case postSkip
    case postCrash
    case general
}

@Model
final class MicroEducation {
    @Attribute(.unique) var id: UUID
    var bugSlug: String
    var trigger: EducationTrigger
    var body: String
    var createdAt: Date
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        bugSlug: String,
        trigger: EducationTrigger,
        body: String,
        createdAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.bugSlug = bugSlug
        self.trigger = trigger
        self.body = body
        self.createdAt = createdAt
        self.deletedAt = deletedAt
    }
}
