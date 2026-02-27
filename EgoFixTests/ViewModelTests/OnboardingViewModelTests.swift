import XCTest
@testable import EgoFix

@MainActor
final class OnboardingViewModelTests: XCTestCase {

    private var bugRepo: MockBugRepository!
    private var userRepo: MockUserRepository!
    private var viewModel: OnboardingViewModel!

    override func setUp() {
        super.setUp()
        bugRepo = MockBugRepository()
        userRepo = MockUserRepository()
        viewModel = OnboardingViewModel(
            bugRepository: bugRepo,
            userRepository: userRepo
        )
    }

    // MARK: - Helpers

    private let slugs = [
        "need-to-be-right", "need-to-be-liked", "need-to-control",
        "need-to-compare", "need-to-impress", "need-to-deflect", "need-to-narrate"
    ]

    private func seedBugs(count: Int) async throws {
        for i in 0..<count {
            let bug = Bug(
                slug: slugs[i],
                title: "Bug \(i)",
                description: "Description for bug \(i)"
            )
            try await bugRepo.save(bug)
        }
    }

    // MARK: - State Machine Tests

    func test_OnboardingViewModel_initialState_isBoot() {
        XCTAssertEqual(viewModel.state, .boot)
    }

    func test_OnboardingViewModel_beginScan_transitionsToScanning() async throws {
        try await seedBugs(count: 7)
        await viewModel.loadBugs()

        viewModel.beginScan()

        XCTAssertEqual(viewModel.state, .scanning(bugIndex: 0))
        XCTAssertNotNil(viewModel.currentBug)
        XCTAssertEqual(viewModel.currentBug?.slug, "need-to-be-right")
    }

    func test_OnboardingViewModel_respondToBug_advancesIndex() async throws {
        try await seedBugs(count: 7)
        await viewModel.loadBugs()
        viewModel.beginScan()

        let bug = viewModel.allBugs[0]
        viewModel.respondToBug(bug.id, response: .yesOften)

        XCTAssertEqual(viewModel.state, .scanning(bugIndex: 1))
        XCTAssertEqual(viewModel.responses[bug.id], .yesOften)
    }

    func test_OnboardingViewModel_showsMoreDetectedAfterFifthBug() async throws {
        try await seedBugs(count: 7)
        await viewModel.loadBugs()
        viewModel.beginScan()

        // Respond to first 5 bugs
        for i in 0..<5 {
            viewModel.respondToBug(viewModel.allBugs[i].id, response: .sometimes)
        }

        XCTAssertEqual(viewModel.state, .moreDetected)
    }

    func test_OnboardingViewModel_continueAfterMoreDetected_resumesAt6th() async throws {
        try await seedBugs(count: 7)
        await viewModel.loadBugs()
        viewModel.beginScan()

        for i in 0..<5 {
            viewModel.respondToBug(viewModel.allBugs[i].id, response: .sometimes)
        }
        XCTAssertEqual(viewModel.state, .moreDetected)

        viewModel.continueAfterMoreDetected()
        XCTAssertEqual(viewModel.state, .scanning(bugIndex: 5))
    }

    func test_OnboardingViewModel_afterAllBugs_goesToConfirmation() async throws {
        try await seedBugs(count: 7)
        await viewModel.loadBugs()
        viewModel.beginScan()

        // Respond to first 5
        for i in 0..<5 {
            viewModel.respondToBug(viewModel.allBugs[i].id, response: .sometimes)
        }
        viewModel.continueAfterMoreDetected()

        // Respond to last 2
        viewModel.respondToBug(viewModel.allBugs[5].id, response: .rarely)
        viewModel.respondToBug(viewModel.allBugs[6].id, response: .rarely)

        XCTAssertEqual(viewModel.state, .confirmation)
    }

    // MARK: - Response Weighting Tests

    func test_OnboardingViewModel_activeBugs_sortedByWeight() async throws {
        try await seedBugs(count: 7)
        await viewModel.loadBugs()

        // Set specific responses
        viewModel.responses[viewModel.allBugs[0].id] = .rarely      // need-to-be-right: 1
        viewModel.responses[viewModel.allBugs[1].id] = .yesOften    // need-to-be-liked: 3
        viewModel.responses[viewModel.allBugs[2].id] = .sometimes   // need-to-control: 2
        viewModel.responses[viewModel.allBugs[3].id] = .yesOften    // need-to-compare: 3
        viewModel.responses[viewModel.allBugs[4].id] = .rarely      // need-to-impress: 1
        viewModel.responses[viewModel.allBugs[5].id] = .sometimes   // need-to-deflect: 2
        viewModel.responses[viewModel.allBugs[6].id] = .rarely      // need-to-narrate: 1

        let active = viewModel.activeBugs
        XCTAssertEqual(active.count, 3)

        // Top 3 should be: need-to-be-liked (3), need-to-compare (3), need-to-control (2)
        XCTAssertEqual(active[0].slug, "need-to-be-liked")
        XCTAssertEqual(active[1].slug, "need-to-compare")
        XCTAssertEqual(active[2].slug, "need-to-control")
    }

    func test_OnboardingViewModel_activeBugs_tiesResolvedByOriginalOrder() async throws {
        try await seedBugs(count: 7)
        await viewModel.loadBugs()

        // All rate "sometimes" — ties should preserve original order
        for bug in viewModel.allBugs {
            viewModel.responses[bug.id] = .sometimes
        }

        let active = viewModel.activeBugs
        XCTAssertEqual(active.count, 3)
        XCTAssertEqual(active[0].slug, "need-to-be-right")
        XCTAssertEqual(active[1].slug, "need-to-be-liked")
        XCTAssertEqual(active[2].slug, "need-to-control")
    }

