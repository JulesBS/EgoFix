import XCTest
@testable import EgoFix

final class FixConfigurationTests: XCTestCase {

    // MARK: - TimedConfig Tests

    func test_TimedConfig_encodesAndDecodes() throws {
        let config = TimedConfig(durationSeconds: 300)

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(TimedConfig.self, from: data)

        XCTAssertEqual(decoded, config)
        XCTAssertEqual(decoded.durationSeconds, 300)
    }

    func test_TimedConfig_decodesFromJSON() throws {
        let json = """
        {"durationSeconds": 600}
        """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(TimedConfig.self, from: data)

        XCTAssertEqual(decoded.durationSeconds, 600)
    }

    // MARK: - MultiStepConfig Tests

    func test_MultiStepConfig_encodesAndDecodes() throws {
        let config = MultiStepConfig(steps: [
            .init(id: "step-1", prompt: "First step", validation: "Check it", inlineComment: "Comment 1"),
            .init(id: "step-2", prompt: "Second step", validation: nil, inlineComment: nil)
        ])

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(MultiStepConfig.self, from: data)

        XCTAssertEqual(decoded, config)
        XCTAssertEqual(decoded.steps.count, 2)
        XCTAssertEqual(decoded.steps[0].id, "step-1")
        XCTAssertEqual(decoded.steps[0].prompt, "First step")
        XCTAssertEqual(decoded.steps[0].validation, "Check it")
        XCTAssertEqual(decoded.steps[0].inlineComment, "Comment 1")
        XCTAssertEqual(decoded.steps[1].id, "step-2")
        XCTAssertNil(decoded.steps[1].validation)
    }

    func test_MultiStepConfig_StepItem_isIdentifiable() {
        let step = MultiStepConfig.StepItem(
            id: "test-id",
            prompt: "Test prompt",
            validation: nil,
            inlineComment: nil
        )

        XCTAssertEqual(step.id, "test-id")
    }

