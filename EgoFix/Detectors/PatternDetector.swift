import Foundation

protocol PatternDetector {
    var patternType: PatternType { get }
    var minimumDataPoints: Int { get }

    /// Analyze events and diagnostics to detect patterns
    /// - Parameters:
    ///   - events: Analytics events for the user
    ///   - diagnostics: Weekly diagnostic responses for the user
    ///   - userId: The user's ID
    ///   - bugNames: Dictionary mapping bug UUIDs to their display titles
    /// - Returns: A detected pattern if one is found, nil otherwise
    func analyze(events: [AnalyticsEvent], diagnostics: [WeeklyDiagnostic], userId: UUID, bugNames: [UUID: String]) -> DetectedPattern?
}