    func test_OnboardingViewModel_allRatedRarely_stillProducesTop3() async throws {
        try await seedBugs(count: 7)
        await viewModel.loadBugs()

        for bug in viewModel.allBugs {
            viewModel.responses[bug.id] = .rarely
        }

        XCTAssertTrue(viewModel.allRatedRarely)
        XCTAssertEqual(viewModel.activeBugs.count, 3)
        // Should take first 3 by original order
        XCTAssertEqual(viewModel.activeBugs[0].slug, "need-to-be-right")
    }

    func test_OnboardingViewModel_deprioritizedBugs_excludesActive() async throws {
        try await seedBugs(count: 7)
        await viewModel.loadBugs()

        for bug in viewModel.allBugs {
            viewModel.responses[bug.id] = .sometimes
        }

        XCTAssertEqual(viewModel.deprioritizedBugs.count, 4)
        let activeIds = Set(viewModel.activeBugs.map(\.id))
        for bug in viewModel.deprioritizedBugs {
            XCTAssertFalse(activeIds.contains(bug.id))
        }
    }

    // MARK: - Commit Tests

    func test_OnboardingViewModel_commitConfiguration_activatesBugsAndCreatesUser() async throws {
        try await seedBugs(count: 7)
        await viewModel.loadBugs()

        viewModel.responses[viewModel.allBugs[0].id] = .yesOften
        viewModel.responses[viewModel.allBugs[1].id] = .sometimes
        viewModel.responses[viewModel.allBugs[2].id] = .sometimes
        viewModel.responses[viewModel.allBugs[3].id] = .rarely
        viewModel.responses[viewModel.allBugs[4].id] = .rarely
        viewModel.responses[viewModel.allBugs[5].id] = .rarely
        viewModel.responses[viewModel.allBugs[6].id] = .rarely

        await viewModel.commitConfiguration()

        XCTAssertTrue(viewModel.isComplete)

        // Check user was created with priorities
        let user = try await userRepo.get()
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.bugPriorities.count, 7)
        XCTAssertEqual(user?.bugPriorities.first?.rank, 1)

        // Check active bugs are activated
        for bug in viewModel.activeBugs {
            XCTAssertTrue(bug.isActive)
            XCTAssertEqual(bug.status, .active)
            XCTAssertNotNil(bug.activatedAt)
        }

        // Check deprioritized bugs are not active
        for bug in viewModel.deprioritizedBugs {
            XCTAssertFalse(bug.isActive)
            XCTAssertEqual(bug.status, .identified)
        }
    }

    // MARK: - Onboarding Check Tests

    func test_OnboardingViewModel_checkOnboardingNeeded_trueWhenNoUser() async {
        let needed = await viewModel.checkOnboardingNeeded()
        XCTAssertTrue(needed)
    }

    func test_OnboardingViewModel_checkOnboardingNeeded_falseWhenUserHasPriorities() async throws {
        let user = UserProfile(
            bugPriorities: [BugPriority(bugId: UUID(), rank: 1)]
        )
        try await userRepo.save(user)

        let needed = await viewModel.checkOnboardingNeeded()
        XCTAssertFalse(needed)
    }

    // MARK: - Nickname & Comment Tests

    func test_OnboardingViewModel_nickname_returnsCorrectNicknames() {
        XCTAssertEqual(viewModel.nickname(for: "need-to-be-right"), "The Corrector")
        XCTAssertEqual(viewModel.nickname(for: "need-to-impress"), "The Performer")
        XCTAssertEqual(viewModel.nickname(for: "need-to-be-liked"), "The Chameleon")
        XCTAssertEqual(viewModel.nickname(for: "need-to-control"), "The Controller")
        XCTAssertEqual(viewModel.nickname(for: "need-to-compare"), "The Scorekeeper")
        XCTAssertEqual(viewModel.nickname(for: "need-to-deflect"), "The Deflector")
        XCTAssertEqual(viewModel.nickname(for: "need-to-narrate"), "The Narrator")
        XCTAssertEqual(viewModel.nickname(for: "unknown"), "Unknown")
    }

    func test_OnboardingViewModel_inlineComment_existsForAllBugs() {
        for slug in slugs {
            let comment = viewModel.inlineComment(for: slug)
            XCTAssertTrue(comment.hasPrefix("//"), "Comment for \(slug) should start with //")
            XCTAssertFalse(comment.isEmpty, "Comment for \(slug) should not be empty")
        }
    }

    // MARK: - Response Label Tests

    func test_OnboardingViewModel_responseLabel_formatsCorrectly() async throws {
        try await seedBugs(count: 3)
        await viewModel.loadBugs()

        let bug = viewModel.allBugs[0]

        viewModel.responses[bug.id] = .yesOften
        XCTAssertEqual(viewModel.responseLabel(for: bug), "// runs often")

        viewModel.responses[bug.id] = .sometimes
        XCTAssertEqual(viewModel.responseLabel(for: bug), "// runs sometimes")

        viewModel.responses[bug.id] = .rarely
        XCTAssertEqual(viewModel.responseLabel(for: bug), "// runs rarely")
    }

    // MARK: - No Bugs Edge Case

    func test_OnboardingViewModel_beginScan_doesNothingWithNoBugs() {
        viewModel.beginScan()
        XCTAssertEqual(viewModel.state, .boot)
    }

    // MARK: - Fewer Than 5 Bugs (no "more detected" pause)

    func test_OnboardingViewModel_fewBugs_skipsMoreDetected() async throws {
        try await seedBugs(count: 4)
        await viewModel.loadBugs()
        viewModel.beginScan()

        for i in 0..<4 {
            viewModel.respondToBug(viewModel.allBugs[i].id, response: .sometimes)
        }

        // Should go straight to confirmation, not moreDetected
        XCTAssertEqual(viewModel.state, .confirmation)
    }
}
