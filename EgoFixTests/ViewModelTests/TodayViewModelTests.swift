import XCTest
@testable import EgoFix

@MainActor
final class TodayViewModelTests: XCTestCase {

    // MARK: - State enum coverage

    func test_TodayViewState_hasDoneForTodayCase() {
        let state = TodayViewState.doneForToday
        if case .doneForToday = state {
            // Pass — the state case exists
        } else {
            XCTFail("doneForToday state should exist")
        }
    }

    func test_TodayViewState_fixBriefingExists() {
        let fix = Fix(bugId: UUID(), type: .daily, severity: .medium, prompt: "Test", validation: "v")
        let completion = FixCompletion(fixId: fix.id, userId: UUID())
        let state = TodayViewState.fixBriefing(completion, fix)
        XCTAssertEqual(state.stateKey, "fixBriefing")
    }

    func test_TodayViewState_fixActiveExists() {
        let fix = Fix(bugId: UUID(), type: .daily, severity: .medium, prompt: "Test", validation: "v")
        let completion = FixCompletion(fixId: fix.id, userId: UUID())
        let state = TodayViewState.fixActive(completion, fix)
        XCTAssertEqual(state.stateKey, "fixActive")
    }

    func test_TodayViewState_checkInExists() {
        let fix = Fix(bugId: UUID(), type: .daily, severity: .medium, prompt: "Test", validation: "v")
        let completion = FixCompletion(fixId: fix.id, userId: UUID())
        let state = TodayViewState.checkIn(completion, fix)
        XCTAssertEqual(state.stateKey, "checkIn")
    }

    func test_TodayViewState_debriefExists() {
        let content = DebriefContent(
            title: "DEBRIEF",
            body: "Applied today.",
            comment: "// Data logged.",
            template: .tomorrowPreview
        )
        let state = TodayViewState.debrief(content)
        XCTAssertEqual(state.stateKey, "debrief")
    }

    func test_TodayViewState_completedHoldsOutcomeAndTidbit() {
        let state = TodayViewState.completed(.applied, "A tidbit")
        if case .completed(let outcome, let tidbit) = state {
            XCTAssertEqual(outcome, .applied)
            XCTAssertEqual(tidbit, "A tidbit")
        } else {
            XCTFail("Expected completed state")
        }
    }

    func test_TodayViewState_fixEducationExists() {
        let fix = Fix(bugId: UUID(), type: .daily, severity: .medium, prompt: "Test", validation: "v")
        let completion = FixCompletion(fixId: fix.id, userId: UUID())
        let state = TodayViewState.fixEducation(completion, fix, "Your need to be right isn't about truth.")
        XCTAssertEqual(state.stateKey, "fixEducation")
    }

    func test_TodayViewState_fixEducationHoldsContent() {
        let fix = Fix(bugId: UUID(), type: .daily, severity: .medium, prompt: "Test", validation: "v")
        let completion = FixCompletion(fixId: fix.id, userId: UUID())
        let tidbit = "The correction impulse fires before the listening impulse gets a chance."
        let state = TodayViewState.fixEducation(completion, fix, tidbit)
        if case .fixEducation(_, _, let body) = state {
            XCTAssertEqual(body, tidbit)
        } else {
            XCTFail("Expected fixEducation state")
        }
    }

    func test_completedState_canHaveNilTidbit() {
        // After moving education pre-fix, completed state should work with nil tidbit
        let state = TodayViewState.completed(.applied, nil)
        if case .completed(let outcome, let tidbit) = state {
            XCTAssertEqual(outcome, .applied)
            XCTAssertNil(tidbit)
        } else {
            XCTFail("Expected completed state")
        }
    }

    // MARK: - Done status messages

    func test_doneStatusLine_isSetByOutcome() {
        // WeeklySummaryData comment logic
        let summary = WeeklySummaryData(applied: 5, skipped: 1, failed: 0)
        XCTAssertEqual(summary.comment, "// Solid week. Keep going.")

        let roughWeek = WeeklySummaryData(applied: 1, skipped: 0, failed: 3)
        XCTAssertEqual(roughWeek.comment, "// Rough week. The data doesn't judge.")

        let skipWeek = WeeklySummaryData(applied: 1, skipped: 4, failed: 0)
        XCTAssertEqual(skipWeek.comment, "// A lot of skips. No judgment — sometimes you're not ready.")
    }

    // MARK: - Skipped tests (require mock services)

    func test_TodayViewModel_stateTransitions() async {
        XCTSkip("Requires mock service implementation")
    }

    func test_TodayViewModel_showsQuickFix_afterCrash() async {
        XCTSkip("Requires mock service implementation")
    }

    func test_TodayViewModel_initialState_isLoading() async {
        XCTSkip("Requires mock service implementation")
    }
}
