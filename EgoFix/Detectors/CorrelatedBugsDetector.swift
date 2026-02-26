import Foundation

final class CorrelatedBugsDetector: PatternDetector {
    let patternType: PatternType = .correlatedBugs
    let minimumDataPoints: Int = 6

    // Triggers when Pearson r > 0.7 over 6+ weeks
    private let correlationThreshold: Double = 0.7
    private let minimumWeeks: Int = 6

    func analyze(events: [AnalyticsEvent], diagnostics: [WeeklyDiagnostic], userId: UUID) -> DetectedPattern? {
        guard diagnostics.count >= minimumWeeks else { return nil }

        // Get all unique bug IDs from diagnostics
        let allBugIds = Set(diagnostics.flatMap { $0.responses.map { $0.bugId } })
        let bugIdArray = Array(allBugIds)

        guard bugIdArray.count >= 2 else { return nil }

        // Build intensity timelines for each bug
        var bugIntensities: [UUID: [Double]] = [:]

        // Sort diagnostics by date
        let sortedDiagnostics = diagnostics.sorted { $0.weekStarting < $1.weekStarting }

        for diagnostic in sortedDiagnostics {
            for bugId in bugIdArray {
                let intensity = diagnostic.responses
                    .first { $0.bugId == bugId }
                    .map { intensityValue($0.intensity) } ?? 0.0

                bugIntensities[bugId, default: []].append(intensity)
            }
        }

        // Check correlations between all pairs
        for i in 0..<bugIdArray.count {
            for j in (i + 1)..<bugIdArray.count {
                let bugA = bugIdArray[i]
                let bugB = bugIdArray[j]

                guard let intensitiesA = bugIntensities[bugA],
                      let intensitiesB = bugIntensities[bugB],
                      intensitiesA.count >= minimumWeeks,
                      intensitiesB.count >= minimumWeeks else { continue }

                let correlation = pearsonCorrelation(intensitiesA, intensitiesB)

                if correlation > correlationThreshold {
                    return DetectedPattern(
                        userId: userId,
                        patternType: .correlatedBugs,
                        severity: .insight,
                        title: "Correlated Bugs",
                        body: "These two bugs tend to flare up together. They might share a root cause.",
                        relatedBugIds: [bugA, bugB],
                        dataPoints: sortedDiagnostics.count
                    )
                }
            }
        }

        return nil
    }

    private func intensityValue(_ intensity: BugIntensity) -> Double {
        switch intensity {
        case .quiet: return 0.0
        case .present: return 0.5
        case .loud: return 1.0
        }
    }

    private func pearsonCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        guard x.count == y.count, x.count > 0 else { return 0.0 }

        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)

        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))

        guard denominator != 0 else { return 0.0 }

        return numerator / denominator
    }
}
