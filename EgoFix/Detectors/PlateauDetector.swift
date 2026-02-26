import Foundation

final class PlateauDetector: PatternDetector {
    let patternType: PatternType = .plateau
    let minimumDataPoints: Int = 6

    // Triggers when 4+ weeks present/loud despite 6+ fixes applied
    private let minimumStagnantWeeks: Int = 4
    private let minimumFixesApplied: Int = 6

    func analyze(events: [AnalyticsEvent], diagnostics: [WeeklyDiagnostic], userId: UUID, bugNames: [UUID: String]) -> DetectedPattern? {
        guard diagnostics.count >= minimumStagnantWeeks else { return nil }

        // Get applied fix counts per bug
        var bugAppliedCounts: [UUID: Int] = [:]
        for event in events where event.eventType == .fixApplied {
            if let bugId = event.bugId {
                bugAppliedCounts[bugId, default: 0] += 1
            }
        }

        // Sort diagnostics by date (most recent first)
        let sortedDiagnostics = diagnostics.sorted { $0.weekStarting > $1.weekStarting }
        let recentDiagnostics = Array(sortedDiagnostics.prefix(minimumStagnantWeeks))

        // Check each bug for plateau
        let allBugIds = Set(diagnostics.flatMap { $0.responses.map { $0.bugId } })

        for bugId in allBugIds {
            guard let appliedCount = bugAppliedCounts[bugId],
                  appliedCount >= minimumFixesApplied else { continue }

            // Count weeks where this bug was present or loud
            var stagnantWeeks = 0

            for diagnostic in recentDiagnostics {
                if let response = diagnostic.responses.first(where: { $0.bugId == bugId }) {
                    if response.intensity == .present || response.intensity == .loud {
                        stagnantWeeks += 1
                    }
                }
            }

            if stagnantWeeks >= minimumStagnantWeeks {
                let bugName = bugNames[bugId] ?? "this bug"
                return DetectedPattern(
                    userId: userId,
                    patternType: .plateau,
                    severity: .alert,
                    title: "Stuck",
                    body: "\(appliedCount) fixes for '\(bugName).' \(stagnantWeeks) weeks still loud. What you're doing isn't working.",
                    relatedBugIds: [bugId],
                    dataPoints: appliedCount
                )
            }
        }

        return nil
    }
}
