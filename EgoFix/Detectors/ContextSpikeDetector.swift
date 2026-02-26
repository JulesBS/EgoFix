import Foundation

final class ContextSpikeDetector: PatternDetector {
    let patternType: PatternType = .contextualSpike
    let minimumDataPoints: Int = 3

    // Triggers when >60% loud responses in one context, minimum 3
    private let loudThreshold: Double = 0.6
    private let minimumLoudResponses: Int = 3

    func analyze(events: [AnalyticsEvent], diagnostics: [WeeklyDiagnostic], userId: UUID, bugNames: [UUID: String]) -> DetectedPattern? {
        // Analyze weekly diagnostic responses for context spikes
        var contextLoudCounts: [EventContext: Int] = [:]
        var contextTotalCounts: [EventContext: Int] = [:]
        var bugIdsWithSpikes: Set<UUID> = []

        for diagnostic in diagnostics {
            for response in diagnostic.responses {
                guard let context = response.primaryContext else { continue }

                contextTotalCounts[context, default: 0] += 1

                if response.intensity == .loud {
                    contextLoudCounts[context, default: 0] += 1
                    bugIdsWithSpikes.insert(response.bugId)
                }
            }
        }

        // Find contexts with high loud rates
        for (context, loudCount) in contextLoudCounts {
            guard loudCount >= minimumLoudResponses,
                  let totalCount = contextTotalCounts[context],
                  totalCount > 0 else { continue }

            let loudRate = Double(loudCount) / Double(totalCount)

            if loudRate > loudThreshold {
                let contextName = contextDisplayName(context)
                let relatedBugIds = Array(bugIdsWithSpikes)
                let bugNamesList = relatedBugIds.compactMap { bugNames[$0] }.joined(separator: ", ")
                let bugContext = bugNamesList.isEmpty ? "" : " Bugs involved: \(bugNamesList)."
                return DetectedPattern(
                    userId: userId,
                    patternType: .contextualSpike,
                    severity: .insight,
                    title: "\(contextName) is a minefield",
                    body: "\(loudCount) of \(totalCount) check-ins at \(contextName.lowercased()) were loud. That environment's got your number.\(bugContext)",
                    relatedBugIds: relatedBugIds,
                    dataPoints: totalCount
                )
            }
        }

        return nil
    }

    private func contextDisplayName(_ context: EventContext) -> String {
        switch context {
        case .work: return "Work"
        case .home: return "Home"
        case .social: return "Social"
        case .family: return "Family"
        case .online: return "Online"
        case .unknown: return "Unknown"
        }
    }
}
