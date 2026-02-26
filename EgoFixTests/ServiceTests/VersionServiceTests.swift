import XCTest
@testable import EgoFix

@MainActor
final class VersionServiceTests: XCTestCase {

    private var userRepo: MockUserRepository!
    private var versionRepo: MockVersionEntryRepository!
    private var completionRepo: MockFixCompletionRepository!
    private var service: VersionService!

    private let userId = UUID()

    override func setUp() {
        super.setUp()
        userRepo = MockUserRepository()
        versionRepo = MockVersionEntryRepository()
        completionRepo = MockFixCompletionRepository()
        service = VersionService(
            userRepository: userRepo,
            versionEntryRepository: versionRepo,
            fixCompletionRepository: completionRepo
        )
    }

    // MARK: - Helpers

    private func seedUser(version: String = "1.0") async throws {
        let user = UserProfile(id: userId, currentVersion: version)
        try await userRepo.save(user)
    }

    private func seedAppliedCompletions(count: Int) async throws {
        for _ in 0..<count {
            let completion = FixCompletion(
                fixId: UUID(),
                userId: userId,
                outcome: .applied,
                completedAt: Date()
            )
            try await completionRepo.save(completion)
        }
    }

    // MARK: - parseVersion Tests

    func test_VersionService_parseVersion() {
        let result = service.parseVersion("2.5")
        XCTAssertEqual(result.major, 2)
        XCTAssertEqual(result.minor, 5)
    }

    func test_VersionService_parseVersion_defaultsTo1_0() {
        let result = service.parseVersion("invalid")
        XCTAssertEqual(result.major, 1)
        XCTAssertEqual(result.minor, 0)
    }

    // MARK: - incrementVersion Tests

    func test_VersionService_incrementVersion_minorToMinor() {
        let result = service.incrementVersion(major: 1, minor: 0)
        XCTAssertEqual(result, "1.1")
    }

    func test_VersionService_incrementVersion_minorToMajor() {
        let result = service.incrementVersion(major: 1, minor: 9)
        XCTAssertEqual(result, "2.0")
    }

    // MARK: - checkAndIncrementVersion Tests

    func test_VersionService_incrementsOnMilestone() async throws {
        try await seedUser(version: "1.0")
        try await seedAppliedCompletions(count: 7)

        let entry = try await service.checkAndIncrementVersion()
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.version, "1.1")
        XCTAssertEqual(entry?.changeType, .minorUpdate)

        let user = try await userRepo.get()
        XCTAssertEqual(user?.currentVersion, "1.1")
    }

    func test_VersionService_noIncrementBelowThreshold() async throws {
        try await seedUser(version: "1.0")
        try await seedAppliedCompletions(count: 5)

        let entry = try await service.checkAndIncrementVersion()
        XCTAssertNil(entry)
    }

    func test_VersionService_majorBumpAt70Fixes() async throws {
        try await seedUser(version: "1.0")
        try await seedAppliedCompletions(count: 70)

        let entry = try await service.checkAndIncrementVersion()
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.version, "2.0")
        XCTAssertEqual(entry?.changeType, .majorUpdate)
    }

    func test_VersionService_getCurrentVersion_defaultsTo1_0() async throws {
        let version = try await service.getCurrentVersion()
        XCTAssertEqual(version, "1.0")
    }
}
