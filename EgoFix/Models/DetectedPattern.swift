import Foundation
import SwiftData

enum PatternType: String, Codable {
    case avoidance
    case temporalCrash
    case contextualSpike
    case correlatedBugs
    case plateau
    case regression
    case improvement
}

enum PatternSeverity: String, Codable {
    case observation
    case insight
    case alert
}

@Model
final class DetectedPattern {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var patternType: PatternType
    var severity: PatternSeverity
    var title: String
    var body: String
    var relatedBugIds: [UUID]
    var dataPoints: Int
    var detectedAt: Date
    var viewedAt: Date?
    var dismissedAt: Date?
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        userId: UUID,
        patternType: PatternType,
        severity: PatternSeverity,
        title: String,
        body: String,
        relatedBugIds: [UUID] = [],
        dataPoints: Int,
        detectedAt: Date = Date(),
        viewedAt: Date? = nil,
        dismissedAt: Date? = nil,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.patternType = patternType
        self.severity = severity
        self.title = title
        self.body = body
        self.relatedBugIds = relatedBugIds
        self.dataPoints = dataPoints
        self.detectedAt = detectedAt
        self.viewedAt = viewedAt
        self.dismissedAt = dismissedAt
        self.deletedAt = deletedAt
    }
}
