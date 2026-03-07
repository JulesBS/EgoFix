import XCTest
@testable import EgoFix

@MainActor
final class DebriefServiceTests: XCTestCase {

    func test_generateDebrief_milestone5() async {
        let bugRepo = MockBugRepository()
        let completionRepo = MockFixCompletionRepository()
        let userId = UUID()

        // Create exactly 5 completed completions
        for _ in 0..<5 {
            let completion = FixCompletion(fixId: UUID(), userId: userId, outcome: .applied)
            completion.completedAt = Date()
            try? await completionRepo.save(completion)
        }

        let service = DebriefService(
            fixCompletionRepository: completionRepo,
            bugRepository: bugRepo
        )

        let debrief = await service.generateDebrief(
            bugSlug: "need-to-be-right",
            bugLabel: "need-to-be-right",
            userId: userId,
            lastOutcome: .applied
        )

        XCTAssertNotNil(debrief)
        XCTAssertEqual(debrief?.template, .milestone)
        XCTAssertTrue(debrief?.body.contains("5") ?? false)
    }

    func test_generateDebrief_nonMilestone_returnsTomorrowPreview() async {
        let bugRepo = MockBugRepository()
        let completionRepo = MockFixCompletionRepository()
        let userId = UUID()

        // Create 3 completed completions (not a milestone)
        for _ in 0..<3 {
            let completion = FixCompletion(fixId: UUID(), userId: userId, outcome: .applied)
            completion.completedAt = Date()
            try? await completionRepo.save(completion)
        }

        let service = DebriefService(
            fixCompletionRepository: completionRepo,
            bugRepository: bugRepo
        )

        let debrief = await service.generateDebrief(
            bugSlug: "need-to-be-right",
            bugLabel: "need-to-be-right",
            userId: userId,
            lastOutcome: .applied
        )

        XCTAssertNotNil(debrief)
        XCTAssertEqual(debrief?.template, .tomorrowPreview)
    }

    func test_generateDebrief_milestone10() async {
        let bugRepo = MockBugRepository()
        let completionRepo = MockFixCompletionRepository()
        let userId = UUID()

        for _ in 0..<10 {
            let completion = FixCompletion(fixId: UUID(), userId: userId, outcome: .applied)
            completion.completedAt = Date()
            try? await completionRepo.save(completion)
        }

        let service = DebriefService(
            fixCompletionRepository: completionRepo,
            bugRepository: bugRepo
        )

        let debrief = await service.generateDebrief(
            bugSlug: "need-to-be-right",
            bugLabel: "need-to-be-right",
            userId: userId,
            lastOutcome: .applied
        )

        XCTAssertEqual(debrief?.template, .milestone)
        XCTAssertTrue(debrief?.body.contains("10") ?? false)
    }

    func test_DebriefContent_identifiable() {
        let content = DebriefContent(
            title: "DEBRIEF",
            body: "Test",
            comment: "// Test",
            template: .tomorrowPreview
        )
        // DebriefContent conforms to Identifiable
        XCTAssertNotNil(content.id)
    }
}