    func test_MultiStepConfig_decodesFromJSON() throws {
        let json = """
        {
            "steps": [
                {"id": "s1", "prompt": "Do this", "validation": "Did you?", "inlineComment": "Note"},
                {"id": "s2", "prompt": "Then this", "validation": null, "inlineComment": null}
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(MultiStepConfig.self, from: data)

        XCTAssertEqual(decoded.steps.count, 2)
        XCTAssertEqual(decoded.steps[0].prompt, "Do this")
    }

    // MARK: - QuizConfig Tests

    func test_QuizConfig_encodesAndDecodes() throws {
        let config = QuizConfig(
            question: "What do you do?",
            options: [
                .init(id: "a", text: "Option A", weightModifier: 1.2, insight: "Insight A"),
                .init(id: "b", text: "Option B", weightModifier: 0.8, insight: nil)
            ],
            explanationAfter: "This explains things"
        )

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(QuizConfig.self, from: data)

        XCTAssertEqual(decoded, config)
        XCTAssertEqual(decoded.question, "What do you do?")
        XCTAssertEqual(decoded.options.count, 2)
        XCTAssertEqual(decoded.options[0].weightModifier, 1.2)
        XCTAssertEqual(decoded.options[0].insight, "Insight A")
        XCTAssertNil(decoded.options[1].insight)
        XCTAssertEqual(decoded.explanationAfter, "This explains things")
    }

    func test_QuizConfig_QuizOption_isIdentifiable() {
        let option = QuizConfig.QuizOption(
            id: "opt-1",
            text: "Test option",
            weightModifier: 1.0,
            insight: nil
        )

        XCTAssertEqual(option.id, "opt-1")
    }

    func test_QuizConfig_decodesWithNullExplanation() throws {
        let json = """
        {
            "question": "Test?",
            "options": [
                {"id": "x", "text": "X", "weightModifier": 1.0, "insight": null}
            ],
            "explanationAfter": null
        }
        """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(QuizConfig.self, from: data)

        XCTAssertNil(decoded.explanationAfter)
    }

    // MARK: - ScenarioConfig Tests

    func test_ScenarioConfig_encodesAndDecodes() throws {
        let config = ScenarioConfig(
            situation: "You're in a meeting...",
            options: [
                .init(id: "opt-1", text: "Speak up", weightModifier: 1.3, reflection: "Bold choice"),
                .init(id: "opt-2", text: "Stay quiet", weightModifier: 0.7, reflection: nil)
            ],
            debrief: "Consider how this felt"
        )

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(ScenarioConfig.self, from: data)

        XCTAssertEqual(decoded, config)
        XCTAssertEqual(decoded.situation, "You're in a meeting...")
        XCTAssertEqual(decoded.options.count, 2)
        XCTAssertEqual(decoded.options[0].weightModifier, 1.3)
        XCTAssertEqual(decoded.options[0].reflection, "Bold choice")
        XCTAssertEqual(decoded.debrief, "Consider how this felt")
    }

    func test_ScenarioConfig_ScenarioOption_isIdentifiable() {
        let option = ScenarioConfig.ScenarioOption(
            id: "scenario-opt",
            text: "Test",
            weightModifier: 1.0,
            reflection: nil
        )

        XCTAssertEqual(option.id, "scenario-opt")
    }

    func test_ScenarioConfig_decodesWithNullDebrief() throws {
        let json = """
        {
            "situation": "Test situation",
            "options": [
                {"id": "a", "text": "A", "weightModifier": 1.0, "reflection": null}
            ],
            "debrief": null
        }
        """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(ScenarioConfig.self, from: data)

        XCTAssertNil(decoded.debrief)
    }

    // MARK: - CounterConfig Tests

    func test_CounterConfig_encodesAndDecodes() throws {
        let config = CounterConfig(
            counterPrompt: "Times you wanted to correct someone",
            minTarget: 0,
            maxTarget: 10
        )

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(CounterConfig.self, from: data)

        XCTAssertEqual(decoded, config)
        XCTAssertEqual(decoded.counterPrompt, "Times you wanted to correct someone")
        XCTAssertEqual(decoded.minTarget, 0)
        XCTAssertEqual(decoded.maxTarget, 10)
    }

    func test_CounterConfig_targetsCanBeNil() throws {
        let config = CounterConfig(
            counterPrompt: "Just count",
            minTarget: nil,
            maxTarget: nil
        )

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(CounterConfig.self, from: data)

        XCTAssertEqual(decoded, config)
        XCTAssertNil(decoded.minTarget)
        XCTAssertNil(decoded.maxTarget)
    }

    func test_CounterConfig_decodesFromJSON() throws {
        let json = """
        {"counterPrompt": "Count this", "minTarget": 5, "maxTarget": null}
        """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(CounterConfig.self, from: data)

        XCTAssertEqual(decoded.counterPrompt, "Count this")
        XCTAssertEqual(decoded.minTarget, 5)
        XCTAssertNil(decoded.maxTarget)
    }

    // MARK: - ObservationConfig Tests

    func test_ObservationConfig_encodesAndDecodes() throws {
        let config = ObservationConfig(reportPrompt: "What did you notice?")

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(ObservationConfig.self, from: data)

        XCTAssertEqual(decoded, config)
        XCTAssertEqual(decoded.reportPrompt, "What did you notice?")
    }

    // MARK: - AbstainConfig Tests

    func test_AbstainConfig_encodesAndDecodes() throws {
        let config = AbstainConfig(durationDescription: "Until noon", endTime: "12:00")

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(AbstainConfig.self, from: data)

        XCTAssertEqual(decoded, config)
        XCTAssertEqual(decoded.durationDescription, "Until noon")
        XCTAssertEqual(decoded.endTime, "12:00")
    }

    func test_AbstainConfig_endTimeCanBeNil() throws {
        let config = AbstainConfig(durationDescription: "All day", endTime: nil)

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(AbstainConfig.self, from: data)

        XCTAssertEqual(decoded, config)
        XCTAssertNil(decoded.endTime)
    }

    // MARK: - SubstituteConfig Tests

    func test_SubstituteConfig_encodesAndDecodes() throws {
        let config = SubstituteConfig(
            triggerBehavior: "Urge to correct someone",
            replacementBehavior: "Ask them a question instead"
        )

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(SubstituteConfig.self, from: data)

        XCTAssertEqual(decoded, config)
        XCTAssertEqual(decoded.triggerBehavior, "Urge to correct someone")
        XCTAssertEqual(decoded.replacementBehavior, "Ask them a question instead")
    }

    // MARK: - PredictConfig Tests

    func test_PredictConfig_encodesAndDecodes() throws {
        let config = PredictConfig(
            predictionPrompt: "What will happen if you say 'I don't know'?",
            observationPrompt: "What actually happened?"
        )

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(PredictConfig.self, from: data)

        XCTAssertEqual(decoded, config)
        XCTAssertEqual(decoded.predictionPrompt, "What will happen if you say 'I don't know'?")
        XCTAssertEqual(decoded.observationPrompt, "What actually happened?")
    }

    // MARK: - AuditConfig Tests

    func test_AuditConfig_encodesAndDecodes() throws {
        let config = AuditConfig(
            auditPrompt: "List moments you performed instead of being genuine",
            categories: [
                .init(id: "work", label: "At work"),
                .init(id: "social", label: "With friends")
            ]
        )

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(AuditConfig.self, from: data)

        XCTAssertEqual(decoded, config)
        XCTAssertEqual(decoded.auditPrompt, "List moments you performed instead of being genuine")
        XCTAssertEqual(decoded.categories.count, 2)
        XCTAssertEqual(decoded.categories[0].id, "work")
        XCTAssertEqual(decoded.categories[1].label, "With friends")
    }

    func test_AuditConfig_AuditCategory_isIdentifiable() {
        let category = AuditConfig.AuditCategory(id: "cat-1", label: "Test")
        XCTAssertEqual(category.id, "cat-1")
    }

    // MARK: - New Outcome Tests

    func test_ObservationOutcome_encodesAndDecodes() throws {
        let outcome = ObservationOutcome(report: "I noticed 5 times I started with 'I'")

        let data = try JSONEncoder().encode(outcome)
        let decoded = try JSONDecoder().decode(ObservationOutcome.self, from: data)

        XCTAssertEqual(decoded, outcome)
    }

    func test_AbstainOutcome_encodesAndDecodes() throws {
        let outcome = AbstainOutcome(completed: true, slipCount: 1)

        let data = try JSONEncoder().encode(outcome)
        let decoded = try JSONDecoder().decode(AbstainOutcome.self, from: data)

        XCTAssertEqual(decoded, outcome)
        XCTAssertTrue(decoded.completed)
        XCTAssertEqual(decoded.slipCount, 1)
    }

    func test_SubstituteOutcome_encodesAndDecodes() throws {
        let outcome = SubstituteOutcome(substituteCount: 3, urgeCount: 5)

        let data = try JSONEncoder().encode(outcome)
        let decoded = try JSONDecoder().decode(SubstituteOutcome.self, from: data)

        XCTAssertEqual(decoded, outcome)
    }

    func test_PredictOutcome_encodesAndDecodes() throws {
        let outcome = PredictOutcome(
            prediction: "They'll think I'm stupid",
            actualResult: "Nobody cared"
        )

        let data = try JSONEncoder().encode(outcome)
        let decoded = try JSONDecoder().decode(PredictOutcome.self, from: data)

        XCTAssertEqual(decoded, outcome)
    }

    func test_AuditOutcome_encodesAndDecodes() throws {
        let outcome = AuditOutcome(items: [
            .init(categoryId: "work", note: "Dropped my title in a meeting"),
            .init(categoryId: "social", note: "Name-dropped at dinner")
        ])

        let data = try JSONEncoder().encode(outcome)
        let decoded = try JSONDecoder().decode(AuditOutcome.self, from: data)

        XCTAssertEqual(decoded, outcome)
        XCTAssertEqual(decoded.items.count, 2)
    }
}
