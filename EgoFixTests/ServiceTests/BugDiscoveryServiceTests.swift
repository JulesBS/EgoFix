import XCTest
@testable import EgoFix

@MainActor
final class BugDiscoveryServiceTests: XCTestCase {

    func test_relatedPairings_allSlugsAreValid() {
        let validSlugs: Set<String> = [
            "need-to-be-right", "need-to-be-liked", "need-to-control",
            "need-to-compare", "need-to-impress", "need-to-deflect", "need-to-narrate"
        ]

        for (key, value) in BugDiscoveryService.relatedPairings {
            XCTAssertTrue(validSlugs.contains(key), "Invalid source slug: \(key)")
            XCTAssertTrue(validSlugs.contains(value), "Invalid target slug: \(value)")
        }
    }

    func test_relatedPairings_coverAllSevenBugs() {
        let keys = Set(BugDiscoveryService.relatedPairings.keys)
        XCTAssertEqual(keys.count, 7, "Should have pairings for all 7 bugs")
    }

    func test_getIdentifiedBugs_filtersCorrectly() async throws {
        let bugRepo = MockBugRepository()
        let userRepo = MockUserRepository()
        let completionRepo = MockFixCompletionRepository()

        let activeBug = Bug(slug: "need-to-be-right", title: "Test", description: "d", isActive: true, status: .active)
        let identifiedBug = Bug(slug: "need-to-control", title: "Test2", description: "d", isActive: false, status: .identified)

        try await bugRepo.save(activeBug)
        try await bugRepo.save(identifiedBug)

        let service = BugDiscoveryService(
            bugRepository: bugRepo,
            userRepository: userRepo,
            fixCompletionRepository: completionRepo
        )

        let identified = try await service.getIdentifiedBugs()
        XCTAssertEqual(identified.count, 1)
        XCTAssertEqual(identified.first?.slug, "need-to-control")
    }

    func test_activateBug_setsActiveAndAddsPriority() async throws {
        let bugRepo = MockBugRepository()
        let userRepo = MockUserRepository()
        let completionRepo = MockFixCompletionRepository()

        let bug = Bug(slug: "need-to-control", title: "Test", description: "d", isActive: false, status: .identified)
        try await bugRepo.save(bug)

        let user = UserProfile(bugPriorities: [BugPriority(bugId: UUID(), rank: 1)])
        try await userRepo.save(user)

        let service = BugDiscoveryService(
            bugRepository: bugRepo,
            userRepository: userRepo,
            fixCompletionRepository: completionRepo
        )

        try await service.activateBug(bug.id)

        let updatedBug = try await bugRepo.getById(bug.id)
        XCTAssertTrue(updatedBug?.isActive ?? false)
        XCTAssertEqual(updatedBug?.status, .active)
        XCTAssertNotNil(updatedBug?.activatedAt)

        let updatedUser = try await userRepo.get()
        XCTAssertEqual(updatedUser?.bugPriorities.count, 2)
    }
}
