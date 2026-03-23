import Foundation
import SwiftData

enum EducationTrigger: String, Codable {
    case postApply
    case postSkip
    case postCrash
    case postFailed
    case general
    case duringDiagnostic
    case restDay
}

@Model
final class MicroEducation {
    @Attribute(.unique) var id: UUID
    var bugSlug: String
    var trigger: EducationTrigger
    var body: String
    var teaser: String?
    var deepDive: String?
    var createdAt: Date
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        bugSlug: String,
        trigger: EducationTrigger,
        body: String,
        teaser: String? = nil,
        deepDive: String? = nil,
        createdAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.bugSlug = bugSlug
        self.trigger = trigger
        self.body = body
        self.teaser = teaser
        self.deepDive = deepDive
        self.createdAt = createdAt
        self.deletedAt = deletedAt
    }

    /// Teaser text, falling back to first sentence of body
    var effectiveTeaser: String {
        if let teaser, !teaser.isEmpty { return teaser }
        let sentences = body.components(separatedBy: ". ")
        return sentences.prefix(2).joined(separator: ". ") + (sentences.count > 2 ? "." : "")
    }

    /// Deep dive text, falling back to body after first sentence
    var effectiveDeepDive: String {
        if let deepDive, !deepDive.isEmpty { return deepDive }
        let sentences = body.components(separatedBy: ". ")
        guard sentences.count > 2 else { return body }
        return sentences.dropFirst(2).joined(separator: ". ")
    }
}
