import XCTest
@testable import EgoFix

@MainActor
final class WeeklyDiagnosticServiceTests: XCTestCase {

    private var diagnosticRepo: MockWeeklyDiagnosticRepository!
    private var bugRepo: MockBugRepository!
    private var userRepo: MockUserRepository!
    private var analyticsRepo: MockAnalyticsEventRepository!
    private var service: WeeklyDiagnosticService!

    private let userId = UUID()

    override func setUp() {
        super.setUp()
        diagnosticRepo = MockWeeklyDiagnosticRepository()
        bugRepo = MockBugRepository()
        userRepo = MockUserRepository()
        analyticsRepo = MockAnalyticsEventRepository()
        service = WeeklyDiagnosticService(
            weeklyDiagnosticRepository: diagnosticRepo,
            bugRepository: bugRepo,
            userRepository: userRepo,
            analyticsEventRepository: analyticsRepo
        )
    }

    private func seedUser() async throws {
        let user = UserProfile(id: userId)
        try await userRepo.save(user)
    }

    private func seedActiveBugs(count: Int) async throws -> [Bug] {
        var bugs: [Bug] = []
        for i in 0..<count {
            let bug = Bug(
                slug: "bug-\(i)",
                title: "Bug \(i)",
                description: "Description \(i)",
                isActive: true,
                status: .active
            )
            try await bugRepo.save(bug)
            bugs.append(bug)
        }
        return bugs
    }

    // MARK: - getBugsForDiagnostic Tests

    func test_WeeklyDiagnostic_capsAtThreeBugs() async throws {
        try await seedUser()
        _ = try await seedActiveBugs(count: 5)

        let result = try await service.getBugsForDiagnostic()
        XCTAssertEqual(result.count, 3)
    }

    func test_WeeklyDiagnostic_returnsAllIfThreeOrFewer() async throws {
        try await seedUser()
        _ = try await seedActiveBugs(count: 2)

        let result = try await service.getBugsForDiagnostic()
        XCTAssertEqual(result.count, 2)
    }

    func test_WeeklyDiagnostic_rotatesBugs() async throws {
        try await seedUser()
        let bugs = try await seedActiveBugs(count: 5)

        // Submit a diagnostic that assessed the first 3 bugs
        let responses = bugs.prefix(3).map {
            BugDiagnosticResponse(bugId: $0.id, intensity: .present, primaryContext: nil)
        }

        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!

        let diagnostic = WeeklyDiagnostic(
            userId: userId,
            weekStarting: startOfWeek,
            responses: responses
        )
        try await diagnosticRepo.save(diagnostic)

        // Next diagnostic should prioritize unassessed bugs
        let result = try await service.getBugsForDiagnostic()
        let resultIds = Set(result.map { $0.id })
        let unassessedIds = Set(bugs.suffix(2).map { $0.id })

        XCTAssertTrue(unassessedIds.isSubset(of: resultIds))
    }

    // MARK: - submitDiagnostic Tests

    func test_WeeklyDiagnostic_submitSavesDiagnostic() async throws {
        try await seedUser()

        let responses = [
            BugDiagnosticResponse(bugId: UUID(), intensity: .loud, primaryContext: .work)
        ]

        try await service.submitDiagnostic(responses: responses)

        let diagnostics = try await diagnosticRepo.getForUser(userId)
        XCTAssertEqual(diagnostics.count, 1)
        XCTAssertEqual(diagnostics.first?.responses.count, 1)
        XCTAssertEqual(diagnostics.first?.responses.first?.intensity, .loud)
    }

    func test_WeeklyDiagnostic_submitLogsAnalytics() async throws {
        try await seedUser()

        try await service.submitDiagnostic(responses: [])

        let events = try await analyticsRepo.getForUser(userId)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.eventType, .weeklyCompleted)
    }

    func test_WeeklyDiagnostic_returnsEmptyWithoutUser() async throws {
        let bugs = try await service.getBugsForDiagnostic()
        XCTAssertTrue(bugs.isEmpty)
    }
}
