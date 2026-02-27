import Foundation
import SwiftData

enum BugIntensity: String, Codable {
    case quiet
    case present
    case loud

    var quieter: BugIntensity {
        switch self {
        case .quiet: return .quiet
        case .present: return .quiet
        case .loud: return .present
        }
    }

    var louder: BugIntensity {
        switch self {
        case .quiet: return .present
        case .present: return .loud
        case .loud: return .loud
        }
    }
}

struct BugDiagnosticResponse: Codable {
    let bugId: UUID
    let intensity: BugIntensity
    let primaryContext: EventContext?
}

@Model
final class WeeklyDiagnostic {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var weekStarting: Date
    var responses: [BugDiagnosticResponse]
    var completedAt: Date
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        userId: UUID,
        weekStarting: Date,
        responses: [BugDiagnosticResponse] = [],
        completedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.weekStarting = weekStarting
        self.responses = responses
        self.completedAt = completedAt
        self.deletedAt = deletedAt
    }
}
