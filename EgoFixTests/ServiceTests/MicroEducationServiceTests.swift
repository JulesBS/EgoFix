import XCTest
@testable import EgoFix

@MainActor
final class MicroEducationServiceTests: XCTestCase {

    private var repository: MockMicroEducationRepository!
    private var service: MicroEducationService!

    override func setUp() async throws {
        repository = MockMicroEducationRepository()
        service = MicroEducationService(repository: repository)
    }

    // MARK: - Basic Retrieval

    func test_getRandomTidbit_returnsNilWhenEmpty() async throws {
        let result = try await service.getRandomTidbit(bugSlug: "need-to-be-right", trigger: .postApply)
        XCTAssertNil(result)
    }

    func test_getRandomTidbit_returnsTidbitForBugAndTrigger() async throws {
        let tidbit = MicroEducation(
            bugSlug: "need-to-be-right",
            trigger: .postApply,
            body: "The urge to correct is a status signal, not an accuracy signal."
        )
        try await repository.save(tidbit)

        let result = try await service.getRandomTidbit(bugSlug: "need-to-be-right", trigger: .postApply)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.bugSlug, "need-to-be-right")
        XCTAssertEqual(result?.trigger, .postApply)
    }

    func test_getRandomTidbit_doesNotReturnWrongBug() async throws {
        let tidbit = MicroEducation(
            bugSlug: "need-to-be-liked",
            trigger: .postApply,
            body: "Approval-seeking is outsourced self-worth."
        )
        try await repository.save(tidbit)

        let result = try await service.getRandomTidbit(bugSlug: "need-to-be-right", trigger: .postApply)
        XCTAssertNil(result)
    }

    func test_getRandomTidbit_doesNotReturnWrongTrigger() async throws {
        let tidbit = MicroEducation(
            bugSlug: "need-to-be-right",
            trigger: .postCrash,
            body: "Crashes reveal the pattern."
        )
        try await repository.save(tidbit)

        let result = try await service.getRandomTidbit(bugSlug: "need-to-be-right", trigger: .postApply)
        // Should fall back to general, which is also empty
        XCTAssertNil(result)
    }

    // MARK: - General Fallback

    func test_getRandomTidbit_fallsBackToGeneral() async throws {
        let general = MicroEducation(
            bugSlug: "need-to-be-right",
            trigger: .general,
            body: "Being right feels good because it's a status win."
        )
        try await repository.save(general)

        let result = try await service.getRandomTidbit(bugSlug: "need-to-be-right", trigger: .postSkip)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.trigger, .general)
    }

    func test_getRandomTidbit_prefersSpecificOverGeneral() async throws {
        let specific = MicroEducation(
            bugSlug: "need-to-be-right",
            trigger: .postApply,
            body: "Specific tidbit"
        )
        let general = MicroEducation(
            bugSlug: "need-to-be-right",
            trigger: .general,
            body: "General tidbit"
        )
        try await repository.save(specific)
        try await repository.save(general)

        let result = try await service.getRandomTidbit(bugSlug: "need-to-be-right", trigger: .postApply)
        XCTAssertEqual(result?.trigger, .postApply)
    }

    // MARK: - No Consecutive Repeats

    func test_getRandomTidbit_avoidsConsecutiveRepeats() async throws {
        let tidbit1 = MicroEducation(
            bugSlug: "need-to-be-right",
            trigger: .postApply,
            body: "Tidbit 1"
        )
        let tidbit2 = MicroEducation(
            bugSlug: "need-to-be-right",
            trigger: .postApply,
            body: "Tidbit 2"
        )
        try await repository.save(tidbit1)
        try await repository.save(tidbit2)

        let first = try await service.getRandomTidbit(bugSlug: "need-to-be-right", trigger: .postApply)
        XCTAssertNotNil(first)

        // With only 2 tidbits, the second call should return the other one
        let second = try await service.getRandomTidbit(bugSlug: "need-to-be-right", trigger: .postApply)
        XCTAssertNotNil(second)
        XCTAssertNotEqual(first?.id, second?.id)
    }

    func test_getRandomTidbit_singleTidbit_returnsItAgain() async throws {
        let tidbit = MicroEducation(
            bugSlug: "need-to-be-right",
            trigger: .postApply,
            body: "Only one"
        )
        try await repository.save(tidbit)

        let first = try await service.getRandomTidbit(bugSlug: "need-to-be-right", trigger: .postApply)
        let second = try await service.getRandomTidbit(bugSlug: "need-to-be-right", trigger: .postApply)

        // With only 1 tidbit, it must return it again
        XCTAssertEqual(first?.id, second?.id)
    }
}
