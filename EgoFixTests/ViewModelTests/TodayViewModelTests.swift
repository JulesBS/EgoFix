import XCTest
@testable import EgoFix

final class TodayViewModelTests: XCTestCase {

    func test_TodayViewModel_stateTransitions() async {
        // loading → loaded → applied
        XCTSkip("Requires mock service implementation")
    }

    func test_TodayViewModel_showsQuickFix_afterCrash() async {
        XCTSkip("Requires mock service implementation")
    }

    func test_TodayViewModel_initialState_isLoading() async {
        XCTSkip("Requires mock service implementation")
    }
}
