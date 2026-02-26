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

    private func seedBugs(count: Int) async throws {
        let slugs = [
            "need-to-be-right", "need-to-be-liked", "need-to-control",
            "need-to-compare", "need-to-impress", "need-to-deflect", "need-to-narrate"
        ]
        for i in 0..<count {
            let bug = Bug(
                slug: slugs[i],
                title: "Bug \(i)",
                description: "Description for bug \(i)"
            )
            try await bugRepo.save(bug)
        }
    }

    // MARK: - Loading Tests

    func test_OnboardingViewModel_shows5BugsInitially() async throws {
        try await seedBugs(count: 7)

        await viewModel.loadBugs()

        XCTAssertEqual(viewModel.availableBugs.count, 5)
        XCTAssertEqual(viewModel.rankedBugs.count, 5)
        XCTAssertFalse(viewModel.showingAllBugs)
        XCTAssertTrue(viewModel.hasMoreBugs)
    }

    func test_OnboardingViewModel_showMoreRevealsAll7() async throws {
        try await seedBugs(count: 7)

        await viewModel.loadBugs()
        XCTAssertEqual(viewModel.availableBugs.count, 5)

        viewModel.showMore()

        XCTAssertEqual(viewModel.availableBugs.count, 7)
        XCTAssertEqual(viewModel.rankedBugs.count, 7)
        XCTAssertTrue(viewModel.showingAllBugs)
        XCTAssertFalse(viewModel.hasMoreBugs)
    }

    func test_OnboardingViewModel_showAllIfFiveOrFewer() async throws {
        try await seedBugs(count: 4)

        await viewModel.loadBugs()

        XCTAssertEqual(viewModel.availableBugs.count, 4)
        XCTAssertTrue(viewModel.showingAllBugs)
        XCTAssertFalse(viewModel.hasMoreBugs)
    }

    // MARK: - Step Transition Tests

    func test_OnboardingViewModel_stepTransitions() {
        XCTAssertEqual(viewModel.currentStep, .welcome)

        viewModel.goToRankBugs()
        XCTAssertEqual(viewModel.currentStep, .rankBugs)

        viewModel.confirmRanking()
        XCTAssertEqual(viewModel.currentStep, .confirmation)

        viewModel.goBack()
        XCTAssertEqual(viewModel.currentStep, .rankBugs)

        viewModel.goBack()
        XCTAssertEqual(viewModel.currentStep, .welcome)
    }

    // MARK: - Selection Tests

    func test_OnboardingViewModel_confirmSelection_activatesBugs() async throws {
        try await seedBugs(count: 3)

        await viewModel.loadBugs()
        await viewModel.confirmSelection()

        XCTAssertTrue(viewModel.isComplete)

        let user = try await userRepo.get()
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.bugPriorities.count, 3)
        XCTAssertEqual(user?.bugPriorities.first?.rank, 1)
    }

    func test_OnboardingViewModel_topPriorities_limitsToThree() async throws {
        try await seedBugs(count: 7)

        await viewModel.loadBugs()

        XCTAssertEqual(viewModel.topPriorities.count, 3)
    }

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
}
