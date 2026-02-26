import XCTest
@testable import EgoFix

final class UserProfileTests: XCTestCase {

    func test_UserProfile_defaultVersion() {
        // New user starts at v1.0
        let user = UserProfile()
        XCTAssertEqual(user.currentVersion, "1.0")
    }

    func test_UserProfile_hasUniqueId() {
        let user1 = UserProfile()
        let user2 = UserProfile()
        XCTAssertNotEqual(user1.id, user2.id)
    }

    func test_UserProfile_createdAtIsSet() {
        let before = Date()
        let user = UserProfile()
        let after = Date()

        XCTAssertGreaterThanOrEqual(user.createdAt, before)
        XCTAssertLessThanOrEqual(user.createdAt, after)
    }
}
