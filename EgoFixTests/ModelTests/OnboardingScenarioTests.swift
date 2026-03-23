import XCTest
@testable import EgoFix

final class OnboardingScenarioTests: XCTestCase {

    // MARK: - JSON Loading

    private func loadScenarios() throws -> [OnboardingScenario] {
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: "onboarding_scenarios", withExtension: "json")
            ?? Bundle.main.url(forResource: "onboarding_scenarios", withExtension: "json")
        guard let url else {
            XCTFail("onboarding_scenarios.json not found in any bundle")
            return []
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([OnboardingScenario].self, from: data)
    }

    // MARK: - Structure Tests

    func test_SeedData_scenariosLoadFromJSON() throws {
        let scenarios = try loadScenarios()
        XCTAssertEqual(scenarios.count, 3, "Should have exactly 3 scenarios")
    }

    func test_SeedData_scenariosHave3to4Options() throws {
        let scenarios = try loadScenarios()
        for scenario in scenarios {
            XCTAssertGreaterThanOrEqual(scenario.options.count, 3,
                "Scenario \(scenario.id) should have at least 3 options")
            XCTAssertLessThanOrEqual(scenario.options.count, 4,
                "Scenario \(scenario.id) should have at most 4 options")
        }
    }

    func test_SeedData_scenariosHaveUniqueIDs() throws {
        let scenarios = try loadScenarios()
        let ids = scenarios.map { $0.id }
        XCTAssertEqual(ids.count, Set(ids).count, "Duplicate scenario IDs found")
    }

    func test_SeedData_optionsHaveUniqueIDsPerScenario() throws {
        let scenarios = try loadScenarios()
        for scenario in scenarios {
            let ids = scenario.options.map { $0.id }
            XCTAssertEqual(ids.count, Set(ids).count,
                "Duplicate option IDs in scenario \(scenario.id)")
        }
    }

    func test_SeedData_scenariosHaveNonEmptySituations() throws {
        let scenarios = try loadScenarios()
        for scenario in scenarios {
            XCTAssertFalse(scenario.situation.isEmpty,
                "Scenario \(scenario.id) has empty situation")
        }
    }

    func test_SeedData_reframesNotEmpty() throws {
        let scenarios = try loadScenarios()
        for scenario in scenarios {
            XCTAssertFalse(scenario.reframe.isEmpty,
                "Scenario \(scenario.id) has empty reframe")
            XCTAssertTrue(scenario.reframe.hasPrefix("//"),
                "Scenario \(scenario.id) reframe should be a code comment (start with //)")
        }
    }

    func test_SeedData_optionsHaveNonEmptyText() throws {
        let scenarios = try loadScenarios()
        for scenario in scenarios {
            for option in scenario.options {
                XCTAssertFalse(option.text.isEmpty,
                    "Option \(option.id) in scenario \(scenario.id) has empty text")
            }
        }
    }

    // MARK: - Weight Validation

    func test_SeedData_weightsBounded() throws {
        let scenarios = try loadScenarios()
        for scenario in scenarios {
            for option in scenario.options {
                for (slug, weight) in option.weights {
                    XCTAssertGreaterThanOrEqual(weight, 0.0,
                        "Weight for \(slug) in \(scenario.id).\(option.id) is negative: \(weight)")
                    XCTAssertLessThanOrEqual(weight, 1.0,
                        "Weight for \(slug) in \(scenario.id).\(option.id) exceeds 1.0: \(weight)")
                }
            }
        }
    }

    func test_SeedData_weightsOnlyReferenceValidBugs() throws {
        let validSlugs = Set(ScenarioWeightCalculator.allBugSlugs)
        let scenarios = try loadScenarios()
        for scenario in scenarios {
            for option in scenario.options {
                for slug in option.weights.keys {
                    XCTAssertTrue(validSlugs.contains(slug),
                        "Unknown bug slug '\(slug)' in \(scenario.id).\(option.id)")
                }
            }
        }
    }

    func test_SeedData_allBugsRepresentedAcrossScenarios() throws {
        let scenarios = try loadScenarios()
        var allSlugs: Set<String> = []
        for scenario in scenarios {
            for option in scenario.options {
                allSlugs.formUnion(option.weights.keys)
            }
        }
        let expectedSlugs = Set(ScenarioWeightCalculator.allBugSlugs)
        XCTAssertEqual(allSlugs, expectedSlugs,
            "Not all bugs are reachable from scenarios. Missing: \(expectedSlugs.subtracting(allSlugs))")
    }

    func test_SeedData_everyBugReachableFrom2Scenarios() throws {
        let scenarios = try loadScenarios()
        for slug in ScenarioWeightCalculator.allBugSlugs {
            var scenariosWithSlug = 0
            for scenario in scenarios {
                let hasSlug = scenario.options.contains { $0.weights[slug] != nil }
                if hasSlug { scenariosWithSlug += 1 }
            }
            XCTAssertGreaterThanOrEqual(scenariosWithSlug, 2,
                "Bug \(slug) should be reachable from at least 2 scenarios, found \(scenariosWithSlug)")
        }
    }

