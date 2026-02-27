import XCTest
@testable import EgoFix

@MainActor
final class BugLifecycleServiceTests: XCTestCase {
    private var sut: BugLifecycleService!
    private var mockBugRepository: MockBugRepository!
    private var mockWeeklyDiagnosticRepository: MockWeeklyDiagnosticRepository!
    private var mockCrashRepository: MockCrashRepository!

    override func setUp() async throws {
        try await super.setUp()
        mockBugRepository = MockBugRepository()
        mockWeeklyDiagnosticRepository = MockWeeklyDiagnosticRepository()
        mockCrashRepository = MockCrashRepository()

        sut = BugLifecycleService(
            bugRepository: mockBugRepository,
            weeklyDiagnosticRepository: mockWeeklyDiagnosticRepository,
            crashRepository: mockCrashRepository
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockBugRepository = nil
        mockWeeklyDiagnosticRepository = nil
        mockCrashRepository = nil
        try await super.tearDown()
    }

    // MARK: - Activate Tests

    func test_activate_fromIdentified_transitionsToActive() async throws {
        // Arrange
        let bug = Bug(
            slug: "need-to-be-right",
            title: "Need to be right",
            description: "Test bug",
            status: .identified
        )
        try await mockBugRepository.save(bug)

        // Act
        try await sut.activate(bug.id)

        // Assert
        let updatedBug = try await mockBugRepository.getById(bug.id)
        XCTAssertEqual(updatedBug?.status, .active)
        XCTAssertTrue(updatedBug?.isActive ?? false)
        XCTAssertNotNil(updatedBug?.activatedAt)
    }

    func test_activate_fromActive_doesNothing() async throws {
        // Arrange
        let originalDate = Date().addingTimeInterval(-86400)
        let bug = Bug(
            slug: "need-to-be-right",
            title: "Need to be right",
            description: "Test bug",
            isActive: true,
            status: .active,
            activatedAt: originalDate
        )
        try await mockBugRepository.save(bug)

        // Act
        try await sut.activate(bug.id)

        // Assert
        let updatedBug = try await mockBugRepository.getById(bug.id)
        XCTAssertEqual(updatedBug?.activatedAt, originalDate)
    }

    func test_activate_nonexistentBug_doesNothing() async throws {
        // Act & Assert - should not throw
        try await sut.activate(UUID())
    }

    // MARK: - Resolve Tests

    func test_resolve_fromStable_transitionsToResolved() async throws {
        // Arrange
        let bug = Bug(
            slug: "need-to-be-right",
            title: "Need to be right",
            description: "Test bug",
            isActive: true,
            status: .stable,
            stableAt: Date()
        )
        try await mockBugRepository.save(bug)

        // Act
        try await sut.resolve(bug.id)

        // Assert
        let updatedBug = try await mockBugRepository.getById(bug.id)
        XCTAssertEqual(updatedBug?.status, .resolved)
        XCTAssertFalse(updatedBug?.isActive ?? true)
        XCTAssertNotNil(updatedBug?.resolvedAt)
    }

    func test_resolve_fromActive_doesNothing() async throws {
        // Arrange
        let bug = Bug(
            slug: "need-to-be-right",
            title: "Need to be right",
            description: "Test bug",
            isActive: true,
            status: .active
        )
        try await mockBugRepository.save(bug)

        // Act
        try await sut.resolve(bug.id)

        // Assert
        let updatedBug = try await mockBugRepository.getById(bug.id)
        XCTAssertEqual(updatedBug?.status, .active)
        XCTAssertNil(updatedBug?.resolvedAt)
    }

    // MARK: - Reactivate Tests

    func test_reactivate_fromResolved_transitionsToActive() async throws {
        // Arrange
        let bug = Bug(
            slug: "need-to-be-right",
            title: "Need to be right",
            description: "Test bug",
            isActive: false,
            status: .resolved,
            stableAt: Date().addingTimeInterval(-86400 * 7),
            resolvedAt: Date()
        )
        try await mockBugRepository.save(bug)

        // Act
        try await sut.reactivate(bug.id)

        // Assert
        let updatedBug = try await mockBugRepository.getById(bug.id)
        XCTAssertEqual(updatedBug?.status, .active)
        XCTAssertTrue(updatedBug?.isActive ?? false)
        XCTAssertNil(updatedBug?.resolvedAt)
        XCTAssertNil(updatedBug?.stableAt)
    }

    func test_reactivate_fromStable_doesNothing() async throws {
        // Arrange
        let bug = Bug(
            slug: "need-to-be-right",
            title: "Need to be right",
            description: "Test bug",
            isActive: true,
            status: .stable
        )
        try await mockBugRepository.save(bug)

        // Act
        try await sut.reactivate(bug.id)

        // Assert
        let updatedBug = try await mockBugRepository.getById(bug.id)
        XCTAssertEqual(updatedBug?.status, .stable)
    }

    // MARK: - Deactivate Tests

    func test_deactivate_clearsAllTimestampsAndStatus() async throws {
        // Arrange
        let bug = Bug(
            slug: "need-to-be-right",
            title: "Need to be right",
            description: "Test bug",
            isActive: true,
            status: .active,
            activatedAt: Date(),
            stableAt: Date(),
            resolvedAt: Date()
        )
        try await mockBugRepository.save(bug)

        // Act
        try await sut.deactivate(bug.id)

        // Assert
        let updatedBug = try await mockBugRepository.getById(bug.id)
        XCTAssertEqual(updatedBug?.status, .identified)
        XCTAssertFalse(updatedBug?.isActive ?? true)
        XCTAssertNil(updatedBug?.activatedAt)
        XCTAssertNil(updatedBug?.stableAt)
        XCTAssertNil(updatedBug?.resolvedAt)
    }

    // MARK: - Stability Transition Tests

    func test_checkForStabilityTransition_with4QuietWeeks_transitionsToStable() async throws {
        // Arrange
        let userId = UUID()
        let bugId = UUID()

        let bug = Bug(
            id: bugId,
            slug: "need-to-be-right",
            title: "Need to be right",
            description: "Test bug",
            isActive: true,
            status: .active
        )
        try await mockBugRepository.save(bug)

        // Create 4 weeks of quiet diagnostics
        for weekOffset in 0..<4 {
            let diagnostic = WeeklyDiagnostic(
                userId: userId,
                weekStarting: Date().addingTimeInterval(TimeInterval(-7 * 86400 * weekOffset)),
                responses: [
                    BugDiagnosticResponse(bugId: bugId, intensity: .quiet, primaryContext: nil)
                ],
                completedAt: Date().addingTimeInterval(TimeInterval(-7 * 86400 * weekOffset))
            )
            try await mockWeeklyDiagnosticRepository.save(diagnostic)
        }

        // Act
        let result = try await sut.checkForStabilityTransition(bugId: bugId, userId: userId)

        // Assert
        XCTAssertTrue(result)
        let updatedBug = try await mockBugRepository.getById(bugId)
        XCTAssertEqual(updatedBug?.status, .stable)
        XCTAssertNotNil(updatedBug?.stableAt)
    }

    func test_checkForStabilityTransition_withLessThan4Weeks_returnsFalse() async throws {
        // Arrange
        let userId = UUID()
        let bugId = UUID()

        let bug = Bug(
            id: bugId,
            slug: "need-to-be-right",
            title: "Need to be right",
            description: "Test bug",
            isActive: true,
            status: .active
        )
        try await mockBugRepository.save(bug)

        // Only 3 weeks of quiet diagnostics
        for weekOffset in 0..<3 {
            let diagnostic = WeeklyDiagnostic(
                userId: userId,
                weekStarting: Date().addingTimeInterval(TimeInterval(-7 * 86400 * weekOffset)),
                responses: [
                    BugDiagnosticResponse(bugId: bugId, intensity: .quiet, primaryContext: nil)
                ],
                completedAt: Date().addingTimeInterval(TimeInterval(-7 * 86400 * weekOffset))
            )
            try await mockWeeklyDiagnosticRepository.save(diagnostic)
        }

        // Act
        let result = try await sut.checkForStabilityTransition(bugId: bugId, userId: userId)

        // Assert
        XCTAssertFalse(result)
        let updatedBug = try await mockBugRepository.getById(bugId)
        XCTAssertEqual(updatedBug?.status, .active)
    }

    func test_checkForStabilityTransition_withNonQuietWeek_returnsFalse() async throws {
        // Arrange
        let userId = UUID()
        let bugId = UUID()

        let bug = Bug(
            id: bugId,
            slug: "need-to-be-right",
            title: "Need to be right",
            description: "Test bug",
            isActive: true,
            status: .active
        )
        try await mockBugRepository.save(bug)

        // 4 weeks but one is "present" not "quiet"
        for weekOffset in 0..<4 {
            let intensity: BugIntensity = weekOffset == 2 ? .present : .quiet
            let diagnostic = WeeklyDiagnostic(
                userId: userId,
                weekStarting: Date().addingTimeInterval(TimeInterval(-7 * 86400 * weekOffset)),
                responses: [
                    BugDiagnosticResponse(bugId: bugId, intensity: intensity, primaryContext: nil)
                ],
                completedAt: Date().addingTimeInterval(TimeInterval(-7 * 86400 * weekOffset))
            )
            try await mockWeeklyDiagnosticRepository.save(diagnostic)
        }

        // Act
        let result = try await sut.checkForStabilityTransition(bugId: bugId, userId: userId)

        // Assert
        XCTAssertFalse(result)
        let updatedBug = try await mockBugRepository.getById(bugId)
        XCTAssertEqual(updatedBug?.status, .active)
    }

    func test_checkForStabilityTransition_nonActiveBug_returnsFalse() async throws {
        // Arrange
        let userId = UUID()
        let bugId = UUID()

        let bug = Bug(
            id: bugId,
            slug: "need-to-be-right",
            title: "Need to be right",
            description: "Test bug",
            status: .identified
        )
        try await mockBugRepository.save(bug)

        // Act
        let result = try await sut.checkForStabilityTransition(bugId: bugId, userId: userId)

        // Assert
        XCTAssertFalse(result)
    }

    // MARK: - Regression Detection Tests

    func test_checkForRegression_with3RecentCrashes_triggersRegression() async throws {
        // Arrange
        let userId = UUID()
        let bugId = UUID()

        let bug = Bug(
            id: bugId,
            slug: "need-to-be-right",
            title: "Need to be right",
            description: "Test bug",
            isActive: false,
            status: .resolved,
            resolvedAt: Date().addingTimeInterval(-86400 * 30)
        )
        try await mockBugRepository.save(bug)

        // Create 3 recent crashes for this bug (within 14 days)
        for dayOffset in 0..<3 {
            let crash = Crash(
                userId: userId,
                bugId: bugId,
                crashedAt: Date().addingTimeInterval(TimeInterval(-dayOffset * 86400))
            )
            try await mockCrashRepository.save(crash)
        }

        // Act
        let result = try await sut.checkForRegression(bugId: bugId, userId: userId)

        // Assert
        XCTAssertTrue(result)
        let updatedBug = try await mockBugRepository.getById(bugId)
        XCTAssertEqual(updatedBug?.status, .active)
        XCTAssertTrue(updatedBug?.isActive ?? false)
        XCTAssertNil(updatedBug?.resolvedAt)
    }

    func test_checkForRegression_withOldCrashes_doesNotTrigger() async throws {
        // Arrange
        let userId = UUID()
        let bugId = UUID()

        let bug = Bug(
            id: bugId,
            slug: "need-to-be-right",
            title: "Need to be right",
            description: "Test bug",
            isActive: false,
            status: .resolved,
            resolvedAt: Date().addingTimeInterval(-86400 * 30)
        )
        try await mockBugRepository.save(bug)

        // Create 3 crashes but older than 14 days
        for dayOffset in 0..<3 {
            let crash = Crash(
                userId: userId,
                bugId: bugId,
                crashedAt: Date().addingTimeInterval(TimeInterval(-(20 + dayOffset) * 86400))
            )
            try await mockCrashRepository.save(crash)
        }

        // Act
        let result = try await sut.checkForRegression(bugId: bugId, userId: userId)

        // Assert
        XCTAssertFalse(result)
        let updatedBug = try await mockBugRepository.getById(bugId)
        XCTAssertEqual(updatedBug?.status, .resolved)
    }

    func test_checkForRegression_withFewerThan3Crashes_doesNotTrigger() async throws {
        // Arrange
        let userId = UUID()
        let bugId = UUID()

        let bug = Bug(
            id: bugId,
            slug: "need-to-be-right",
            title: "Need to be right",
            description: "Test bug",
            isActive: false,
            status: .resolved,
            resolvedAt: Date().addingTimeInterval(-86400 * 30)
        )
        try await mockBugRepository.save(bug)

        // Only 2 recent crashes
        for dayOffset in 0..<2 {
            let crash = Crash(
                userId: userId,
                bugId: bugId,
                crashedAt: Date().addingTimeInterval(TimeInterval(-dayOffset * 86400))
            )
            try await mockCrashRepository.save(crash)
        }

        // Act
        let result = try await sut.checkForRegression(bugId: bugId, userId: userId)

        // Assert
        XCTAssertFalse(result)
        let updatedBug = try await mockBugRepository.getById(bugId)
        XCTAssertEqual(updatedBug?.status, .resolved)
    }

    func test_checkForRegression_nonResolvedBug_returnsFalse() async throws {
        // Arrange
        let userId = UUID()
        let bugId = UUID()

        let bug = Bug(
            id: bugId,
            slug: "need-to-be-right",
            title: "Need to be right",
            description: "Test bug",
            isActive: true,
            status: .active
        )
        try await mockBugRepository.save(bug)

        // Act
        let result = try await sut.checkForRegression(bugId: bugId, userId: userId)

        // Assert
        XCTAssertFalse(result)
    }

    // MARK: - Run Lifecycle Checks Tests

    func test_runLifecycleChecks_detectsMultipleTransitions() async throws {
        // Arrange
        let userId = UUID()
        let activeBugId = UUID()
        let resolvedBugId = UUID()

        // Active bug that should become stable
        let activeBug = Bug(
            id: activeBugId,
            slug: "need-to-be-right",
            title: "Need to be right",
            description: "Test bug",
            isActive: true,
            status: .active
        )
        try await mockBugRepository.save(activeBug)

        // Create 4 weeks of quiet diagnostics for active bug
        for weekOffset in 0..<4 {
            let diagnostic = WeeklyDiagnostic(
                userId: userId,
                weekStarting: Date().addingTimeInterval(TimeInterval(-7 * 86400 * weekOffset)),
                responses: [
                    BugDiagnosticResponse(bugId: activeBugId, intensity: .quiet, primaryContext: nil)
                ],
                completedAt: Date().addingTimeInterval(TimeInterval(-7 * 86400 * weekOffset))
            )
            try await mockWeeklyDiagnosticRepository.save(diagnostic)
        }

        // Resolved bug that should regress
        let resolvedBug = Bug(
            id: resolvedBugId,
            slug: "need-to-impress",
            title: "Need to impress",
            description: "Test bug 2",
            isActive: false,
            status: .resolved,
            resolvedAt: Date().addingTimeInterval(-86400 * 30)
        )
        try await mockBugRepository.save(resolvedBug)

        // Create 3 recent crashes for resolved bug
        for dayOffset in 0..<3 {
            let crash = Crash(
                userId: userId,
                bugId: resolvedBugId,
                crashedAt: Date().addingTimeInterval(TimeInterval(-dayOffset * 86400))
            )
            try await mockCrashRepository.save(crash)
        }

        // Act
        let transitions = try await sut.runLifecycleChecks(userId: userId)

        // Assert
        XCTAssertEqual(transitions.count, 2)

        let stabilityTransition = transitions.first { $0.bugId == activeBugId }
        XCTAssertNotNil(stabilityTransition)
        XCTAssertEqual(stabilityTransition?.from, .active)
        XCTAssertEqual(stabilityTransition?.to, .stable)

        let regressionTransition = transitions.first { $0.bugId == resolvedBugId }
        XCTAssertNotNil(regressionTransition)
        XCTAssertEqual(regressionTransition?.from, .resolved)
        XCTAssertEqual(regressionTransition?.to, .active)
    }

    // MARK: - Lifecycle Info Tests

    func test_getLifecycleInfo_returnsCorrectInfo() async throws {
        // Arrange
        let activatedAt = Date().addingTimeInterval(-86400 * 30)
        let stableAt = Date().addingTimeInterval(-86400 * 7)
        let bug = Bug(
            slug: "need-to-be-right",
            title: "Need to be right",
            description: "Test bug description",
            isActive: true,
            status: .stable,
            activatedAt: activatedAt,
            stableAt: stableAt
        )

        // Act
        let info = sut.getLifecycleInfo(for: bug)

        // Assert
        XCTAssertEqual(info.slug, "need-to-be-right")
        XCTAssertEqual(info.title, "Need to be right")
        XCTAssertEqual(info.description, "Test bug description")
        XCTAssertEqual(info.status, .stable)
        XCTAssertEqual(info.activatedAt, activatedAt)
        XCTAssertEqual(info.stableAt, stableAt)
        XCTAssertNil(info.resolvedAt)
        XCTAssertEqual(info.statusLabel, "STABLE")
        XCTAssertEqual(info.statusComment, "// Hasn't fired in a while. Don't get comfortable.")
    }
}
