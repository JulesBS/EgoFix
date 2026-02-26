import Foundation

final class ImprovementDetector: PatternDetector {
    let patternType: PatternType = .improvement
    let minimumDataPoints: Int = 4

    // Triggers when downward trend ending in quiet over 4+ weeks
    private let minimumWeeks: Int = 4

    func analyze(events: [AnalyticsEvent], diagnostics: [WeeklyDiagnostic], userId: UUID, bugNames: [UUID: String]) -> DetectedPattern? {
        guard diagnostics.count >= minimumWeeks else { return nil }

        // Sort diagnostics by date (oldest first)
        let sortedDiagnostics = diagnostics.sorted { $0.weekStarting < $1.weekStarting }

        // Get all unique bug IDs
        let allBugIds = Set(diagnostics.flatMap { $0.responses.map { $0.bugId } })

        for bugId in allBugIds {
            // Get intensity timeline for this bug
            var intensities: [BugIntensity] = []

            for diagnostic in sortedDiagnostics {
                if let response = diagnostic.responses.first(where: { $0.bugId == bugId }) {
                    intensities.append(response.intensity)
                }
            }

            guard intensities.count >= minimumWeeks else { continue }

            // Check last N weeks for downward trend
            let recentIntensities = Array(intensities.suffix(minimumWeeks))

            if isDownwardTrendEndingQuiet(recentIntensities) {
                let bugName = bugNames[bugId] ?? "This bug"
                return DetectedPattern(
                    userId: userId,
                    patternType: .improvement,
                    severity: .observation,
                    title: "Still running",
                    body: "'\(bugName)' has been quiet for \(minimumWeeks) weeks. Whatever you're doing, keep doing it.",
                    relatedBugIds: [bugId],
                    dataPoints: intensities.count
                )
            }
        }

        return nil
    }

    private func isDownwardTrendEndingQuiet(_ intensities: [BugIntensity]) -> Bool {
        guard let last = intensities.last, last == .quiet else {
            return false
        }

        // Check that trend is downward (or at least not upward)
        var previousValue = intensityValue(intensities[0])
        var downwardCount = 0
        var upwardCount = 0

        for i in 1..<intensities.count {
            let currentValue = intensityValue(intensities[i])
            if currentValue < previousValue {
                downwardCount += 1
            } else if currentValue > previousValue {
                upwardCount += 1
            }
            previousValue = currentValue
        }

        // More downward moves than upward, ending in quiet
        return downwardCount > upwardCount
    }

    private func intensityValue(_ intensity: BugIntensity) -> Int {
        switch intensity {
        case .quiet: return 0
        case .present: return 1
        case .loud: return 2
        }
    }
}
