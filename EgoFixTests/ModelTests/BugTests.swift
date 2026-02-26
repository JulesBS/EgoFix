import XCTest
@testable import EgoFix

final class BugTests: XCTestCase {

    func test_Bug_softDelete_setsTimestamp() {
        let bug = Bug(
            slug: "test-bug",
            title: "Test Bug",
            description: "A test bug"
        )

        XCTAssertNil(bug.deletedAt)

        bug.deletedAt = Date()

        XCTAssertNotNil(bug.deletedAt)
    }

    func test_Bug_defaultStatus_isIdentified() {
        let bug = Bug(
            slug: "test-bug",
            title: "Test Bug",
            description: "A test bug"
        )

        XCTAssertEqual(bug.status, .identified)
    }

    func test_Bug_defaultIsActive_isFalse() {
        let bug = Bug(
            slug: "test-bug",
            title: "Test Bug",
            description: "A test bug"
        )

        XCTAssertFalse(bug.isActive)
    }

    func test_Bug_activating_setsActivatedAt() {
        let bug = Bug(
            slug: "test-bug",
            title: "Test Bug",
            description: "A test bug"
        )

        XCTAssertNil(bug.activatedAt)

        bug.isActive = true
        bug.status = .active
        bug.activatedAt = Date()

        XCTAssertNotNil(bug.activatedAt)
        XCTAssertEqual(bug.status, .active)
    }
}
