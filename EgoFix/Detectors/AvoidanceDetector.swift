import Foundation

final class AvoidanceDetector: PatternDetector {
    let patternType: PatternType = .avoidance
    let minimumDataPoints: Int = 4

    // Triggers when >50% skip rate on a bug, minimum 4 skips
    private let skipRateThreshold: Double = 0.5
    private let minimumSkips: Int = 4

    func analyze(events: [AnalyticsEvent], diagnostics: [WeeklyDiagnostic], userId: UUID) -> DetectedPattern? {
        // Group events by bug
        var bugSkipCounts: [UUID: Int] = [:]
        var bugTotalCounts: [UUID: Int] = [:]

        for event in events {
            guard let bugId = event.bugId else { continue }

            switch event.eventType {
            case .fixSkipped:
                bugSkipCounts[bugId, default: 0] += 1
                bugTotalCounts[bugId, default: 0] += 1
            case .fixApplied, .fixFailed:
                bugTotalCounts[bugId, default: 0] += 1
            default:
                break
            }
        }

        // Find bugs with high skip rates
        for (bugId, skipCount) in bugSkipCounts {
            guard skipCount >= minimumSkips,
                  let totalCount = bugTotalCounts[bugId],
                  totalCount > 0 else { continue }

            let skipRate = Double(skipCount) / Double(totalCount)

            if skipRate > skipRateThreshold {
                return DetectedPattern(
                    userId: userId,
                    patternType: .avoidance,
                    severity: .insight,
                    title: "Avoidance Pattern",
                    body: "You've skipped \(skipCount) of \(totalCount) fixes for this bug. Avoidance is often a sign the bug is particularly active.",
                    relatedBugIds: [bugId],
                    dataPoints: totalCount
                )
            }
        }

        return nil
    }
}
