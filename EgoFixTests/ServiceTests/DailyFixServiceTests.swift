import XCTest
@testable import EgoFix

@MainActor
final class DailyFixServiceTests: XCTestCase {

    private var fixRepo: MockFixRepository!
    private var completionRepo: MockFixCompletionRepository!
    private var userRepo: MockUserRepository!
    private var analyticsRepo: MockAnalyticsEventRepository!
    private var service: DailyFixService!

    private let userId = UUID()
    private let bugId = UUID()

    override func setUp() {
        super.setUp()
        fixRepo = MockFixRepository()
        completionRepo = MockFixCompletionRepository()
        userRepo = MockUserRepository()
        analyticsRepo = MockAnalyticsEventRepository()
        service = DailyFixService(
            fixRepository: fixRepo,
            fixCompletionRepository: completionRepo,
            userRepository: userRepo,
            analyticsEventRepository: analyticsRepo
        )
    }

    // MARK: - Helpers

    private func seedUser(withBugPriority: Bool = true) async throws {
        let user = UserProfile(
            id: userId,
            bugPriorities: withBugPriority ? [BugPriority(bugId: bugId, rank: 1)] : []
        )
        try await userRepo.save(user)
    }

    private func seedFix(id: UUID = UUID(), type: FixType = .daily) async throws -> Fix {
        let fix = Fix(
            id: id,
            bugId: bugId,
            type: type,
            severity: .medium,
            prompt: "Test prompt",
            validation: "Test validation"
        )
        try await fixRepo.save(fix)
        return fix
    }

    // MARK: - Tests

    func test_DailyFixService_assignsOnePerDay() async throws {
        try await seedUser()
        let fix = try await seedFix()

        let first = try await service.assignDailyFix()
        XCTAssertNotNil(first)
        XCTAssertEqual(first?.fixId, fix.id)
        XCTAssertEqual(first?.userId, userId)
        XCTAssertEqual(first?.outcome, .pending)

        // Second call same day returns same completion
        let second = try await service.assignDailyFix()
        XCTAssertEqual(first?.id, second?.id)
    }

    func test_DailyFixService_returnsNilWithoutUser() async throws {
        let result = try await service.assignDailyFix()
        XCTAssertNil(result)
    }

    func test_DailyFixService_returnsNilWithoutPriorities() async throws {
        try await seedUser(withBugPriority: false)
        let result = try await service.assignDailyFix()
        XCTAssertNil(result)
    }

    func test_DailyFixService_excludesCompletedFixes() async throws {
        try await seedUser()
        let fix1 = try await seedFix()
        let fix2 = try await seedFix(id: UUID())

        // Complete fix1
        let completion = FixCompletion(fixId: fix1.id, userId: userId, outcome: .applied)
        try await completionRepo.save(completion)

        let result = try await service.assignDailyFix()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.fixId, fix2.id)
    }

    func test_DailyFixService_markOutcome_setsApplied() async throws {
        try await seedUser()
        _ = try await seedFix()

        let assigned = try await service.assignDailyFix()
        XCTAssertNotNil(assigned)

        try await service.markOutcome(assigned!.id, outcome: .applied)

        let updated = try await completionRepo.getById(assigned!.id)
        XCTAssertEqual(updated?.outcome, .applied)
        XCTAssertNotNil(updated?.completedAt)
    }

    func test_DailyFixService_markOutcome_logsAnalyticsEvent() async throws {
        try await seedUser()
        _ = try await seedFix()

        let assigned = try await service.assignDailyFix()!
        try await service.markOutcome(assigned.id, outcome: .applied)

        let events = try await analyticsRepo.getForUser(userId)
        let appliedEvents = events.filter { $0.eventType == .fixApplied }
        XCTAssertEqual(appliedEvents.count, 1)
    }

    func test_DailyFixService_getTodaysFix_returnsNilWhenEmpty() async throws {
        try await seedUser()
        let result = try await service.getTodaysFix()
        XCTAssertNil(result)
    }

    // MARK: - Complexity Progression

    func test_maxComplexity_week1_returns2() {
        XCTAssertEqual(DailyFixService.maxComplexity(forCompletedFixes: 0), 2)
        XCTAssertEqual(DailyFixService.maxComplexity(forCompletedFixes: 6), 2)
    }

    func test_maxComplexity_week2to3_returns3() {
        XCTAssertEqual(DailyFixService.maxComplexity(forCompletedFixes: 7), 3)
        XCTAssertEqual(DailyFixService.maxComplexity(forCompletedFixes: 20), 3)
    }

    func test_maxComplexity_week4to6_returns4() {
        XCTAssertEqual(DailyFixService.maxComplexity(forCompletedFixes: 21), 4)
        XCTAssertEqual(DailyFixService.maxComplexity(forCompletedFixes: 41), 4)
    }

    func test_maxComplexity_week7plus_returns5() {
        XCTAssertEqual(DailyFixService.maxComplexity(forCompletedFixes: 42), 5)
        XCTAssertEqual(DailyFixService.maxComplexity(forCompletedFixes: 100), 5)
    }

    // MARK: - Fix Complexity Values

    func test_Fix_complexity_simpleTypesAre1or2() {
        let standard = Fix(bugId: UUID(), type: .daily, severity: .low, interactionType: .standard, prompt: "t", validation: "v")
        let counter = Fix(bugId: UUID(), type: .daily, severity: .low, interactionType: .counter, prompt: "t", validation: "v")
        let abstain = Fix(bugId: UUID(), type: .daily, severity: .low, interactionType: .abstain, prompt: "t", validation: "v")
        let observation = Fix(bugId: UUID(), type: .daily, severity: .low, interactionType: .observation, prompt: "t", validation: "v")

        XCTAssertEqual(standard.complexity, 1)
        XCTAssertEqual(counter.complexity, 1)
        XCTAssertEqual(abstain.complexity, 2)
        XCTAssertEqual(observation.complexity, 2)
    }

    func test_Fix_complexity_advancedTypesAre4or5() {
        let scenario = Fix(bugId: UUID(), type: .daily, severity: .low, interactionType: .scenario, prompt: "t", validation: "v")
        let multiStep = Fix(bugId: UUID(), type: .daily, severity: .low, interactionType: .multiStep, prompt: "t", validation: "v")
        let audit = Fix(bugId: UUID(), type: .daily, severity: .low, interactionType: .audit, prompt: "t", validation: "v")

        XCTAssertEqual(scenario.complexity, 4)
        XCTAssertEqual(multiStep.complexity, 4)
        XCTAssertEqual(audit.complexity, 5)
    }
}
