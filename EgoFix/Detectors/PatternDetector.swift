import Foundation

protocol PatternDetector {
    var patternType: PatternType { get }
    var minimumDataPoints: Int { get }
    func analyze(events: [AnalyticsEvent], diagnostics: [WeeklyDiagnostic], userId: UUID) -> DetectedPattern?
}
