import Foundation

/// Action types for pattern recommendations
enum RecommendationAction: String, Codable {
    case adjustPriority        // "Consider raising priority for this bug"
    case practiceMore          // "More practice with this type of fix"
    case avoidContext          // "Be aware of triggers in X context"
    case celebrateProgress     // "You're making progress!"
    case seekSupport           // "Consider external support"
    case reviewTime            // "Try fixes at a different time"
    case slowDown              // "Take more time with fixes"
    case focusOnOne            // "Focus on one bug at a time"
    case changeApproach        // "Try a different approach"
    case maintainCourse        // "Keep doing what you're doing"
}

/// A recommendation generated from a detected pattern
struct PatternRecommendation: Identifiable, Codable {
    let id: UUID
    let actionType: RecommendationAction
    let title: String
    let description: String
    let priority: Int  // 1 = highest priority

    init(
        id: UUID = UUID(),
        actionType: RecommendationAction,
        title: String,
        description: String,
        priority: Int = 1
    ) {
        self.id = id
        self.actionType = actionType
        self.title = title
        self.description = description
        self.priority = priority
    }
}
