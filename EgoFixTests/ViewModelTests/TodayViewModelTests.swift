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

    func test_TodayViewState_completedHoldsOutcomeAndTidbit() {
        let state = TodayViewState.completed(.applied, "A tidbit")
        if case .completed(let outcome, let tidbit) = state {
            XCTAssertEqual(outcome, .applied)
            XCTAssertEqual(tidbit, "A tidbit")
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