    // MARK: - Weight Calculation Tests

    func test_accumulateWeights_singleOption() {
        let scenario = OnboardingScenario(
            id: "test",
            situation: "Test",
            options: [
                ScenarioOption(id: "a", text: "Option A", weights: ["need-to-be-right": 0.8, "need-to-control": 0.3])
            ],
            reframe: "// test"
        )
        let weights = ScenarioWeightCalculator.accumulateWeights(
            from: [0: "a"],
            scenarios: [scenario]
        )
        XCTAssertEqual(weights["need-to-be-right"] ?? 0, 0.8, accuracy: 0.001)
        XCTAssertEqual(weights["need-to-control"] ?? 0, 0.3, accuracy: 0.001)
        XCTAssertNil(weights["need-to-be-liked"])
    }

    func test_accumulateWeights_multipleScenariosSumCorrectly() {
        let scenarios = [
            OnboardingScenario(
                id: "s1", situation: "S1",
                options: [ScenarioOption(id: "a", text: "A", weights: ["need-to-be-liked": 0.8, "need-to-deflect": 0.3])],
                reframe: "// r1"
            ),
            OnboardingScenario(
                id: "s2", situation: "S2",
                options: [ScenarioOption(id: "b", text: "B", weights: ["need-to-be-liked": 0.4, "need-to-impress": 0.7])],
                reframe: "// r2"
            ),
            OnboardingScenario(
                id: "s3", situation: "S3",
                options: [ScenarioOption(id: "c", text: "C", weights: ["need-to-deflect": 0.5])],
                reframe: "// r3"
            ),
        ]
        let weights = ScenarioWeightCalculator.accumulateWeights(
            from: [0: "a", 1: "b", 2: "c"],
            scenarios: scenarios
        )
        XCTAssertEqual(weights["need-to-be-liked"] ?? 0, 1.2, accuracy: 0.001)
        XCTAssertEqual(weights["need-to-deflect"] ?? 0, 0.8, accuracy: 0.001)
        XCTAssertEqual(weights["need-to-impress"] ?? 0, 0.7, accuracy: 0.001)
    }

    func test_accumulateWeights_invalidSelectionIgnored() {
        let scenario = OnboardingScenario(
            id: "test", situation: "Test",
            options: [ScenarioOption(id: "a", text: "A", weights: ["need-to-be-right": 0.5])],
            reframe: "// test"
        )
        let weights = ScenarioWeightCalculator.accumulateWeights(
            from: [0: "z"],  // "z" doesn't exist
            scenarios: [scenario]
        )
        XCTAssertTrue(weights.isEmpty)
    }

    func test_accumulateWeights_outOfBoundsScenarioIgnored() {
        let scenario = OnboardingScenario(
            id: "test", situation: "Test",
            options: [ScenarioOption(id: "a", text: "A", weights: ["need-to-be-right": 0.5])],
            reframe: "// test"
        )
        let weights = ScenarioWeightCalculator.accumulateWeights(
            from: [5: "a"],  // index 5 doesn't exist
            scenarios: [scenario]
        )
        XCTAssertTrue(weights.isEmpty)
    }

    // MARK: - Ranking Tests

    func test_rankBugSlugs_sortsDescending() {
        let weights: [String: Double] = [
            "need-to-be-right": 0.3,
            "need-to-be-liked": 1.2,
            "need-to-control": 0.8,
            "need-to-compare": 0.0,
            "need-to-impress": 0.7,
            "need-to-deflect": 0.5,
            "need-to-narrate": 1.5
        ]
        let ranked = ScenarioWeightCalculator.rankBugSlugs(by: weights)
        XCTAssertEqual(ranked[0], "need-to-narrate")
        XCTAssertEqual(ranked[1], "need-to-be-liked")
        XCTAssertEqual(ranked[2], "need-to-control")
        XCTAssertEqual(ranked[3], "need-to-impress")
    }

    func test_rankBugSlugs_tiesResolvedByCanonicalOrder() {
        let weights: [String: Double] = [
            "need-to-be-right": 0.5,
            "need-to-be-liked": 0.5,
            "need-to-control": 0.5,
            "need-to-compare": 0.5,
            "need-to-impress": 0.5,
            "need-to-deflect": 0.5,
            "need-to-narrate": 0.5
        ]
        let ranked = ScenarioWeightCalculator.rankBugSlugs(by: weights)
        // All tied → canonical order
        XCTAssertEqual(ranked, ScenarioWeightCalculator.allBugSlugs)
    }

    func test_rankBugSlugs_emptyWeightsReturnsCanonicalOrder() {
        let ranked = ScenarioWeightCalculator.rankBugSlugs(by: [:])
        XCTAssertEqual(ranked, ScenarioWeightCalculator.allBugSlugs)
    }

    func test_rankBugSlugs_returnsAll7() {
        let weights: [String: Double] = ["need-to-narrate": 2.0]
        let ranked = ScenarioWeightCalculator.rankBugSlugs(by: weights)
        XCTAssertEqual(ranked.count, 7)
        XCTAssertEqual(ranked[0], "need-to-narrate")
    }
}
