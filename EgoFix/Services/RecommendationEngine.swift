import Foundation

/// Generates actionable recommendations for detected patterns
final class RecommendationEngine {

    /// Generate recommendations for a given pattern
    static func generateRecommendations(for pattern: DetectedPattern) -> [PatternRecommendation] {
        switch pattern.patternType {
        case .avoidance:
            return avoidanceRecommendations()
        case .temporalCrash:
            return temporalCrashRecommendations()
        case .contextualSpike:
            return contextSpikeRecommendations()
        case .correlatedBugs:
            return correlatedBugsRecommendations()
        case .plateau:
            return plateauRecommendations()
        case .regression:
            return regressionRecommendations()
        case .improvement:
            return improvementRecommendations()
        }
    }

    // MARK: - Private Recommendation Generators

    private static func avoidanceRecommendations() -> [PatternRecommendation] {
        [
            PatternRecommendation(
                actionType: .adjustPriority,
                title: "Face it",
                description: "The ones you skip are usually the ones that matter. Make this bug top priority.",
                priority: 1
            ),
            PatternRecommendation(
                actionType: .practiceMore,
                title: "Just the first step",
                description: "Don't commit to the whole fix. Just the first step. See what happens.",
                priority: 2
            )
        ]
    }

    private static func temporalCrashRecommendations() -> [PatternRecommendation] {
        [
            PatternRecommendation(
                actionType: .reviewTime,
                title: "Schedule around it",
                description: "No important decisions during your crash window. Move the meeting. Delay the text.",
                priority: 1
            ),
            PatternRecommendation(
                actionType: .slowDown,
                title: "Pre-game",
                description: "Five minutes before your usual crash time. Just notice you're entering the danger zone.",
                priority: 2
            )
        ]
    }

    private static func contextSpikeRecommendations() -> [PatternRecommendation] {
        [
            PatternRecommendation(
                actionType: .avoidContext,
                title: "Know before you go",
                description: "Before entering that context, name the bug out loud. It helps.",
                priority: 1
            ),
            PatternRecommendation(
                actionType: .practiceMore,
                title: "Lower the stakes",
                description: "Practice in that context when nothing's on the line. Build tolerance.",
                priority: 2
            )
        ]
    }

    private static func correlatedBugsRecommendations() -> [PatternRecommendation] {
        [
            PatternRecommendation(
                actionType: .focusOnOne,
                title: "Pick one",
                description: "They move together. Fix one, the other usually follows.",
                priority: 1
            ),
            PatternRecommendation(
                actionType: .seekSupport,
                title: "Dig deeper",
                description: "Two bugs, same root. Worth asking what's underneath both.",
                priority: 2
            )
        ]
    }

    private static func plateauRecommendations() -> [PatternRecommendation] {
        [
            PatternRecommendation(
                actionType: .changeApproach,
                title: "Try something else",
                description: "Same approach, same result. Time for a different angle.",
                priority: 1
            ),
            PatternRecommendation(
                actionType: .seekSupport,
                title: "Get outside eyes",
                description: "Blind spots are called that for a reason. Someone else might see what you can't.",
                priority: 2
            )
        ]
    }

    private static func regressionRecommendations() -> [PatternRecommendation] {
        [
            PatternRecommendation(
                actionType: .slowDown,
                title: "It happens",
                description: "Regression is data, not failure. Something triggered the old pattern. Find out what.",
                priority: 1
            ),
            PatternRecommendation(
                actionType: .practiceMore,
                title: "Back to basics",
                description: "The simple fixes that worked before. Do those again.",
                priority: 2
            )
        ]
    }

    private static func improvementRecommendations() -> [PatternRecommendation] {
        [
            PatternRecommendation(
                actionType: .celebrateProgress,
                title: "Still running",
                description: "Whatever you're doing, it's working. Don't overthink it.",
                priority: 1
            ),
            PatternRecommendation(
                actionType: .maintainCourse,
                title: "Stay the course",
                description: "Don't fix what isn't broken.",
                priority: 2
            )
        ]
    }
}
