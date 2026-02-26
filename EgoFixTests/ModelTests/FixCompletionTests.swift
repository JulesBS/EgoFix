import XCTest
@testable import EgoFix

final class FixCompletionTests: XCTestCase {

    func test_FixCompletion_outcomeTransitions_pendingToApplied() {
        let completion = FixCompletion(
            fixId: UUID(),
            userId: UUID()
        )

        XCTAssertEqual(completion.outcome, .pending)

        completion.outcome = .applied
        completion.completedAt = Date()

        XCTAssertEqual(completion.outcome, .applied)
        XCTAssertNotNil(completion.completedAt)
    }

    func test_FixCompletion_outcomeTransitions_pendingToSkipped() {
        let completion = FixCompletion(
            fixId: UUID(),
            userId: UUID()
        )

        completion.outcome = .skipped
        completion.completedAt = Date()

        XCTAssertEqual(completion.outcome, .skipped)
    }

    func test_FixCompletion_outcomeTransitions_pendingToFailed() {
        let completion = FixCompletion(
            fixId: UUID(),
            userId: UUID()
        )

        completion.outcome = .failed
        completion.completedAt = Date()

        XCTAssertEqual(completion.outcome, .failed)
    }

    func test_FixCompletion_defaultOutcome_isPending() {
        let completion = FixCompletion(
            fixId: UUID(),
            userId: UUID()
        )

        XCTAssertEqual(completion.outcome, .pending)
        XCTAssertNil(completion.completedAt)
    }

    func test_FixCompletion_reflection_isOptional() {
        let completion = FixCompletion(
            fixId: UUID(),
            userId: UUID()
        )

        XCTAssertNil(completion.reflection)

        completion.reflection = "I struggled with this one"

        XCTAssertEqual(completion.reflection, "I struggled with this one")
    }

    // MARK: - Outcome Data Tests

    func test_FixCompletion_outcomeData_isNilByDefault() {
        let completion = FixCompletion(
            fixId: UUID(),
            userId: UUID()
        )

        XCTAssertNil(completion.outcomeData)
    }

    func test_FixCompletion_setOutcomeData_encodesTimedOutcome() {
        let completion = FixCompletion(
            fixId: UUID(),
            userId: UUID()
        )

        let outcome = TimedOutcome(timerCompleted: true, actualDurationSeconds: 300)
        completion.setOutcomeData(outcome)

        XCTAssertNotNil(completion.outcomeData)
        XCTAssertEqual(completion.timedOutcome?.timerCompleted, true)
        XCTAssertEqual(completion.timedOutcome?.actualDurationSeconds, 300)
    }

    func test_FixCompletion_setOutcomeData_encodesMultiStepOutcome() {
        let completion = FixCompletion(
            fixId: UUID(),
            userId: UUID()
        )

        let outcome = MultiStepOutcome(stepsCompleted: [
            .init(stepId: "s1", completedAt: Date(), skipped: false),
            .init(stepId: "s2", completedAt: Date(), skipped: true)
        ])
        completion.setOutcomeData(outcome)

        XCTAssertNotNil(completion.outcomeData)
        XCTAssertEqual(completion.multiStepOutcome?.stepsCompleted.count, 2)
        XCTAssertFalse(completion.multiStepOutcome?.stepsCompleted[0].skipped ?? true)
        XCTAssertTrue(completion.multiStepOutcome?.stepsCompleted[1].skipped ?? false)
    }

    func test_FixCompletion_setOutcomeData_encodesQuizOutcome() {
        let completion = FixCompletion(
            fixId: UUID(),
            userId: UUID()
        )

        let outcome = QuizOutcome(selectedOptionId: "option-a", weightModifierApplied: 1.25)
        completion.setOutcomeData(outcome)

        XCTAssertNotNil(completion.outcomeData)
        XCTAssertEqual(completion.quizOutcome?.selectedOptionId, "option-a")
        XCTAssertEqual(completion.quizOutcome?.weightModifierApplied, 1.25)
    }

    func test_FixCompletion_setOutcomeData_encodesScenarioOutcome() {
        let completion = FixCompletion(
            fixId: UUID(),
            userId: UUID()
        )

        let outcome = ScenarioOutcome(selectedOptionId: "response-1", weightModifierApplied: 1.15)
        completion.setOutcomeData(outcome)

        XCTAssertNotNil(completion.outcomeData)
        XCTAssertEqual(completion.scenarioOutcome?.selectedOptionId, "response-1")
        XCTAssertEqual(completion.scenarioOutcome?.weightModifierApplied, 1.15)
    }

    func test_FixCompletion_setOutcomeData_encodesCounterOutcome() {
        let completion = FixCompletion(
            fixId: UUID(),
            userId: UUID()
        )

        let outcome = CounterOutcome(
            finalCount: 5,
            countHistory: [
                .init(timestamp: Date(), delta: 1),
                .init(timestamp: Date(), delta: 1)
            ]
        )
        completion.setOutcomeData(outcome)

        XCTAssertNotNil(completion.outcomeData)
        XCTAssertEqual(completion.counterOutcome?.finalCount, 5)
        XCTAssertEqual(completion.counterOutcome?.countHistory.count, 2)
    }

    func test_FixCompletion_outcomeAccessors_returnNilWhenNoData() {
        let completion = FixCompletion(
            fixId: UUID(),
            userId: UUID()
        )

        XCTAssertNil(completion.timedOutcome)
        XCTAssertNil(completion.multiStepOutcome)
        XCTAssertNil(completion.quizOutcome)
        XCTAssertNil(completion.scenarioOutcome)
        XCTAssertNil(completion.counterOutcome)
    }

    func test_FixCompletion_outcomeAccessors_returnNilForWrongType() {
        let completion = FixCompletion(
            fixId: UUID(),
            userId: UUID()
        )

        // Set timed outcome
        let timedOutcome = TimedOutcome(timerCompleted: true, actualDurationSeconds: 300)
        completion.setOutcomeData(timedOutcome)

        // timedOutcome should work
        XCTAssertNotNil(completion.timedOutcome)

        // Others should return nil (decoding fails because structure doesn't match)
        XCTAssertNil(completion.multiStepOutcome)
        XCTAssertNil(completion.quizOutcome)
        XCTAssertNil(completion.scenarioOutcome)
        XCTAssertNil(completion.counterOutcome)
    }

    func test_FixCompletion_canStoreOutcomeDataInInit() {
        let outcome = QuizOutcome(selectedOptionId: "test", weightModifierApplied: 1.0)
        let encodedData = try? JSONEncoder().encode(outcome)

        let completion = FixCompletion(
            fixId: UUID(),
            userId: UUID(),
            outcome: .applied,
            outcomeData: encodedData
        )

        XCTAssertNotNil(completion.outcomeData)
        XCTAssertEqual(completion.quizOutcome?.selectedOptionId, "test")
    }
}
