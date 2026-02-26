import XCTest
@testable import EgoFix

final class CalendarActivityTests: XCTestCase {

    // MARK: - Outcome Color

    func test_outcomeColor_applied_whenFixesApplied() {
        let day = CalendarDay(
            id: Date(),
            fixesApplied: 1,
            fixesSkipped: 0,
            fixesFailed: 0,
            crashes: 0
        )
        XCTAssertEqual(day.outcomeColor, .applied)
    }

    func test_outcomeColor_skipped_whenOnlySkipped() {
        let day = CalendarDay(
            id: Date(),
            fixesApplied: 0,
            fixesSkipped: 2,
            fixesFailed: 0,
            crashes: 0
        )
        XCTAssertEqual(day.outcomeColor, .skipped)
    }

    func test_outcomeColor_crash_whenCrashPresent() {
        let day = CalendarDay(
            id: Date(),
            fixesApplied: 1,
            fixesSkipped: 0,
            fixesFailed: 0,
            crashes: 1
        )
        XCTAssertEqual(day.outcomeColor, .crash)
    }

    func test_outcomeColor_crash_whenFailed() {
        let day = CalendarDay(
            id: Date(),
            fixesApplied: 0,
            fixesSkipped: 0,
            fixesFailed: 1,
            crashes: 0
        )
        XCTAssertEqual(day.outcomeColor, .crash)
    }

    func test_outcomeColor_crash_takesHighestPriority() {
        let day = CalendarDay(
            id: Date(),
            fixesApplied: 3,
            fixesSkipped: 2,
            fixesFailed: 1,
            crashes: 1
        )
        // Crash/failed takes priority over applied and skipped
        XCTAssertEqual(day.outcomeColor, .crash)
    }

    func test_outcomeColor_applied_overSkipped() {
        let day = CalendarDay(
            id: Date(),
            fixesApplied: 1,
            fixesSkipped: 2,
            fixesFailed: 0,
            crashes: 0
        )
        // Applied takes priority over skipped
        XCTAssertEqual(day.outcomeColor, .applied)
    }

    func test_outcomeColor_empty_whenNoActivity() {
        let day = CalendarDay.empty(for: Date())
        XCTAssertEqual(day.outcomeColor, .empty)
    }

    // MARK: - Intensity

    func test_intensity_none_forEmptyDay() {
        let day = CalendarDay.empty(for: Date())
        XCTAssertEqual(day.intensity, .none)
    }

    func test_intensity_low_forSingleActivity() {
        let day = CalendarDay(
            id: Date(),
            fixesApplied: 1,
            fixesSkipped: 0,
            fixesFailed: 0,
            crashes: 0
        )
        XCTAssertEqual(day.intensity, .low)
    }

    func test_intensity_medium_forModerateActivity() {
        let day = CalendarDay(
            id: Date(),
            fixesApplied: 1,
            fixesSkipped: 1,
            fixesFailed: 0,
            crashes: 0
        )
        XCTAssertEqual(day.intensity, .medium)
    }

    func test_intensity_high_forHeavyActivity() {
        let day = CalendarDay(
            id: Date(),
            fixesApplied: 2,
            fixesSkipped: 1,
            fixesFailed: 1,
            crashes: 1
        )
        XCTAssertEqual(day.intensity, .high)
    }
}
