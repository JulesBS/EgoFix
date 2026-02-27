import XCTest
@testable import EgoFix

@MainActor
final class DiagnosticEngineTests: XCTestCase {

    var analyticsRepo: MockAnalyticsEventRepository!
    var diagnosticRepo: MockWeeklyDiagnosticRepository!
    var patternRepo: MockPatternRepository!
    var bugRepo: MockBugRepository!
    var userRepo: MockUserRepository!

    override func setUp() async throws {
        analyticsRepo = MockAnalyticsEventRepository()
        diagnosticRepo = MockWeeklyDiagnosticRepository()
        patternRepo = MockPatternRepository()
        bugRepo = MockBugRepository()
        userRepo = MockUserRepository()

        // Create a test user
        let user = UserProfile(id: UUID(), currentVersion: "1.0")
        try await userRepo.save(user)
    }

    // MARK: - Scheduling Tests

    func test_DiagnosticEngine_shouldRunIfNeverRun() async throws {
        let user = try await userRepo.get()!

        let engine = DiagnosticEngine(
            analyticsEventRepository: analyticsRepo,
            weeklyDiagnosticRepository: diagnosticRepo,
            patternRepository: patternRepo,
            bugRepository: bugRepo,
            userRepository: userRepo,
            detectors: []
        )

        let shouldRun = try await engine.shouldRunDiagnostics(for: user.id)
        XCTAssertTrue(shouldRun)
    }

    func test_DiagnosticEngine_shouldNotRunIfRunRecently() async throws {
        var user = try await userRepo.get()!
        user.lastDiagnosticsRunAt = Date()
        try await userRepo.save(user)

        let engine = DiagnosticEngine(
            analyticsEventRepository: analyticsRepo,
            weeklyDiagnosticRepository: diagnosticRepo,
            patternRepository: patternRepo,
            bugRepository: bugRepo,
            userRepository: userRepo,
            detectors: []
        )

        let shouldRun = try await engine.shouldRunDiagnostics(for: user.id)
        XCTAssertFalse(shouldRun)
    }

    func test_DiagnosticEngine_shouldRunIfOverSevenDays() async throws {
        var user = try await userRepo.get()!
        user.lastDiagnosticsRunAt = Calendar.current.date(byAdding: .day, value: -8, to: Date())
        try await userRepo.save(user)

        let engine = DiagnosticEngine(
            analyticsEventRepository: analyticsRepo,
            weeklyDiagnosticRepository: diagnosticRepo,
            patternRepository: patternRepo,
            bugRepository: bugRepo,
            userRepository: userRepo,
            detectors: []
        )

        let shouldRun = try await engine.shouldRunDiagnostics(for: user.id)
        XCTAssertTrue(shouldRun)
    }

    func test_DiagnosticEngine_updatesLastRunAfterDiagnostics() async throws {
        let user = try await userRepo.get()!
        XCTAssertNil(user.lastDiagnosticsRunAt)

        let engine = DiagnosticEngine(
            analyticsEventRepository: analyticsRepo,
            weeklyDiagnosticRepository: diagnosticRepo,
            patternRepository: patternRepo,
            bugRepository: bugRepo,
            userRepository: userRepo,
            detectors: []
        )

        _ = try await engine.runDiagnostics(for: user.id)

        let updatedUser = try await userRepo.get()!
        XCTAssertNotNil(updatedUser.lastDiagnosticsRunAt)
    }

    // MARK: - Cooldown Tests

    func test_DiagnosticEngine_respectsCooldown() async throws {
        let user = try await userRepo.get()!
        let bugId = UUID()

        // Create a bug for the detector to reference
        let bug = Bug(
            id: bugId,
            slug: "test-bug",
            title: "Test Bug",
            description: "A test bug",
            isActive: true,
            status: .active
        )
        try await bugRepo.save(bug)

        // Create a recent pattern of type .avoidance
        let recentPattern = DetectedPattern(
            userId: user.id,
            patternType: .avoidance,
            severity: .insight,
            title: "Existing Pattern",
            body: "Body",
            relatedBugIds: [bugId],
            dataPoints: 5
        )
        try await patternRepo.save(recentPattern)

        // Create events that would trigger avoidance detector
        for _ in 0..<5 {
            try await analyticsRepo.save(AnalyticsEvent(
                userId: user.id,
                eventType: .fixSkipped,
                bugId: bugId,
                dayOfWeek: 1,
                hourOfDay: 10
            ))
        }
        for _ in 0..<3 {
            try await analyticsRepo.save(AnalyticsEvent(
                userId: user.id,
                eventType: .fixApplied,
                bugId: bugId,
                dayOfWeek: 1,
                hourOfDay: 10
            ))
        }

        let engine = DiagnosticEngine(
            analyticsEventRepository: analyticsRepo,
            weeklyDiagnosticRepository: diagnosticRepo,
            patternRepository: patternRepo,
            bugRepository: bugRepo,
            userRepository: userRepo,
            detectors: [AvoidanceDetector()]
        )

        let detectedPatterns = try await engine.runDiagnostics(for: user.id)

        // Should NOT detect a new pattern because cooldown
        XCTAssertTrue(detectedPatterns.isEmpty)
    }

    // MARK: - Priority Tests

    func test_DiagnosticEngine_returnsPatternsInPriorityOrder() async throws {
        let user = try await userRepo.get()!

        // Create patterns with different severities
        let alertPattern = DetectedPattern(
            userId: user.id,
            patternType: .temporalCrash,
            severity: .alert,
            title: "Alert",
            body: "Body",
            relatedBugIds: [],
            dataPoints: 5
        )
        let insightPattern = DetectedPattern(
            userId: user.id,
            patternType: .avoidance,
            severity: .insight,
            title: "Insight",
            body: "Body",
            relatedBugIds: [],
            dataPoints: 5
        )
        let observationPattern = DetectedPattern(
            userId: user.id,
            patternType: .improvement,
            severity: .observation,
            title: "Observation",
            body: "Body",
            relatedBugIds: [],
            dataPoints: 5
        )

        // Save in random order
        try await patternRepo.save(observationPattern)
        try await patternRepo.save(alertPattern)
        try await patternRepo.save(insightPattern)

        let engine = DiagnosticEngine(
            analyticsEventRepository: analyticsRepo,
            weeklyDiagnosticRepository: diagnosticRepo,
            patternRepository: patternRepo,
            bugRepository: bugRepo,
            userRepository: userRepo,
            detectors: []
        )

        let topPattern = try await engine.getPatternToSurface(for: user.id)

        // Alert should be first priority
        XCTAssertEqual(topPattern?.severity, .alert)
    }
}
