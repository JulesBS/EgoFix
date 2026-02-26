import XCTest
@testable import EgoFix

@MainActor
final class CrashServiceTests: XCTestCase {

    private var crashRepo: MockCrashRepository!
    private var fixRepo: MockFixRepository!
    private var completionRepo: MockFixCompletionRepository!
    private var userRepo: MockUserRepository!
    private var analyticsRepo: MockAnalyticsEventRepository!
    private var service: CrashService!

    private let userId = UUID()
    private let bugId = UUID()

    override func setUp() {
        super.setUp()
        crashRepo = MockCrashRepository()
        fixRepo = MockFixRepository()
        completionRepo = MockFixCompletionRepository()
        userRepo = MockUserRepository()
        analyticsRepo = MockAnalyticsEventRepository()
        service = CrashService(
            crashRepository: crashRepo,
            fixRepository: fixRepo,
            fixCompletionRepository: completionRepo,
            userRepository: userRepo,
            analyticsEventRepository: analyticsRepo
        )
    }

    private func seedUser() async throws {
        let user = UserProfile(id: userId)
        try await userRepo.save(user)
    }

    // MARK: - logCrash Tests

    func test_CrashService_logsCrash() async throws {
        try await seedUser()

        let crash = try await service.logCrash(bugId: bugId, note: "Lost it")
        XCTAssertNotNil(crash)
        XCTAssertEqual(crash?.userId, userId)
        XCTAssertEqual(crash?.bugId, bugId)
        XCTAssertEqual(crash?.note, "Lost it")
        XCTAssertNil(crash?.rebootedAt)
    }

    func test_CrashService_logsAnalyticsEvent() async throws {
        try await seedUser()

        _ = try await service.logCrash(bugId: bugId, note: nil)

        let events = try await analyticsRepo.getForUser(userId)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.eventType, .crashLogged)
        XCTAssertEqual(events.first?.bugId, bugId)
    }

    func test_CrashService_returnsNilWithoutUser() async throws {
        let crash = try await service.logCrash(bugId: bugId, note: nil)
        XCTAssertNil(crash)
    }

    // MARK: - assignQuickFix Tests

    func test_CrashService_triggersQuickFix() async throws {
        try await seedUser()

        let quickFix = Fix(
            bugId: bugId,
            type: .quickFix,
            severity: .low,
            prompt: "Quick recovery",
            validation: "Do it"
        )
        try await fixRepo.save(quickFix)

        let crash = try await service.logCrash(bugId: bugId, note: nil)!
        let completion = try await service.assignQuickFix(for: crash.id)
        XCTAssertNotNil(completion)
        XCTAssertEqual(completion?.fixId, quickFix.id)
        XCTAssertEqual(completion?.userId, userId)
    }

    func test_CrashService_quickFixReturnsNilWithoutBugId() async throws {
        try await seedUser()

        let crash = try await service.logCrash(bugId: nil, note: nil)!
        let completion = try await service.assignQuickFix(for: crash.id)
        XCTAssertNil(completion)
    }

    // MARK: - reboot Tests

    func test_CrashService_rebootSetsTimestamp() async throws {
        try await seedUser()

        let crash = try await service.logCrash(bugId: bugId, note: nil)!
        XCTAssertNil(crash.rebootedAt)

        try await service.reboot(crashId: crash.id)

        let updated = try await crashRepo.getById(crash.id)
        XCTAssertNotNil(updated?.rebootedAt)
    }

    func test_CrashService_rebootLogsAnalyticsEvent() async throws {
        try await seedUser()

        let crash = try await service.logCrash(bugId: bugId, note: nil)!
        try await service.reboot(crashId: crash.id)

        let events = try await analyticsRepo.getForUser(userId)
        let rebootEvents = events.filter { $0.eventType == .crashRebooted }
        XCTAssertEqual(rebootEvents.count, 1)
    }

    // MARK: - getUnrebootedCrashes Tests

    func test_CrashService_getUnrebootedCrashes() async throws {
        try await seedUser()

        let crash1 = try await service.logCrash(bugId: bugId, note: nil)!
        let crash2 = try await service.logCrash(bugId: bugId, note: nil)!
        try await service.reboot(crashId: crash1.id)

        let unrebooted = try await service.getUnrebootedCrashes()
        XCTAssertEqual(unrebooted.count, 1)
        XCTAssertEqual(unrebooted.first?.id, crash2.id)
    }
}
