import XCTest
@testable import EgoFix

@MainActor
final class ShareServiceTests: XCTestCase {

    private var analyticsRepo: MockAnalyticsEventRepository!
    private var service: ShareService!

    override func setUp() async throws {
        analyticsRepo = MockAnalyticsEventRepository()
        service = ShareService(analyticsEventRepository: analyticsRepo)
    }

    // MARK: - Content Generation

    func test_ShareService_includesPrompt() {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .standard,
            prompt: "Let someone finish a point you disagree with.",
            validation: "Did you?"
        )

        let content = service.generateShareContent(for: fix)
        XCTAssertTrue(content.text.contains("Let someone finish a point you disagree with."))
    }

    func test_ShareService_includesInlineComment() {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .standard,
            prompt: "Test prompt",
            validation: "Test validation",
            inlineComment: "The pause is the practice."
        )

        let content = service.generateShareContent(for: fix)
        XCTAssertTrue(content.text.contains("// The pause is the practice."))
    }

    func test_ShareService_includesWatermark() {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .standard,
            prompt: "Test",
            validation: "Test"
        )

        let content = service.generateShareContent(for: fix)
        XCTAssertTrue(content.text.contains("— EgoFix"))
    }

    func test_ShareService_excludesPersonalData() {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .standard,
            prompt: "Test prompt",
            validation: "Test validation",
            inlineComment: "Test comment"
        )

        let content = service.generateShareContent(for: fix)

        // Should NOT contain any of these
        XCTAssertFalse(content.text.contains("streak"))
        XCTAssertFalse(content.text.contains("version"))
        XCTAssertFalse(content.text.contains("stats"))
        XCTAssertFalse(content.text.contains("validation"))
    }

    func test_ShareService_handlesNoComment() {
        let fix = Fix(
            bugId: UUID(),
            type: .daily,
            severity: .medium,
            interactionType: .standard,
            prompt: "Test prompt",
            validation: "Test validation"
        )

        let content = service.generateShareContent(for: fix)
        XCTAssertFalse(content.text.contains("//"))
        XCTAssertTrue(content.text.contains("Test prompt"))
        XCTAssertTrue(content.text.contains("— EgoFix"))
    }

    // MARK: - Analytics Logging

    func test_ShareService_logsAnalyticsEvent() async throws {
        let fixId = UUID()
        let bugId = UUID()
        let userId = UUID()

        try await service.logShare(userId: userId, fixId: fixId, bugId: bugId)

        let events = try await analyticsRepo.getAll()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.eventType, .fixShared)
        XCTAssertEqual(events.first?.fixId, fixId)
        XCTAssertEqual(events.first?.bugId, bugId)
        XCTAssertEqual(events.first?.userId, userId)
    }
}
