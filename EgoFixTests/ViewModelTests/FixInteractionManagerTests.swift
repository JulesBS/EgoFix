import XCTest
@testable import EgoFix

@MainActor
final class FixInteractionManagerTests: XCTestCase {

    // MARK: - Test Fixtures

    private func makeManager() -> FixInteractionManager {
        // Create a minimal TimerService with mock repository
        let timerSessionRepository = MockTimerSessionRepository()
        let timerService = TimerService(timerSessionRepository: timerSessionRepository)
        return FixInteractionManager(timerService: timerService)
    }

    private func makeStandardFix() -> Fix {
        Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .standard,
            prompt: "Test standard fix",
            validation: "Did you do it?"
        )
    }

    private func makeMultiStepFix() -> Fix {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .multiStep,
            prompt: "Multi-step fix",
            validation: "Complete all steps"
        )
        let config = MultiStepConfig(steps: [
            .init(id: "step-1", prompt: "First step", validation: nil, inlineComment: nil),
            .init(id: "step-2", prompt: "Second step", validation: "Check", inlineComment: nil),
            .init(id: "step-3", prompt: "Third step", validation: nil, inlineComment: "Final")
        ])
        fix.setConfiguration(config)
        return fix
    }

    private func makeQuizFix() -> Fix {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .quiz,
            prompt: "Quiz fix",
            validation: "Select an answer"
        )
        let config = QuizConfig(
            question: "What is your reaction?",
            options: [
                .init(id: "opt-a", text: "Option A", weightModifier: 1.2, insight: "Insight for A"),
                .init(id: "opt-b", text: "Option B", weightModifier: 0.8, insight: "Insight for B"),
                .init(id: "opt-c", text: "Option C", weightModifier: 1.0, insight: nil)
            ],
            explanationAfter: "Here's why this matters"
        )
        fix.setConfiguration(config)
        return fix
    }

    private func makeScenarioFix() -> Fix {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .scenario,
            prompt: "Scenario fix",
            validation: "Choose your response"
        )
        let config = ScenarioConfig(
            situation: "You're in a meeting and someone says something wrong.",
            options: [
                .init(id: "resp-1", text: "Correct them", weightModifier: 1.3, reflection: "Bold choice"),
                .init(id: "resp-2", text: "Stay silent", weightModifier: 0.7, reflection: "Patient approach")
            ],
            debrief: "Consider the consequences"
        )
        fix.setConfiguration(config)
        return fix
    }

    private func makeCounterFix() -> Fix {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .counter,
            prompt: "Counter fix",
            validation: "Track your count"
        )
        let config = CounterConfig(
            counterPrompt: "Times you wanted to correct someone",
            minTarget: nil,
            maxTarget: nil
        )
        fix.setConfiguration(config)
        return fix
    }

    // MARK: - Initial State Tests

    func test_initialState_isStandard() async {
        let manager = makeManager()

        // Give manager time to initialize
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms

        XCTAssertEqual(manager.interactionType, .standard)
        XCTAssertNil(manager.currentFix)
        XCTAssertNil(manager.currentFixCompletionId)
    }

    func test_initialState_canMarkApplied() async {
        let manager = makeManager()

        // Give manager time to initialize
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms

        // Standard type always allows marking applied
        XCTAssertTrue(manager.canMarkApplied)
    }

    // MARK: - Reset Tests

    func test_reset_clearsAllState() async {
        let manager = makeManager()
        let fix = makeMultiStepFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        // Verify state was set
        XCTAssertEqual(manager.interactionType, .multiStep)
        XCTAssertNotNil(manager.multiStepConfig)

        // Reset
        manager.reset()

        // Verify reset
        XCTAssertEqual(manager.interactionType, .standard)
        XCTAssertNil(manager.currentFix)
        XCTAssertNil(manager.multiStepConfig)
        XCTAssertEqual(manager.currentStepIndex, 0)
        XCTAssertTrue(manager.completedSteps.isEmpty)
    }

    // MARK: - Standard Interaction Tests

    func test_standardInteraction_canAlwaysMarkApplied() async {
        let manager = makeManager()
        let fix = makeStandardFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        XCTAssertEqual(manager.interactionType, .standard)
        XCTAssertTrue(manager.canMarkApplied)
    }

    func test_standardInteraction_generatesNoOutcomeData() async {
        let manager = makeManager()
        let fix = makeStandardFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        let outcomeData = manager.generateOutcomeData()
        XCTAssertNil(outcomeData)
    }

    // MARK: - Multi-Step Interaction Tests

    func test_multiStepSetup_loadsConfig() async {
        let manager = makeManager()
        let fix = makeMultiStepFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        XCTAssertEqual(manager.interactionType, .multiStep)
        XCTAssertNotNil(manager.multiStepConfig)
        XCTAssertEqual(manager.totalSteps, 3)
        XCTAssertEqual(manager.currentStepIndex, 0)
        XCTAssertTrue(manager.completedSteps.isEmpty)
    }

    func test_multiStep_initiallyCannotMarkApplied() async {
        let manager = makeManager()
        let fix = makeMultiStepFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        // Cannot mark applied until all steps processed with at least one completed
        XCTAssertFalse(manager.canMarkApplied)
    }

    func test_multiStep_currentStepReturnsCorrectStep() async {
        let manager = makeManager()
        let fix = makeMultiStepFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        XCTAssertEqual(manager.currentStep?.id, "step-1")
        XCTAssertEqual(manager.currentStep?.prompt, "First step")
    }

    func test_multiStep_completeCurrentStep_advancesToNext() async {
        let manager = makeManager()
        let fix = makeMultiStepFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        manager.completeCurrentStep()

        XCTAssertEqual(manager.currentStepIndex, 1)
        XCTAssertEqual(manager.completedSteps.count, 1)
        XCTAssertFalse(manager.completedSteps[0].skipped)
        XCTAssertEqual(manager.completedSteps[0].stepId, "step-1")
    }

    func test_multiStep_skipCurrentStep_advancesToNext() async {
        let manager = makeManager()
        let fix = makeMultiStepFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        manager.skipCurrentStep()

        XCTAssertEqual(manager.currentStepIndex, 1)
        XCTAssertEqual(manager.completedSteps.count, 1)
        XCTAssertTrue(manager.completedSteps[0].skipped)
    }

    func test_multiStep_allStepsProcessed_whenAllCompleted() async {
        let manager = makeManager()
        let fix = makeMultiStepFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        manager.completeCurrentStep() // Step 1
        manager.completeCurrentStep() // Step 2
        manager.completeCurrentStep() // Step 3

        XCTAssertTrue(manager.allStepsProcessed)
        XCTAssertEqual(manager.completedStepsCount, 3)
        XCTAssertEqual(manager.skippedStepsCount, 0)
    }

    func test_multiStep_canMarkApplied_afterAllStepsWithOneCompleted() async {
        let manager = makeManager()
        let fix = makeMultiStepFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        manager.skipCurrentStep()     // Step 1 skipped
        manager.completeCurrentStep() // Step 2 completed
        manager.skipCurrentStep()     // Step 3 skipped

        XCTAssertTrue(manager.allStepsProcessed)
        XCTAssertTrue(manager.hasCompletedAtLeastOneStep)
        XCTAssertTrue(manager.canMarkApplied)
    }

    func test_multiStep_cannotMarkApplied_ifAllSkipped() async {
        let manager = makeManager()
        let fix = makeMultiStepFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        manager.skipCurrentStep() // Step 1
        manager.skipCurrentStep() // Step 2
        manager.skipCurrentStep() // Step 3

        XCTAssertTrue(manager.allStepsProcessed)
        XCTAssertFalse(manager.hasCompletedAtLeastOneStep)
        XCTAssertFalse(manager.canMarkApplied)
    }

    func test_multiStep_generatesOutcomeData() async {
        let manager = makeManager()
        let fix = makeMultiStepFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        manager.completeCurrentStep()
        manager.skipCurrentStep()
        manager.completeCurrentStep()

        let data = manager.generateOutcomeData()
        XCTAssertNotNil(data)

        let outcome = try? JSONDecoder().decode(MultiStepOutcome.self, from: data!)
        XCTAssertNotNil(outcome)
        XCTAssertEqual(outcome?.stepsCompleted.count, 3)
        XCTAssertEqual(outcome?.completedCount, 2)
        XCTAssertEqual(outcome?.skippedCount, 1)
    }

    // MARK: - Quiz Interaction Tests

    func test_quizSetup_loadsConfig() async {
        let manager = makeManager()
        let fix = makeQuizFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        XCTAssertEqual(manager.interactionType, .quiz)
        XCTAssertNotNil(manager.quizConfig)
        XCTAssertEqual(manager.quizConfig?.options.count, 3)
        XCTAssertFalse(manager.quizAnswered)
        XCTAssertNil(manager.selectedOptionId)
    }

    func test_quiz_initiallyCannotMarkApplied() async {
        let manager = makeManager()
        let fix = makeQuizFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        XCTAssertFalse(manager.canMarkApplied)
    }

    func test_quiz_selectOption_setsState() async {
        let manager = makeManager()
        let fix = makeQuizFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        let optionA = manager.quizConfig!.options[0]
        manager.selectQuizOption(optionA)

        XCTAssertTrue(manager.quizAnswered)
        XCTAssertEqual(manager.selectedOptionId, "opt-a")
        XCTAssertEqual(manager.selectedQuizInsight, "Insight for A")
    }

    func test_quiz_canMarkApplied_afterSelection() async {
        let manager = makeManager()
        let fix = makeQuizFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        let optionB = manager.quizConfig!.options[1]
        manager.selectQuizOption(optionB)

        XCTAssertTrue(manager.canMarkApplied)
    }

    func test_quiz_cannotChangeSelection() async {
        let manager = makeManager()
        let fix = makeQuizFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        let optionA = manager.quizConfig!.options[0]
        let optionB = manager.quizConfig!.options[1]

        manager.selectQuizOption(optionA)
        manager.selectQuizOption(optionB) // Should be ignored

        XCTAssertEqual(manager.selectedOptionId, "opt-a")
    }

    func test_quiz_selectedQuizOption_returnsCorrectOption() async {
        let manager = makeManager()
        let fix = makeQuizFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        let optionB = manager.quizConfig!.options[1]
        manager.selectQuizOption(optionB)

        XCTAssertEqual(manager.selectedQuizOption?.id, "opt-b")
        XCTAssertEqual(manager.selectedQuizOption?.weightModifier, 0.8)
    }

    func test_quiz_generatesOutcomeData() async {
        let manager = makeManager()
        let fix = makeQuizFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        let optionA = manager.quizConfig!.options[0]
        manager.selectQuizOption(optionA)

        let data = manager.generateOutcomeData()
        XCTAssertNotNil(data)

        let outcome = try? JSONDecoder().decode(QuizOutcome.self, from: data!)
        XCTAssertNotNil(outcome)
        XCTAssertEqual(outcome?.selectedOptionId, "opt-a")
        XCTAssertEqual(outcome?.weightModifierApplied, 1.2)
    }

    // MARK: - Scenario Interaction Tests

    func test_scenarioSetup_loadsConfig() async {
        let manager = makeManager()
        let fix = makeScenarioFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        XCTAssertEqual(manager.interactionType, .scenario)
        XCTAssertNotNil(manager.scenarioConfig)
        XCTAssertEqual(manager.scenarioConfig?.options.count, 2)
        XCTAssertFalse(manager.scenarioAnswered)
    }

    func test_scenario_initiallyCannotMarkApplied() async {
        let manager = makeManager()
        let fix = makeScenarioFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        XCTAssertFalse(manager.canMarkApplied)
    }

    func test_scenario_selectOption_setsState() async {
        let manager = makeManager()
        let fix = makeScenarioFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        let option = manager.scenarioConfig!.options[1]
        manager.selectScenarioOption(option)

        XCTAssertTrue(manager.scenarioAnswered)
        XCTAssertEqual(manager.selectedScenarioOptionId, "resp-2")
        XCTAssertEqual(manager.scenarioReflection, "Patient approach")
    }

    func test_scenario_canMarkApplied_afterSelection() async {
        let manager = makeManager()
        let fix = makeScenarioFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        let option = manager.scenarioConfig!.options[0]
        manager.selectScenarioOption(option)

        XCTAssertTrue(manager.canMarkApplied)
    }

    func test_scenario_cannotChangeSelection() async {
        let manager = makeManager()
        let fix = makeScenarioFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        let option1 = manager.scenarioConfig!.options[0]
        let option2 = manager.scenarioConfig!.options[1]

        manager.selectScenarioOption(option1)
        manager.selectScenarioOption(option2) // Should be ignored

        XCTAssertEqual(manager.selectedScenarioOptionId, "resp-1")
    }

    func test_scenario_generatesOutcomeData() async {
        let manager = makeManager()
        let fix = makeScenarioFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        let option = manager.scenarioConfig!.options[0]
        manager.selectScenarioOption(option)

        let data = manager.generateOutcomeData()
        XCTAssertNotNil(data)

        let outcome = try? JSONDecoder().decode(ScenarioOutcome.self, from: data!)
        XCTAssertNotNil(outcome)
        XCTAssertEqual(outcome?.selectedOptionId, "resp-1")
        XCTAssertEqual(outcome?.weightModifierApplied, 1.3)
    }

    // MARK: - Counter Interaction Tests

    func test_counterSetup_loadsConfig() async {
        let manager = makeManager()
        let fix = makeCounterFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        XCTAssertEqual(manager.interactionType, .counter)
        XCTAssertNotNil(manager.counterConfig)
        XCTAssertEqual(manager.counterValue, 0)
        XCTAssertTrue(manager.counterHistory.isEmpty)
    }

    func test_counter_canAlwaysMarkApplied() async {
        let manager = makeManager()
        let fix = makeCounterFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        // Counter allows marking applied at any count
        XCTAssertTrue(manager.canMarkApplied)
    }

    func test_counter_increment_increasesValue() async {
        let manager = makeManager()
        let fix = makeCounterFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        manager.incrementCounter()
        XCTAssertEqual(manager.counterValue, 1)

        manager.incrementCounter()
        XCTAssertEqual(manager.counterValue, 2)

        manager.incrementCounter()
        XCTAssertEqual(manager.counterValue, 3)
    }

    func test_counter_increment_addsToHistory() async {
        let manager = makeManager()
        let fix = makeCounterFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        manager.incrementCounter()
        manager.incrementCounter()

        XCTAssertEqual(manager.counterHistory.count, 2)
        XCTAssertEqual(manager.counterHistory[0].delta, 1)
        XCTAssertEqual(manager.counterHistory[1].delta, 1)
    }

    func test_counter_decrement_decreasesValue() async {
        let manager = makeManager()
        let fix = makeCounterFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        manager.incrementCounter()
        manager.incrementCounter()
        manager.incrementCounter()
        manager.decrementCounter()

        XCTAssertEqual(manager.counterValue, 2)
    }

    func test_counter_decrement_cannotGoBelowZero() async {
        let manager = makeManager()
        let fix = makeCounterFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        manager.decrementCounter()
        manager.decrementCounter()

        XCTAssertEqual(manager.counterValue, 0)
    }

    func test_counter_decrement_addsNegativeDeltaToHistory() async {
        let manager = makeManager()
        let fix = makeCounterFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        manager.incrementCounter()
        manager.decrementCounter()

        XCTAssertEqual(manager.counterHistory.count, 2)
        XCTAssertEqual(manager.counterHistory[1].delta, -1)
    }

    func test_counter_generatesOutcomeData() async {
        let manager = makeManager()
        let fix = makeCounterFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        manager.incrementCounter()
        manager.incrementCounter()
        manager.incrementCounter()
        manager.decrementCounter()

        let data = manager.generateOutcomeData()
        XCTAssertNotNil(data)

        let outcome = try? JSONDecoder().decode(CounterOutcome.self, from: data!)
        XCTAssertNotNil(outcome)
        XCTAssertEqual(outcome?.finalCount, 2)
        XCTAssertEqual(outcome?.countHistory.count, 4)
    }

    func test_counter_meetsTarget_withNoTargets() async {
        let manager = makeManager()
        let fix = makeCounterFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        // No min/max targets, so always meets target
        XCTAssertTrue(manager.counterMeetsTarget)

        manager.incrementCounter()
        XCTAssertTrue(manager.counterMeetsTarget)
    }

    func test_counter_meetsTarget_withMinTarget() async {
        let manager = makeManager()
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .counter,
            prompt: "Counter",
            validation: "Track"
        )
        fix.setConfiguration(CounterConfig(counterPrompt: "Count", minTarget: 3, maxTarget: nil))

        await manager.setup(for: fix, fixCompletionId: UUID())

        XCTAssertFalse(manager.counterMeetsTarget) // 0 < 3

        manager.incrementCounter()
        manager.incrementCounter()
        XCTAssertFalse(manager.counterMeetsTarget) // 2 < 3

        manager.incrementCounter()
        XCTAssertTrue(manager.counterMeetsTarget) // 3 >= 3
    }

    func test_counter_meetsTarget_withMaxTarget() async {
        let manager = makeManager()
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .counter,
            prompt: "Counter",
            validation: "Track"
        )
        fix.setConfiguration(CounterConfig(counterPrompt: "Count", minTarget: nil, maxTarget: 2))

        await manager.setup(for: fix, fixCompletionId: UUID())

        XCTAssertTrue(manager.counterMeetsTarget) // 0 <= 2

        manager.incrementCounter()
        manager.incrementCounter()
        XCTAssertTrue(manager.counterMeetsTarget) // 2 <= 2

        manager.incrementCounter()
        XCTAssertFalse(manager.counterMeetsTarget) // 3 > 2
    }

    // MARK: - Observation Interaction Tests

    private func makeObservationFix() -> Fix {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .observation,
            prompt: "Notice when you drop someone's name to gain credibility",
            validation: "Report what you observed"
        )
        fix.setConfiguration(ObservationConfig(reportPrompt: "What did you notice?"))
        return fix
    }

    func test_observationSetup_resetsReport() async {
        let manager = makeManager()
        let fix = makeObservationFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        XCTAssertEqual(manager.interactionType, .observation)
        XCTAssertEqual(manager.observationReport, "")
    }

    func test_observation_cannotMarkApplied_whenEmpty() async {
        let manager = makeManager()
        let fix = makeObservationFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        XCTAssertFalse(manager.canMarkApplied)
    }

    func test_observation_cannotMarkApplied_whenWhitespaceOnly() async {
        let manager = makeManager()
        let fix = makeObservationFix()

        await manager.setup(for: fix, fixCompletionId: UUID())
        manager.observationReport = "   \n  "

        XCTAssertFalse(manager.canMarkApplied)
    }

    func test_observation_canMarkApplied_whenReportFilled() async {
        let manager = makeManager()
        let fix = makeObservationFix()

        await manager.setup(for: fix, fixCompletionId: UUID())
        manager.observationReport = "I noticed I dropped a name twice in one meeting"

        XCTAssertTrue(manager.canMarkApplied)
    }

    func test_observation_generatesOutcomeData() async {
        let manager = makeManager()
        let fix = makeObservationFix()

        await manager.setup(for: fix, fixCompletionId: UUID())
        manager.observationReport = "Noticed it three times"

        let data = manager.generateOutcomeData()
        XCTAssertNotNil(data)

        let outcome = try? JSONDecoder().decode(ObservationOutcome.self, from: data!)
        XCTAssertNotNil(outcome)
        XCTAssertEqual(outcome?.report, "Noticed it three times")
    }

    // MARK: - Abstain Interaction Tests

    func test_abstainSetup_resetsState() async {
        let manager = makeManager()
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .abstain,
            prompt: "Go one meeting without offering unsolicited advice",
            validation: "Did you abstain?"
        )
        fix.setConfiguration(AbstainConfig(durationDescription: "One meeting", endTime: nil))

        await manager.setup(for: fix, fixCompletionId: UUID())

        XCTAssertEqual(manager.interactionType, .abstain)
        XCTAssertFalse(manager.abstainCompleted)
    }

    func test_abstain_cannotMarkApplied_initially() async {
        let manager = makeManager()
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .abstain,
            prompt: "Abstain fix",
            validation: "Did you abstain?"
        )
        fix.setConfiguration(AbstainConfig(durationDescription: "One hour", endTime: nil))

        await manager.setup(for: fix, fixCompletionId: UUID())

        XCTAssertFalse(manager.canMarkApplied)
    }

    func test_abstain_canMarkApplied_whenCompleted() async {
        let manager = makeManager()
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .abstain,
            prompt: "Abstain fix",
            validation: "Did you abstain?"
        )
        fix.setConfiguration(AbstainConfig(durationDescription: "One hour", endTime: nil))

        await manager.setup(for: fix, fixCompletionId: UUID())
        manager.abstainCompleted = true

        XCTAssertTrue(manager.canMarkApplied)
    }

    func test_abstain_generatesOutcomeData_completed() async {
        let manager = makeManager()
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .abstain,
            prompt: "Abstain",
            validation: "Done?"
        )
        fix.setConfiguration(AbstainConfig(durationDescription: "One hour", endTime: nil))

        await manager.setup(for: fix, fixCompletionId: UUID())
        manager.abstainCompleted = true

        let data = manager.generateOutcomeData()
        XCTAssertNotNil(data)

        let outcome = try? JSONDecoder().decode(AbstainOutcome.self, from: data!)
        XCTAssertEqual(outcome?.completed, true)
        XCTAssertEqual(outcome?.slipCount, 0)
    }

    func test_abstain_generatesOutcomeData_notCompleted() async {
        let manager = makeManager()
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .abstain,
            prompt: "Abstain",
            validation: "Done?"
        )
        fix.setConfiguration(AbstainConfig(durationDescription: "One hour", endTime: nil))

        await manager.setup(for: fix, fixCompletionId: UUID())
        manager.abstainCompleted = false

        // Force canMarkApplied by setting completed, then unset to test outcome
        // Actually, let's test the outcome directly
        let data = manager.generateOutcomeData()
        XCTAssertNotNil(data)

        let outcome = try? JSONDecoder().decode(AbstainOutcome.self, from: data!)
        XCTAssertEqual(outcome?.completed, false)
        XCTAssertEqual(outcome?.slipCount, 1)
    }

    // MARK: - Substitute Interaction Tests

    func test_substituteSetup_resetsState() async {
        let manager = makeManager()
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .substitute,
            prompt: "When you feel the urge to one-up, ask a follow-up question instead",
            validation: "Track your substitutions"
        )
        fix.setConfiguration(SubstituteConfig(triggerBehavior: "One-upping", replacementBehavior: "Ask a question"))

        await manager.setup(for: fix, fixCompletionId: UUID())

        XCTAssertEqual(manager.interactionType, .substitute)
        XCTAssertEqual(manager.substituteCount, 0)
        XCTAssertEqual(manager.urgeCount, 0)
    }

    func test_substitute_cannotMarkApplied_withNoUrges() async {
        let manager = makeManager()
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .substitute,
            prompt: "Substitute fix",
            validation: "Track"
        )
        fix.setConfiguration(SubstituteConfig(triggerBehavior: "X", replacementBehavior: "Y"))

        await manager.setup(for: fix, fixCompletionId: UUID())

        XCTAssertFalse(manager.canMarkApplied)
    }

    func test_substitute_canMarkApplied_withUrges() async {
        let manager = makeManager()
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .substitute,
            prompt: "Substitute fix",
            validation: "Track"
        )
        fix.setConfiguration(SubstituteConfig(triggerBehavior: "X", replacementBehavior: "Y"))

        await manager.setup(for: fix, fixCompletionId: UUID())
        manager.urgeCount = 3
        manager.substituteCount = 2

        XCTAssertTrue(manager.canMarkApplied)
    }

    func test_substitute_generatesOutcomeData() async {
        let manager = makeManager()
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .substitute,
            prompt: "Substitute",
            validation: "Track"
        )
        fix.setConfiguration(SubstituteConfig(triggerBehavior: "X", replacementBehavior: "Y"))

        await manager.setup(for: fix, fixCompletionId: UUID())
        manager.urgeCount = 5
        manager.substituteCount = 3

        let data = manager.generateOutcomeData()
        XCTAssertNotNil(data)

        let outcome = try? JSONDecoder().decode(SubstituteOutcome.self, from: data!)
        XCTAssertEqual(outcome?.substituteCount, 3)
        XCTAssertEqual(outcome?.urgeCount, 5)
    }

    // MARK: - Journal Interaction Tests

    func test_journalSetup_resetsText() async {
        let manager = makeManager()
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .journal,
            prompt: "Write about a time you changed your opinion to match the room",
            validation: "Write 2-3 sentences"
        )

        await manager.setup(for: fix, fixCompletionId: UUID())

        XCTAssertEqual(manager.interactionType, .journal)
        XCTAssertEqual(manager.journalText, "")
    }

    func test_journal_cannotMarkApplied_whenEmpty() async {
        let manager = makeManager()
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .journal,
            prompt: "Journal fix",
            validation: "Write"
        )

        await manager.setup(for: fix, fixCompletionId: UUID())

        XCTAssertFalse(manager.canMarkApplied)
    }

    func test_journal_canMarkApplied_whenTextEntered() async {
        let manager = makeManager()
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .journal,
            prompt: "Journal fix",
            validation: "Write"
        )

        await manager.setup(for: fix, fixCompletionId: UUID())
        manager.journalText = "I noticed myself doing this at lunch."

        XCTAssertTrue(manager.canMarkApplied)
    }

    func test_journal_generatesNoOutcomeData() async {
        let manager = makeManager()
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .journal,
            prompt: "Journal fix",
            validation: "Write"
        )

        await manager.setup(for: fix, fixCompletionId: UUID())
        manager.journalText = "Some journal entry"

        // Journal uses reflection field, no outcome data
        let data = manager.generateOutcomeData()
        XCTAssertNil(data)
    }

    // MARK: - Reversal Interaction Tests

    func test_reversalSetup_setsType() async {
        let manager = makeManager()
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .reversal,
            prompt: "Today, let someone else have the last word",
            validation: "Did you do the opposite?"
        )

        await manager.setup(for: fix, fixCompletionId: UUID())

        XCTAssertEqual(manager.interactionType, .reversal)
    }

    func test_reversal_canAlwaysMarkApplied() async {
        let manager = makeManager()
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .reversal,
            prompt: "Reversal fix",
            validation: "Did it?"
        )

        await manager.setup(for: fix, fixCompletionId: UUID())

        XCTAssertTrue(manager.canMarkApplied)
    }

    func test_reversal_generatesNoOutcomeData() async {
        let manager = makeManager()
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .reversal,
            prompt: "Reversal fix",
            validation: "Did it?"
        )

        await manager.setup(for: fix, fixCompletionId: UUID())

        let data = manager.generateOutcomeData()
        XCTAssertNil(data)
    }

    // MARK: - Predict Interaction Tests

    private func makePredictFix() -> Fix {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .predict,
            prompt: "Before your next meeting, predict how many times you'll steer the conversation to your expertise",
            validation: "Predict then observe"
        )
        fix.setConfiguration(PredictConfig(
            predictionPrompt: "What do you predict will happen?",
            observationPrompt: "What actually happened?"
        ))
        return fix
    }

    func test_predictSetup_resetsState() async {
        let manager = makeManager()
        let fix = makePredictFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        XCTAssertEqual(manager.interactionType, .predict)
        XCTAssertEqual(manager.predictPhase, .predicting)
        XCTAssertEqual(manager.predictionText, "")
        XCTAssertEqual(manager.observationText, "")
    }

    func test_predict_cannotMarkApplied_inPredictingPhase() async {
        let manager = makeManager()
        let fix = makePredictFix()

        await manager.setup(for: fix, fixCompletionId: UUID())
        manager.predictionText = "I think I'll do it 3 times"

        XCTAssertFalse(manager.canMarkApplied)
    }

    func test_predict_cannotMarkApplied_inObservingPhaseWithoutText() async {
        let manager = makeManager()
        let fix = makePredictFix()

        await manager.setup(for: fix, fixCompletionId: UUID())
        manager.predictionText = "Prediction"
        manager.predictPhase = .observing

        XCTAssertFalse(manager.canMarkApplied)
    }

    func test_predict_canMarkApplied_inObservingPhaseWithText() async {
        let manager = makeManager()
        let fix = makePredictFix()

        await manager.setup(for: fix, fixCompletionId: UUID())
        manager.predictionText = "I think 3 times"
        manager.predictPhase = .observing
        manager.observationText = "Actually happened 5 times"

        XCTAssertTrue(manager.canMarkApplied)
    }

    func test_predict_generatesOutcomeData() async {
        let manager = makeManager()
        let fix = makePredictFix()

        await manager.setup(for: fix, fixCompletionId: UUID())
        manager.predictionText = "3 times"
        manager.predictPhase = .observing
        manager.observationText = "5 times"

        let data = manager.generateOutcomeData()
        XCTAssertNotNil(data)

        let outcome = try? JSONDecoder().decode(PredictOutcome.self, from: data!)
        XCTAssertEqual(outcome?.prediction, "3 times")
        XCTAssertEqual(outcome?.actualResult, "5 times")
    }

    // MARK: - Body Interaction Tests

    func test_bodySetup_setsType() async {
        let manager = makeManager()
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .body,
            prompt: "Notice where in your body you feel tension when someone disagrees with you",
            validation: "Did you notice?"
        )

        await manager.setup(for: fix, fixCompletionId: UUID())

        XCTAssertEqual(manager.interactionType, .body)
    }

    func test_body_canAlwaysMarkApplied() async {
        let manager = makeManager()
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .body,
            prompt: "Body fix",
            validation: "Notice"
        )

        await manager.setup(for: fix, fixCompletionId: UUID())

        XCTAssertTrue(manager.canMarkApplied)
    }

    func test_body_generatesNoOutcomeData() async {
        let manager = makeManager()
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .body,
            prompt: "Body fix",
            validation: "Notice"
        )

        await manager.setup(for: fix, fixCompletionId: UUID())

        let data = manager.generateOutcomeData()
        XCTAssertNil(data)
    }

    // MARK: - Audit Interaction Tests

    private func makeAuditFix() -> Fix {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .high,
            interactionType: .audit,
            prompt: "End-of-day review: How did your need to be right show up today?",
            validation: "Fill in at least one category"
        )
        fix.setConfiguration(AuditConfig(
            auditPrompt: "Review your day",
            categories: [
                .init(id: "meetings", label: "In meetings"),
                .init(id: "messages", label: "In messages"),
                .init(id: "thoughts", label: "In private thoughts")
            ]
        ))
        return fix
    }

    func test_auditSetup_resetsItems() async {
        let manager = makeManager()
        let fix = makeAuditFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        XCTAssertEqual(manager.interactionType, .audit)
        XCTAssertTrue(manager.auditItems.isEmpty)
    }

    func test_audit_cannotMarkApplied_whenEmpty() async {
        let manager = makeManager()
        let fix = makeAuditFix()

        await manager.setup(for: fix, fixCompletionId: UUID())

        XCTAssertFalse(manager.canMarkApplied)
    }

    func test_audit_cannotMarkApplied_whenAllWhitespace() async {
        let manager = makeManager()
        let fix = makeAuditFix()

        await manager.setup(for: fix, fixCompletionId: UUID())
        manager.auditItems["meetings"] = "   "
        manager.auditItems["messages"] = ""

        XCTAssertFalse(manager.canMarkApplied)
    }

    func test_audit_canMarkApplied_withOneFilledCategory() async {
        let manager = makeManager()
        let fix = makeAuditFix()

        await manager.setup(for: fix, fixCompletionId: UUID())
        manager.auditItems["meetings"] = "Corrected two people"

        XCTAssertTrue(manager.canMarkApplied)
    }

    func test_audit_generatesOutcomeData() async {
        let manager = makeManager()
        let fix = makeAuditFix()

        await manager.setup(for: fix, fixCompletionId: UUID())
        manager.auditItems["meetings"] = "Corrected two people"
        manager.auditItems["thoughts"] = "Rehearsed arguments"

        let data = manager.generateOutcomeData()
        XCTAssertNotNil(data)

        let outcome = try? JSONDecoder().decode(AuditOutcome.self, from: data!)
        XCTAssertNotNil(outcome)
        XCTAssertEqual(outcome?.items.count, 2)
    }

    // MARK: - Reset Tests (New Types)

    func test_reset_clearsNewTypeState() async {
        let manager = makeManager()
        let fix = makePredictFix()

        await manager.setup(for: fix, fixCompletionId: UUID())
        manager.predictionText = "My prediction"
        manager.predictPhase = .observing
        manager.observationText = "What happened"

        manager.reset()

        XCTAssertEqual(manager.predictPhase, .predicting)
        XCTAssertEqual(manager.predictionText, "")
        XCTAssertEqual(manager.observationText, "")
        XCTAssertEqual(manager.observationReport, "")
        XCTAssertFalse(manager.abstainCompleted)
        XCTAssertEqual(manager.substituteCount, 0)
        XCTAssertEqual(manager.urgeCount, 0)
        XCTAssertEqual(manager.journalText, "")
        XCTAssertTrue(manager.auditItems.isEmpty)
    }

    // MARK: - Timer Display Tests

    func test_formattedTime_formatsCorrectly() async {
        let manager = makeManager()

        // Give manager time to initialize
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms

        // Test via reflection by directly setting remainingSeconds
        // Since it's private(set), we test indirectly through setup
        // For now, just verify initial state
        XCTAssertEqual(manager.formattedTime, "00:00")
    }

    func test_progressBarString_formatsCorrectly() async {
        let manager = makeManager()

        // Give manager time to initialize
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms

        // Initial state - 0 progress
        XCTAssertEqual(manager.progress, 0)
        // The bar should be all empty blocks
        XCTAssertTrue(manager.progressBarString.contains("["))
        XCTAssertTrue(manager.progressBarString.contains("]"))
    }
}

// MARK: - Mock Timer Session Repository

@MainActor
private class MockTimerSessionRepository: TimerSessionRepository {
    private var sessions: [UUID: TimerSession] = [:]

    func getAll() async throws -> [TimerSession] {
        Array(sessions.values)
    }

    func save(_ session: TimerSession) async throws {
        sessions[session.id] = session
    }

    func getById(_ id: UUID) async throws -> TimerSession? {
        sessions[id]
    }

    func getForFixCompletion(_ fixCompletionId: UUID) async throws -> TimerSession? {
        sessions.values.first { $0.fixCompletionId == fixCompletionId }
    }

    func getActive() async throws -> TimerSession? {
        sessions.values.first { $0.status == .running || $0.status == .paused }
    }

    func delete(_ id: UUID) async throws {
        sessions.removeValue(forKey: id)
    }
}
