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
                title: "Raise Bug Priority",
                description: "Consider making this bug your top priority. Avoidance often signals resistance to change - the very thing that needs attention.",
                priority: 1
            ),
            PatternRecommendation(
                actionType: .practiceMore,
                title: "Start Small",
                description: "Try committing to just the first step of fixes for this bug. Small wins build momentum.",
                priority: 2
            )
        ]
    }

    private static func temporalCrashRecommendations() -> [PatternRecommendation] {
        [
            PatternRecommendation(
                actionType: .reviewTime,
                title: "Plan Around Peak Times",
                description: "You tend to crash at specific times. Schedule important interactions or decisions outside these windows.",
                priority: 1
            ),
            PatternRecommendation(
                actionType: .slowDown,
                title: "Add Buffer Time",
                description: "Before your typical crash times, take 5 minutes to center yourself. Awareness is half the battle.",
                priority: 2
            )
        ]
    }

    private static func contextSpikeRecommendations() -> [PatternRecommendation] {
        [
            PatternRecommendation(
                actionType: .avoidContext,
                title: "Prepare for Triggers",
                description: "Before entering this context, remind yourself of your bug. Pre-commitment reduces reactive behavior.",
                priority: 1
            ),
            PatternRecommendation(
                actionType: .practiceMore,
                title: "Practice in Safe Mode",
                description: "When possible, enter this context with lower stakes first. Build your tolerance gradually.",
                priority: 2
            )
        ]
    }

    private static func correlatedBugsRecommendations() -> [PatternRecommendation] {
        [
            PatternRecommendation(
                actionType: .focusOnOne,
                title: "Focus on One Bug",
                description: "These bugs tend to flare together. Pick one to focus on - progress on one often improves the other.",
                priority: 1
            ),
            PatternRecommendation(
                actionType: .seekSupport,
                title: "Look for Root Cause",
                description: "Correlated bugs may share a deeper root. Consider journaling about what underlies both patterns.",
                priority: 2
            )
        ]
    }

    private static func plateauRecommendations() -> [PatternRecommendation] {
        [
            PatternRecommendation(
                actionType: .changeApproach,
                title: "Try Something Different",
                description: "You've been putting in effort without progress. It might be time to approach this bug from a new angle.",
                priority: 1
            ),
            PatternRecommendation(
                actionType: .seekSupport,
                title: "Consider Outside Help",
                description: "Persistent patterns sometimes need external perspective. A coach, therapist, or trusted friend might see what you can't.",
                priority: 2
            )
        ]
    }

    private static func regressionRecommendations() -> [PatternRecommendation] {
        [
            PatternRecommendation(
                actionType: .slowDown,
                title: "Don't Panic",
                description: "Regression is normal. It often happens when stress increases or old patterns get triggered. This is data, not failure.",
                priority: 1
            ),
            PatternRecommendation(
                actionType: .practiceMore,
                title: "Return to Basics",
                description: "Go back to the simpler fixes that worked before. Rebuild your foundation before pushing forward.",
                priority: 2
            )
        ]
    }

    private static func improvementRecommendations() -> [PatternRecommendation] {
        [
            PatternRecommendation(
                actionType: .celebrateProgress,
                title: "Acknowledge Your Progress",
                description: "You're improving. Take a moment to recognize the work you've done - this is real change.",
                priority: 1
            ),
            PatternRecommendation(
                actionType: .maintainCourse,
                title: "Keep Going",
                description: "What you're doing is working. Don't fix what isn't broken - stay the course.",
                priority: 2
            )
        ]
    }
}
