import XCTest
@testable import EgoFix

final class VersionEntryTests: XCTestCase {

    func test_VersionEntry_incrementsCorrectly_minorUpdate() {
        let entry = VersionEntry(
            userId: UUID(),
            version: "1.1",
            changeType: .minorUpdate,
            description: "7 fixes applied"
        )

        XCTAssertEqual(entry.version, "1.1")
        XCTAssertEqual(entry.changeType, .minorUpdate)
    }

    func test_VersionEntry_incrementsCorrectly_majorUpdate() {
        let entry = VersionEntry(
            userId: UUID(),
            version: "2.0",
            changeType: .majorUpdate,
            description: "Major milestone reached"
        )

        XCTAssertEqual(entry.version, "2.0")
        XCTAssertEqual(entry.changeType, .majorUpdate)
    }

    func test_VersionEntry_crashType() {
        let entry = VersionEntry(
            userId: UUID(),
            version: "1.5",
            changeType: .crash,
            description: "Crash logged"
        )

        XCTAssertEqual(entry.changeType, .crash)
    }

    func test_VersionEntry_rebootType() {
        let entry = VersionEntry(
            userId: UUID(),
            version: "1.5",
            changeType: .reboot,
            description: "Rebooted after crash"
        )

        XCTAssertEqual(entry.changeType, .reboot)
    }
}
