import XCTest
@testable import EgoFix

final class FixCompletionDataTests: XCTestCase {

    // MARK: - TimedOutcome Tests

    func test_TimedOutcome_encodesAndDecodes() throws {
        let outcome = TimedOutcome(timerCompleted: true, actualDurationSeconds: 300)

        let data = try JSONEncoder().encode(outcome)
        let decoded = try JSONDecoder().decode(TimedOutcome.self, from: data)

        XCTAssertEqual(decoded, outcome)
        XCTAssertTrue(decoded.timerCompleted)
        XCTAssertEqual(decoded.actualDurationSeconds, 300)
    }

    func test_TimedOutcome_handlesIncompletedTimer() throws {
        let outcome = TimedOutcome(timerCompleted: false, actualDurationSeconds: nil)

        let data = try JSONEncoder().encode(outcome)
        let decoded = try JSONDecoder().decode(TimedOutcome.self, from: data)

        XCTAssertEqual(decoded, outcome)
        XCTAssertFalse(decoded.timerCompleted)
        XCTAssertNil(decoded.actualDurationSeconds)
    }

    // MARK: - MultiStepOutcome Tests

    func test_MultiStepOutcome_encodesAndDecodes() throws {
        let now = Date()
        let outcome = MultiStepOutcome(stepsCompleted: [
            .init(stepId: "step-1", completedAt: now, skipped: false),
            .init(stepId: "step-2", completedAt: now, skipped: true)
        ])

        let data = try JSONEncoder().encode(outcome)
        let decoded = try JSONDecoder().decode(MultiStepOutcome.self, from: data)

        XCTAssertEqual(decoded.stepsCompleted.count, 2)
        XCTAssertEqual(decoded.stepsCompleted[0].stepId, "step-1")
        XCTAssertFalse(decoded.stepsCompleted[0].skipped)
        XCTAssertEqual(decoded.stepsCompleted[1].stepId, "step-2")
        XCTAssertTrue(decoded.stepsCompleted[1].skipped)
    }

    func test_MultiStepOutcome_allStepsCompleted_whenAllDone() {
        let outcome = MultiStepOutcome(stepsCompleted: [
            .init(stepId: "s1", completedAt: Date(), skipped: false),
            .init(stepId: "s2", completedAt: Date(), skipped: false)
        ])

        XCTAssertTrue(outcome.allStepsCompleted)
    }

    func test_MultiStepOutcome_allStepsCompleted_falseWhenSomeSkipped() {
        let outcome = MultiStepOutcome(stepsCompleted: [
            .init(stepId: "s1", completedAt: Date(), skipped: false),
            .init(stepId: "s2", completedAt: Date(), skipped: true)
        ])

        XCTAssertFalse(outcome.allStepsCompleted)
    }

    func test_MultiStepOutcome_allStepsCompleted_falseWhenEmpty() {
        let outcome = MultiStepOutcome(stepsCompleted: [])

        XCTAssertFalse(outcome.allStepsCompleted)
    }

    func test_MultiStepOutcome_completedCount() {
        let outcome = MultiStepOutcome(stepsCompleted: [
            .init(stepId: "s1", completedAt: Date(), skipped: false),
            .init(stepId: "s2", completedAt: Date(), skipped: true),
            .init(stepId: "s3", completedAt: Date(), skipped: false)
        ])

        XCTAssertEqual(outcome.completedCount, 2)
    }

    func test_MultiStepOutcome_skippedCount() {
        let outcome = MultiStepOutcome(stepsCompleted: [
            .init(stepId: "s1", completedAt: Date(), skipped: false),
            .init(stepId: "s2", completedAt: Date(), skipped: true),
            .init(stepId: "s3", completedAt: Date(), skipped: true)
        ])

        XCTAssertEqual(outcome.skippedCount, 2)
    }

    // MARK: - QuizOutcome Tests

    func test_QuizOutcome_encodesAndDecodes() throws {
        let outcome = QuizOutcome(selectedOptionId: "option-a", weightModifierApplied: 1.25)

        let data = try JSONEncoder().encode(outcome)
        let decoded = try JSONDecoder().decode(QuizOutcome.self, from: data)

        XCTAssertEqual(decoded, outcome)
        XCTAssertEqual(decoded.selectedOptionId, "option-a")
        XCTAssertEqual(decoded.weightModifierApplied, 1.25)
    }

    func test_QuizOutcome_handlesVariousWeightModifiers() throws {
        let lowWeight = QuizOutcome(selectedOptionId: "a", weightModifierApplied: 0.5)
        let highWeight = QuizOutcome(selectedOptionId: "b", weightModifierApplied: 2.0)
        let neutralWeight = QuizOutcome(selectedOptionId: "c", weightModifierApplied: 1.0)

        XCTAssertEqual(lowWeight.weightModifierApplied, 0.5)
        XCTAssertEqual(highWeight.weightModifierApplied, 2.0)
        XCTAssertEqual(neutralWeight.weightModifierApplied, 1.0)
    }

    // MARK: - ScenarioOutcome Tests

    func test_ScenarioOutcome_encodesAndDecodes() throws {
        let outcome = ScenarioOutcome(selectedOptionId: "response-1", weightModifierApplied: 1.15)

        let data = try JSONEncoder().encode(outcome)
        let decoded = try JSONDecoder().decode(ScenarioOutcome.self, from: data)

        XCTAssertEqual(decoded, outcome)
        XCTAssertEqual(decoded.selectedOptionId, "response-1")
        XCTAssertEqual(decoded.weightModifierApplied, 1.15)
    }

    // MARK: - CounterOutcome Tests

    func test_CounterOutcome_encodesAndDecodes() throws {
        let now = Date()
        let outcome = CounterOutcome(
            finalCount: 7,
            countHistory: [
                .init(timestamp: now, delta: 1),
                .init(timestamp: now.addingTimeInterval(60), delta: 1),
                .init(timestamp: now.addingTimeInterval(120), delta: -1)
            ]
        )

        let data = try JSONEncoder().encode(outcome)
        let decoded = try JSONDecoder().decode(CounterOutcome.self, from: data)

        XCTAssertEqual(decoded.finalCount, 7)
        XCTAssertEqual(decoded.countHistory.count, 3)
        XCTAssertEqual(decoded.countHistory[0].delta, 1)
        XCTAssertEqual(decoded.countHistory[2].delta, -1)
    }

    func test_CounterOutcome_handlesEmptyHistory() throws {
        let outcome = CounterOutcome(finalCount: 0, countHistory: [])

        let data = try JSONEncoder().encode(outcome)
        let decoded = try JSONDecoder().decode(CounterOutcome.self, from: data)

        XCTAssertEqual(decoded.finalCount, 0)
        XCTAssertTrue(decoded.countHistory.isEmpty)
    }

    func test_CounterOutcome_CountEvent_capturesTimestamp() {
        let timestamp = Date()
        let event = CounterOutcome.CountEvent(timestamp: timestamp, delta: 1)

        XCTAssertEqual(event.timestamp, timestamp)
        XCTAssertEqual(event.delta, 1)
    }

    func test_CounterOutcome_CountEvent_supportsNegativeDeltas() {
        let event = CounterOutcome.CountEvent(timestamp: Date(), delta: -1)

        XCTAssertEqual(event.delta, -1)
    }
}
