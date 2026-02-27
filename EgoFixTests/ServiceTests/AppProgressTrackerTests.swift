import XCTest
@testable import EgoFix

@MainActor
final class AppProgressTrackerTests: XCTestCase {

    private var tracker: AppProgressTracker!

    override func setUp() {
        super.setUp()
        tracker = AppProgressTracker()
        // Reset all state
        tracker.totalFixesCompleted = 0
        tracker.firstDiagnosticCompleted = false
        tracker.firstPatternDetected = false
        tracker.daysActive = 0
        tracker.lastActiveDate = ""
        tracker.hasSeenHistoryUnlock = false
        tracker.hasSeenPatternsUnlock = false
        tracker.hasSeenBugLibraryUnlock = false
    }

    // MARK: - Unlock Thresholds

    func test_AppProgressTracker_historyUnlocksAt3Fixes() {
        XCTAssertFalse(tracker.isHistoryUnlocked)

        tracker.totalFixesCompleted = 2
        XCTAssertFalse(tracker.isHistoryUnlocked)

        tracker.totalFixesCompleted = 3
        XCTAssertTrue(tracker.isHistoryUnlocked)
    }

    func test_AppProgressTracker_patternsUnlocksOnFirstPattern() {
        XCTAssertFalse(tracker.isPatternsUnlocked)

        tracker.recordPatternDetected()
        XCTAssertTrue(tracker.isPatternsUnlocked)
    }

    func test_AppProgressTracker_bugLibraryUnlocksAt7Fixes() {
        XCTAssertFalse(tracker.isBugLibraryUnlocked)

        tracker.totalFixesCompleted = 6
        XCTAssertFalse(tracker.isBugLibraryUnlocked)

        tracker.totalFixesCompleted = 7
        XCTAssertTrue(tracker.isBugLibraryUnlocked)
    }

    func test_AppProgressTracker_fullNavUnlocksAt14DaysAnd10Fixes() {
        XCTAssertFalse(tracker.isFullNavUnlocked)

        tracker.daysActive = 14
        tracker.totalFixesCompleted = 9
        XCTAssertFalse(tracker.isFullNavUnlocked)

        tracker.totalFixesCompleted = 10
        XCTAssertTrue(tracker.isFullNavUnlocked)

        // Missing days — still locked
        tracker.daysActive = 13
        XCTAssertFalse(tracker.isFullNavUnlocked)
    }

    // MARK: - Recording Actions

    func test_AppProgressTracker_recordFixCompletion_increments() {
        XCTAssertEqual(tracker.totalFixesCompleted, 0)

        tracker.recordFixCompletion()
        XCTAssertEqual(tracker.totalFixesCompleted, 1)

        tracker.recordFixCompletion()
        XCTAssertEqual(tracker.totalFixesCompleted, 2)
    }

    func test_AppProgressTracker_recordPatternDetected_onlyOnce() {
        tracker.recordPatternDetected()
        XCTAssertTrue(tracker.firstPatternDetected)

        // Second call is a no-op
        tracker.recordPatternDetected()
        XCTAssertTrue(tracker.firstPatternDetected)
    }

    func test_AppProgressTracker_recordDiagnosticCompleted_onlyOnce() {
        tracker.recordDiagnosticCompleted()
        XCTAssertTrue(tracker.firstDiagnosticCompleted)

        tracker.recordDiagnosticCompleted()
        XCTAssertTrue(tracker.firstDiagnosticCompleted)
    }

    func test_AppProgressTracker_recordDayActive_incrementsOncePerDay() {
        XCTAssertEqual(tracker.daysActive, 0)

        tracker.recordDayActive()
        XCTAssertEqual(tracker.daysActive, 1)

        // Same day — should not increment again
        tracker.recordDayActive()
        XCTAssertEqual(tracker.daysActive, 1)
    }

    // MARK: - One-Time Prompts

    func test_AppProgressTracker_historyUnlockPrompt_showsOnceOnly() {
        tracker.totalFixesCompleted = 3

        XCTAssertTrue(tracker.shouldShowHistoryUnlockPrompt)

        tracker.markHistoryUnlockSeen()
        XCTAssertFalse(tracker.shouldShowHistoryUnlockPrompt)
    }

    func test_AppProgressTracker_patternsUnlockPrompt_showsOnceOnly() {
        tracker.recordPatternDetected()

        XCTAssertTrue(tracker.shouldShowPatternsUnlockPrompt)

        tracker.markPatternsUnlockSeen()
        XCTAssertFalse(tracker.shouldShowPatternsUnlockPrompt)
    }

    func test_AppProgressTracker_bugLibraryUnlockPrompt_showsOnceOnly() {
        tracker.totalFixesCompleted = 7

        XCTAssertTrue(tracker.shouldShowBugLibraryUnlockPrompt)

        tracker.markBugLibraryUnlockSeen()
        XCTAssertFalse(tracker.shouldShowBugLibraryUnlockPrompt)
    }

    func test_AppProgressTracker_promptNotShownBeforeUnlock() {
        // Not enough fixes — prompt should not show even if not seen
        tracker.totalFixesCompleted = 2
        XCTAssertFalse(tracker.shouldShowHistoryUnlockPrompt)
    }
}
