import XCTest
@testable import EgoFix

@MainActor
final class BugIntensityProviderTests: XCTestCase {
    private var diagnosticRepo: MockWeeklyDiagnosticRepository!
    private var crashRepo: MockCrashRepository!
    private var provider: BugIntensityProvider!

    private let userId = UUID()
    private let bugId = UUID()

    override func setUp() {
        super.setUp()
        diagnosticRepo = MockWeeklyDiagnosticRepository()
        crashRepo = MockCrashRepository()
        provider = BugIntensityProvider(
            weeklyDiagnosticRepository: diagnosticRepo,
            crashRepository: crashRepo
        )
    }

    // MARK: - Default (no data)

    func test_currentIntensity_noData_returnsPresent() async throws {
        let intensity = try await provider.currentIntensity(for: bugId, userId: userId)
        XCTAssertEqual(intensity, .present)
    }

    // MARK: - Diagnostic-driven

    func test_currentIntensity_diagnosticQuiet_noCrashes_returnsQuiet() async throws {
        try await saveDiagnostic(intensity: .quiet)
        let result = try await provider.currentIntensity(for: bugId, userId: userId)
        XCTAssertEqual(result, .quiet)
    }

    func test_currentIntensity_diagnosticPresent_noCrashes_returnsPresent() async throws {
        try await saveDiagnostic(intensity: .present)
        let result = try await provider.currentIntensity(for: bugId, userId: userId)
        XCTAssertEqual(result, .present)
    }

    func test_currentIntensity_diagnosticLoud_noCrashes_returnsLoud() async throws {
        try await saveDiagnostic(intensity: .loud)
        let result = try await provider.currentIntensity(for: bugId, userId: userId)
        XCTAssertEqual(result, .loud)
    }

    // MARK: - Crash-driven

    func test_currentIntensity_noDiagnostic_oneCrash_returnsPresent() async throws {
        try await saveCrash(daysAgo: 1)
        let result = try await provider.currentIntensity(for: bugId, userId: userId)
        XCTAssertEqual(result, .present)
    }

    func test_currentIntensity_noDiagnostic_threeCrashes_returnsLoud() async throws {
        try await saveCrash(daysAgo: 1)
        try await saveCrash(daysAgo: 2)
        try await saveCrash(daysAgo: 3)
        let result = try await provider.currentIntensity(for: bugId, userId: userId)
        XCTAssertEqual(result, .loud)
    }

    // MARK: - Combined

    func test_currentIntensity_diagnosticQuiet_twoCrashes_returnsPresent() async throws {
        try await saveDiagnostic(intensity: .quiet)
        try await saveCrash(daysAgo: 1)
        try await saveCrash(daysAgo: 2)
        let result = try await provider.currentIntensity(for: bugId, userId: userId)
        XCTAssertEqual(result, .present)
    }

    func test_currentIntensity_diagnosticQuiet_threeCrashes_returnsLoud() async throws {
        try await saveDiagnostic(intensity: .quiet)
        try await saveCrash(daysAgo: 1)
        try await saveCrash(daysAgo: 2)
        try await saveCrash(daysAgo: 3)
        let result = try await provider.currentIntensity(for: bugId, userId: userId)
        XCTAssertEqual(result, .loud)
    }

    // MARK: - Old crashes (outside 7-day window) should not count

    func test_currentIntensity_oldCrashesIgnored() async throws {
        try await saveCrash(daysAgo: 10)
        try await saveCrash(daysAgo: 14)
        try await saveCrash(daysAgo: 21)
        let result = try await provider.currentIntensity(for: bugId, userId: userId)
        // No recent crashes, no diagnostic => default present
        XCTAssertEqual(result, .present)
    }

    // MARK: - Helpers

    private func saveDiagnostic(intensity: BugIntensity) async throws {
        let diagnostic = WeeklyDiagnostic(
            userId: userId,
            weekStarting: Calendar.current.startOfDay(for: Date()),
            responses: [BugDiagnosticResponse(bugId: bugId, intensity: intensity, primaryContext: nil)],
            completedAt: Date()
        )
        try await diagnosticRepo.save(diagnostic)
    }

    private func saveCrash(daysAgo: Int) async throws {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        let crash = Crash(
            userId: userId,
            bugId: bugId,
            crashedAt: date
        )
        try await crashRepo.save(crash)
    }
}
