import XCTest
@testable import EgoFix

final class CrashTests: XCTestCase {

    func test_Crash_rebootClearsState() {
        let crash = Crash(userId: UUID())

        XCTAssertNil(crash.rebootedAt)

        crash.rebootedAt = Date()

        XCTAssertNotNil(crash.rebootedAt)
    }

    func test_Crash_bugId_isOptional() {
        let crash = Crash(userId: UUID())

        XCTAssertNil(crash.bugId)

        let bugId = UUID()
        let crashWithBug = Crash(userId: UUID(), bugId: bugId)

        XCTAssertEqual(crashWithBug.bugId, bugId)
    }

    func test_Crash_note_isOptional() {
        let crash = Crash(userId: UUID())

        XCTAssertNil(crash.note)

        crash.note = "Lost my temper in a meeting"

        XCTAssertEqual(crash.note, "Lost my temper in a meeting")
    }

    func test_Crash_crashedAt_isSetOnInit() {
        let before = Date()
        let crash = Crash(userId: UUID())
        let after = Date()

        XCTAssertGreaterThanOrEqual(crash.crashedAt, before)
        XCTAssertLessThanOrEqual(crash.crashedAt, after)
    }
}
