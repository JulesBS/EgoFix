import Foundation

// MARK: - Onboarding Scenario Models

/// A response option within an onboarding scenario.
/// Each option carries weighted signals toward one or more ego bugs.
struct ScenarioOption: Codable, Identifiable, Equatable {
    let id: String
    let text: String
    let weights: [String: Double] // bugSlug → weight (0.0-1.0)
}

/// A situational scenario presented during onboarding to probe for ego patterns.
/// The user reads the situation, picks a response, and their accumulated weights
/// determine which bugs surface in the reveal phase.
struct OnboardingScenario: Codable, Identifiable, Equatable {
    let id: String
    let situation: String
    let options: [ScenarioOption]
    let reframe: String // Post-answer educational comment (displayed as inline comment)
}

// MARK: - Scenario Loader

enum OnboardingScenarioLoader {
    /// Loads scenarios from the bundled JSON seed data.
    static func loadScenarios() -> [OnboardingScenario] {
        guard let url = Bundle.main.url(forResource: "onboarding_scenarios", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return []
        }
        return (try? JSONDecoder().decode([OnboardingScenario].self, from: data)) ?? []
    }
}

// MARK: - Weight Calculation

enum ScenarioWeightCalculator {
    /// All known bug slugs in canonical order.
    static let allBugSlugs: [String] = [
        "need-to-be-right",
        "need-to-be-liked",
        "need-to-control",
        "need-to-compare",
        "need-to-impress",
        "need-to-deflect",
        "need-to-narrate"
    ]

    /// Accumulates bug weights from a set of scenario selections.
    /// - Parameters:
    ///   - selections: Maps scenario index to selected option ID
    ///   - scenarios: The scenario definitions
    /// - Returns: Dictionary of bugSlug → total accumulated weight
    static func accumulateWeights(
        from selections: [Int: String],
        scenarios: [OnboardingScenario]
    ) -> [String: Double] {
        var totals: [String: Double] = [:]
        for (scenarioIndex, optionId) in selections {
            guard scenarioIndex < scenarios.count,
                  let option = scenarios[scenarioIndex].options.first(where: { $0.id == optionId })
            else { continue }
            for (slug, weight) in option.weights {
                totals[slug, default: 0] += weight
            }
        }
        return totals
    }

    /// Ranks bug slugs by accumulated weight, descending.
    /// Ties broken by canonical order.
    /// - Parameter weights: bugSlug → total weight
    /// - Returns: Bug slugs sorted by weight (highest first)
    static func rankBugSlugs(by weights: [String: Double]) -> [String] {
        allBugSlugs.sorted { a, b in
            let wa = weights[a] ?? 0
            let wb = weights[b] ?? 0
            if wa != wb { return wa > wb }
            let ia = allBugSlugs.firstIndex(of: a) ?? 0
            let ib = allBugSlugs.firstIndex(of: b) ?? 0
            return ia < ib
        }
    }
}
