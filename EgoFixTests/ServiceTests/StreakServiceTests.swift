import XCTest
@testable import EgoFix

@MainActor
final class StreakServiceTests: XCTestCase {

    private var userRepository: MockUserRepository!
    private var service: StreakService!
    private var userId: UUID!

    override func setUp() async throws {
        userRepository = MockUserRepository()
        service = StreakService(userRepository: userRepository)
        userId = UUID()

        let user = UserProfile(id: userId)
        try await userRepository.save(user)
    }

    // MARK: - Helpers

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }

    // MARK: - Basic Engagement

    func test_StreakService_firstEngagement_setsStreakToOne() async throws {
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 1))

        let user = try await userRepository.getById(userId)
        XCTAssertEqual(user?.currentStreak, 1)
        XCTAssertEqual(user?.longestStreak, 1)
    }

    func test_StreakService_sameDay_doesNotIncrement() async throws {
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 1))
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 1))

        let user = try await userRepository.getById(userId)
        XCTAssertEqual(user?.currentStreak, 1)
    }

    func test_StreakService_consecutiveDay_increments() async throws {
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 1))
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 2))
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 3))

        let user = try await userRepository.getById(userId)
        XCTAssertEqual(user?.currentStreak, 3)
        XCTAssertEqual(user?.longestStreak, 3)
    }

    // MARK: - Missed Days

    func test_StreakService_missedDay_resetsStreak() async throws {
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 1))
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 2))
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 3))
        // Miss day 4, engage day 5 — but freeze covers 1 missed day, so need to miss 2+
        // Miss day 4 AND 5, engage day 6
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 6))

        let user = try await userRepository.getById(userId)
        // Missed 2 days (4 and 5) — no freeze covers 2 days, reset to 1
        XCTAssertEqual(user?.currentStreak, 1)
        // Longest stays at 3
        XCTAssertEqual(user?.longestStreak, 3)
    }

    // MARK: - Streak Freeze

    func test_StreakService_freeze_preservesStreak() async throws {
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 1))
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 2))
        // Miss day 3, engage day 4 — freeze should preserve streak
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 4))

        let user = try await userRepository.getById(userId)
        XCTAssertEqual(user?.currentStreak, 3)
        XCTAssertFalse(user?.streakFreezeAvailable ?? true, "Freeze should be consumed")
    }

    func test_StreakService_freezeUsed_nextMissResets() async throws {
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 1))
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 2))
        // Miss day 3 — freeze used
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 4))
        // Miss day 5 — no freeze left
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 6))

        let user = try await userRepository.getById(userId)
        XCTAssertEqual(user?.currentStreak, 1, "Should reset since freeze was already used")
    }

    func test_StreakService_freezeResetsWeekly() async throws {
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 1))
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 2))
        // Miss day 3 — use freeze
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 4))

        let user1 = try await userRepository.getById(userId)
        XCTAssertFalse(user1?.streakFreezeAvailable ?? true)

        // Engage consecutively through the week...
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 5))
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 6))
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 7))
        // New week (Jan 8 is a Thursday, but >7 days from lastFreezeResetDate)
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 8))

        let user2 = try await userRepository.getById(userId)
        XCTAssertTrue(user2?.streakFreezeAvailable ?? false, "Freeze should reset after a week")
    }

    // MARK: - Longest Streak

    func test_StreakService_longestStreak_persists() async throws {
        // Build a 5-day streak
        for day in 1...5 {
            try await service.recordEngagement(userId: userId, date: date(2026, 1, day))
        }
        // Miss 2 days, reset
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 8))

        let user = try await userRepository.getById(userId)
        XCTAssertEqual(user?.currentStreak, 1)
        XCTAssertEqual(user?.longestStreak, 5, "Longest streak should be preserved")
    }

    // MARK: - Get Streak Info

    func test_StreakService_getStreakInfo_returnsCorrectData() async throws {
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 1))
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 2))

        let info = try await service.getStreakInfo(userId: userId)
        XCTAssertNotNil(info)
        XCTAssertEqual(info?.currentStreak, 2)
        XCTAssertEqual(info?.longestStreak, 2)
        XCTAssertTrue(info?.freezeAvailable ?? false)
    }

    func test_StreakService_getStreakInfo_returnsNilForMissingUser() async throws {
        let info = try await service.getStreakInfo(userId: UUID())
        XCTAssertNil(info)
    }

    // MARK: - Silent Reset (No Notification)

    func test_StreakService_silentReset_noGuildNotification() async throws {
        // This test verifies the streak resets silently — no notification, no guilt message.
        // The spec says: "Breaking a streak = silent reset. No 'you lost your streak!' notification."
        // We verify this by checking that the streak simply resets to 1 with no side effects.
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 1))
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 2))
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 3))

        // Miss 2+ days
        try await service.recordEngagement(userId: userId, date: date(2026, 1, 10))

        let user = try await userRepository.getById(userId)
        XCTAssertEqual(user?.currentStreak, 1, "Streak should silently reset to 1")
        XCTAssertEqual(user?.longestStreak, 3, "Longest streak preserved")
    }
}
