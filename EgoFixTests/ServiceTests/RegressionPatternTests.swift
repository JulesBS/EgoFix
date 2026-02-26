import XCTest
@testable import EgoFix

@MainActor
final class RegressionPatternTests: XCTestCase {

    var bugRepo: MockBugRepository!
    var diagnosticRepo: MockWeeklyDiagnosticRepository!
    var crashRepo: MockCrashRepository!
    var patternRepo: MockPatternRepository!

    override func setUp() async throws {
        bugRepo = MockBugRepository()
        diagnosticRepo = MockWeeklyDiagnosticRepository()
        crashRepo = MockCrashRepository()
        patternRepo = MockPatternRepository()
    }

    func test_BugLifecycleService_createsRegressionPattern() async throws {
        let userId = UUID()
        let bugId = UUID()

        // Create a resolved bug
        let bug = Bug(
            id: bugId,
            slug: "need-to-control",
            title: "Need to control",
            bugDescription: "A test bug",
            status: .resolved,
            isActive: false
        )
        bug.stableAt = Calendar.current.date(byAdding: .weekOfYear, value: -6, to: Date())
        try await bugRepo.save(bug)

        // Create crashes that trigger regression (3+ in 14 days)
        for i in 0..<4 {
            let crashDate = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            let crash = Crash(
                userId: userId,
                bugId: bugId,
                situation: "Test situation",
                trigger: "Test trigger"
            )
            crash.crashedAt = crashDate
            try await crashRepo.save(crash)
        }

        let service = BugLifecycleService(
            bugRepository: bugRepo,
            weeklyDiagnosticRepository: diagnosticRepo,
            crashRepository: crashRepo,
            patternRepository: patternRepo
        )

        let didRegress = try await service.checkForRegression(bugId: bugId, userId: userId)

        XCTAssertTrue(didRegress)

        // Verify a regression pattern was created
        let patterns = try await patternRepo.getForUser(userId)
        XCTAssertEqual(patterns.count, 1)

        let pattern = patterns.first!
        XCTAssertEqual(pattern.patternType, .regression)
        XCTAssertEqual(pattern.severity, .alert)
        XCTAssertTrue(pattern.title.contains("Need to control"))
        XCTAssertTrue(pattern.body.contains("4 times"))
    }

    func test_BugLifecycleService_noPatternIfNotEnoughCrashes() async throws {
        let userId = UUID()
        let bugId = UUID()

        // Create a resolved bug
        let bug = Bug(
            id: bugId,
            slug: "need-to-control",
            title: "Need to control",
            bugDescription: "A test bug",
            status: .resolved,
            isActive: false
        )
        try await bugRepo.save(bug)

        // Create only 2 crashes (below threshold)
        for i in 0..<2 {
            let crashDate = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            let crash = Crash(
                userId: userId,
                bugId: bugId,
                situation: "Test situation",
                trigger: "Test trigger"
            )
            crash.crashedAt = crashDate
            try await crashRepo.save(crash)
        }

        let service = BugLifecycleService(
            bugRepository: bugRepo,
            weeklyDiagnosticRepository: diagnosticRepo,
            crashRepository: crashRepo,
            patternRepository: patternRepo
        )

        let didRegress = try await service.checkForRegression(bugId: bugId, userId: userId)

        XCTAssertFalse(didRegress)

        // No pattern should be created
        let patterns = try await patternRepo.getForUser(userId)
        XCTAssertTrue(patterns.isEmpty)
    }

    func test_RegressionPattern_hasCorrectRecommendations() {
        let pattern = DetectedPattern(
            userId: UUID(),
            patternType: .regression,
            severity: .alert,
            title: "Bug crashed again",
            body: "Test body",
            relatedBugIds: [],
            dataPoints: 3
        )

        let recommendations = RecommendationEngine.generateRecommendations(for: pattern)

        XCTAssertEqual(recommendations.count, 2)
        XCTAssertEqual(recommendations[0].title, "It happens")
        XCTAssertEqual(recommendations[1].title, "Back to basics")
    }
}
