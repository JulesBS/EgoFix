import XCTest
@testable import EgoFix

final class StatusLineProviderTests: XCTestCase {

    // MARK: - Line generation returns non-empty for all intensities

    func test_line_quiet_normal_returnsNonEmpty() {
        let line = StatusLineProvider.line(for: .quiet, bugTitle: "The Corrector", context: .normal)
        XCTAssertFalse(line.isEmpty)
        XCTAssertTrue(line.hasPrefix("//"))
    }

    func test_line_present_normal_returnsNonEmpty() {
        let line = StatusLineProvider.line(for: .present, bugTitle: "The Corrector", context: .normal)
        XCTAssertFalse(line.isEmpty)
        XCTAssertTrue(line.hasPrefix("//"))
    }

    func test_line_loud_normal_returnsNonEmpty() {
        let line = StatusLineProvider.line(for: .loud, bugTitle: "The Corrector", context: .normal)
        XCTAssertFalse(line.isEmpty)
        XCTAssertTrue(line.hasPrefix("//"))
    }

    // MARK: - Context variants

    func test_line_postCrash_returnsPostCrashLine() {
        let line = StatusLineProvider.line(for: .present, bugTitle: "The Corrector", context: .postCrash)
        XCTAssertFalse(line.isEmpty)
        XCTAssertTrue(line.hasPrefix("//"))
    }

    func test_line_firstDay_returnsFirstDayLine() {
        let line = StatusLineProvider.line(for: .present, bugTitle: "The Corrector", context: .firstDay)
        XCTAssertFalse(line.isEmpty)
        XCTAssertTrue(line.hasPrefix("//"))
    }

    func test_line_longStreak_returnsNonEmpty() {
        let line = StatusLineProvider.line(for: .present, bugTitle: "The Corrector", context: .longStreak(14))
        XCTAssertFalse(line.isEmpty)
        XCTAssertTrue(line.hasPrefix("//"))
    }

    // MARK: - Streak formatting

    func test_formatStreak_zero() {
        XCTAssertEqual(StatusLineProvider.formatStreak(0), "\u{2219} 0")
    }

    func test_formatStreak_low() {
        let result = StatusLineProvider.formatStreak(3)
        XCTAssertTrue(result.contains("3"))
    }

    func test_formatStreak_high() {
        XCTAssertEqual(StatusLineProvider.formatStreak(10), "10 days")
    }

    // MARK: - Milestone comments

    func test_streakMilestone_day7() {
        XCTAssertNotNil(StatusLineProvider.streakMilestoneComment(for: 7))
    }

    func test_streakMilestone_day14() {
        XCTAssertNotNil(StatusLineProvider.streakMilestoneComment(for: 14))
    }

    func test_streakMilestone_day30() {
        XCTAssertNotNil(StatusLineProvider.streakMilestoneComment(for: 30))
    }

    func test_streakMilestone_nonMilestone_returnsNil() {
        XCTAssertNil(StatusLineProvider.streakMilestoneComment(for: 5))
        XCTAssertNil(StatusLineProvider.streakMilestoneComment(for: 10))
        XCTAssertNil(StatusLineProvider.streakMilestoneComment(for: 22))
    }
}
