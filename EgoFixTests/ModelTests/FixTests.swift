import XCTest
@testable import EgoFix

final class FixTests: XCTestCase {

    func test_Fix_belongsToBug() {
        let bugId = UUID()
        let fix = Fix(
            bugId: bugId,
            type: .daily,
            severity: .medium,
            prompt: "Test prompt",
            validation: "Test validation criteria"
        )

        XCTAssertEqual(fix.bugId, bugId)
    }

    func test_Fix_hasValidType() {
        let fix = Fix(
            bugId: UUID(),
            type: .quickFix,
            severity: .high,
            prompt: "Quick fix prompt",
            validation: "Test validation"
        )

        XCTAssertEqual(fix.type, .quickFix)
    }

    func test_Fix_inlineComment_canBeNil() {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .low,
            prompt: "Test prompt",
            validation: "Test validation"
        )

        XCTAssertNil(fix.inlineComment)
    }

    func test_Fix_inlineComment_canBeSet() {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            prompt: "Test prompt",
            validation: "Test validation",
            inlineComment: "This is a comment"
        )

        XCTAssertEqual(fix.inlineComment, "This is a comment")
    }

    func test_Fix_hasValidation() {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            prompt: "Test prompt",
            validation: "Did you complete the task? Mark Applied if yes."
        )

        XCTAssertEqual(fix.validation, "Did you complete the task? Mark Applied if yes.")
    }

    // MARK: - InteractionType Tests

    func test_Fix_defaultInteractionType_isStandard() {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            prompt: "Test prompt",
            validation: "Test validation"
        )

        XCTAssertEqual(fix.interactionType, .standard)
    }

    func test_Fix_interactionType_canBeSet() {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .timed,
            prompt: "Test prompt",
            validation: "Test validation"
        )

        XCTAssertEqual(fix.interactionType, .timed)
    }

    func test_Fix_interactionType_allCasesValid() {
        let types: [InteractionType] = [.standard, .timed, .multiStep, .quiz, .scenario, .counter]

        for interactionType in types {
            let fix = Fix(
                bugId: UUID(),
                type: .daily,
                severity: .medium,
                interactionType: interactionType,
                prompt: "Test",
                validation: "Test"
            )
            XCTAssertEqual(fix.interactionType, interactionType)
        }
    }

    // MARK: - Configuration Data Tests

    func test_Fix_configurationData_isNilByDefault() {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            prompt: "Test",
            validation: "Test"
        )

        XCTAssertNil(fix.configurationData)
    }

    func test_Fix_setConfiguration_encodesTimedConfig() {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .timed,
            prompt: "Test",
            validation: "Test"
        )

        let config = TimedConfig(durationSeconds: 300)
        fix.setConfiguration(config)

        XCTAssertNotNil(fix.configurationData)
        XCTAssertEqual(fix.timedConfig?.durationSeconds, 300)
    }

    func test_Fix_timedConfig_returnsNilForWrongType() {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .standard,
            prompt: "Test",
            validation: "Test"
        )

        let config = TimedConfig(durationSeconds: 300)
        fix.setConfiguration(config)

        // Should return nil because interactionType is .standard, not .timed
        XCTAssertNil(fix.timedConfig)
    }

    func test_Fix_setConfiguration_encodesMultiStepConfig() {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .multiStep,
            prompt: "Test",
            validation: "Test"
        )

        let config = MultiStepConfig(steps: [
            .init(id: "s1", prompt: "Step 1", validation: nil, inlineComment: nil),
            .init(id: "s2", prompt: "Step 2", validation: "Check", inlineComment: "Note")
        ])
        fix.setConfiguration(config)

        XCTAssertNotNil(fix.configurationData)
        XCTAssertEqual(fix.multiStepConfig?.steps.count, 2)
        XCTAssertEqual(fix.multiStepConfig?.steps[0].prompt, "Step 1")
    }

    func test_Fix_setConfiguration_encodesQuizConfig() {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .quiz,
            prompt: "Test",
            validation: "Test"
        )

        let config = QuizConfig(
            question: "What do you feel?",
            options: [
                .init(id: "a", text: "Option A", weightModifier: 1.2, insight: "Insight"),
                .init(id: "b", text: "Option B", weightModifier: 0.8, insight: nil)
            ],
            explanationAfter: "Explanation"
        )
        fix.setConfiguration(config)

        XCTAssertNotNil(fix.configurationData)
        XCTAssertEqual(fix.quizConfig?.question, "What do you feel?")
        XCTAssertEqual(fix.quizConfig?.options.count, 2)
    }

    func test_Fix_setConfiguration_encodesScenarioConfig() {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .scenario,
            prompt: "Test",
            validation: "Test"
        )

        let config = ScenarioConfig(
            situation: "You're at a meeting...",
            options: [
                .init(id: "opt1", text: "Speak up", weightModifier: 1.1, reflection: "Bold"),
                .init(id: "opt2", text: "Stay quiet", weightModifier: 0.9, reflection: nil)
            ],
            debrief: "Think about it"
        )
        fix.setConfiguration(config)

        XCTAssertNotNil(fix.configurationData)
        XCTAssertEqual(fix.scenarioConfig?.situation, "You're at a meeting...")
        XCTAssertEqual(fix.scenarioConfig?.options.count, 2)
    }

    func test_Fix_setConfiguration_encodesCounterConfig() {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .counter,
            prompt: "Test",
            validation: "Test"
        )

        let config = CounterConfig(
            counterPrompt: "Times you corrected someone",
            minTarget: nil,
            maxTarget: 5
        )
        fix.setConfiguration(config)

        XCTAssertNotNil(fix.configurationData)
        XCTAssertEqual(fix.counterConfig?.counterPrompt, "Times you corrected someone")
        XCTAssertEqual(fix.counterConfig?.maxTarget, 5)
        XCTAssertNil(fix.counterConfig?.minTarget)
    }

    func test_Fix_configAccessors_returnNilWhenNoData() {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .timed,
            prompt: "Test",
            validation: "Test"
        )

        // No configuration data set
        XCTAssertNil(fix.timedConfig)
        XCTAssertNil(fix.multiStepConfig)
        XCTAssertNil(fix.quizConfig)
        XCTAssertNil(fix.scenarioConfig)
        XCTAssertNil(fix.counterConfig)
    }

    func test_Fix_configAccessors_returnNilForMismatchedType() {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .quiz,
            prompt: "Test",
            validation: "Test"
        )

        // Set quiz config but check other accessors
        let config = QuizConfig(
            question: "Test?",
            options: [.init(id: "a", text: "A", weightModifier: 1.0, insight: nil)],
            explanationAfter: nil
        )
        fix.setConfiguration(config)

        XCTAssertNotNil(fix.quizConfig)
        XCTAssertNil(fix.timedConfig)
        XCTAssertNil(fix.multiStepConfig)
        XCTAssertNil(fix.scenarioConfig)
        XCTAssertNil(fix.counterConfig)
    }
}
