import Foundation
import SwiftData

enum EventType: String, Codable {
    case fixAssigned
    case fixApplied
    case fixSkipped
    case fixFailed
    case crashLogged
    case crashRebooted
    case appOpened
    case weeklyCompleted
    case patternViewed
    case patternDismissed
    case fixShared
}

enum EventContext: String, Codable {
    case work
    case home
    case social
    case family
    case online
    case unknown
}

@Model
final class AnalyticsEvent {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var eventType: EventType
    var bugId: UUID?
    var fixId: UUID?
    var context: EventContext?
    var dayOfWeek: Int
    var hourOfDay: Int
    var timestamp: Date
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        userId: UUID,
        eventType: EventType,
        bugId: UUID? = nil,
        fixId: UUID? = nil,
        context: EventContext? = nil,
        dayOfWeek: Int,
        hourOfDay: Int,
        timestamp: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.eventType = eventType
        self.bugId = bugId
        self.fixId = fixId
        self.context = context
        self.dayOfWeek = dayOfWeek
        self.hourOfDay = hourOfDay
        self.timestamp = timestamp
        self.deletedAt = deletedAt
    }
}
