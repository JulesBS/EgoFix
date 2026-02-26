import XCTest
@testable import EgoFix

final class SeedDataTests: XCTestCase {

    // MARK: - Bug Seed Data

    private struct SeedBug: Codable {
        let id: String
        let slug: String
        let title: String
        let description: String
    }

    private func loadBugSeedData() throws -> [SeedBug] {
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "bugs", withExtension: "json") else {
            // Fall back to main bundle for seed data
            guard let mainUrl = Bundle.main.url(forResource: "bugs", withExtension: "json") else {
                XCTFail("bugs.json not found in any bundle")
                return []
            }
            let data = try Data(contentsOf: mainUrl)
            return try JSONDecoder().decode([SeedBug].self, from: data)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([SeedBug].self, from: data)
    }

    func test_SeedData_has7Bugs() throws {
        let bugs = try loadBugSeedData()
        XCTAssertEqual(bugs.count, 7, "Should have exactly 7 bugs")
    }

    func test_SeedData_bugSlugsMatchSpec() throws {
        let bugs = try loadBugSeedData()
        let slugs = Set(bugs.map { $0.slug })

        let expectedSlugs: Set<String> = [
            "need-to-be-right",
            "need-to-be-liked",
            "need-to-control",
            "need-to-compare",
            "need-to-impress",
            "need-to-deflect",
            "need-to-narrate"
        ]

        XCTAssertEqual(slugs, expectedSlugs)
    }

    func test_SeedData_noLegacyBugs() throws {
        let bugs = try loadBugSeedData()
        let slugs = bugs.map { $0.slug }

        XCTAssertFalse(slugs.contains("need-to-avoid-failure"), "Legacy bug should be removed")
    }

    func test_SeedData_allBugsHaveValidUUIDs() throws {
        let bugs = try loadBugSeedData()
        for bug in bugs {
            XCTAssertNotNil(UUID(uuidString: bug.id), "Bug \(bug.slug) has invalid UUID: \(bug.id)")
        }
    }

    func test_SeedData_allBugsHaveDescriptions() throws {
        let bugs = try loadBugSeedData()
        for bug in bugs {
            XCTAssertFalse(bug.description.isEmpty, "Bug \(bug.slug) has empty description")
            XCTAssertGreaterThan(bug.description.count, 20, "Bug \(bug.slug) description too short")
        }
    }

    func test_SeedData_noDuplicateSlugs() throws {
        let bugs = try loadBugSeedData()
        let slugs = bugs.map { $0.slug }
        XCTAssertEqual(slugs.count, Set(slugs).count, "Duplicate slugs found")
    }

    func test_SeedData_noDuplicateIDs() throws {
        let bugs = try loadBugSeedData()
        let ids = bugs.map { $0.id }
        XCTAssertEqual(ids.count, Set(ids).count, "Duplicate IDs found")
    }

    // MARK: - Fix Seed Data

    private struct SeedFix: Codable {
        let id: String
        let bugSlug: String
        let type: String
        let severity: String
        let interactionType: String?
        let prompt: String
        let validation: String
        let inlineComment: String?
        let configuration: AnyCodable?
    }

    private struct AnyCodable: Codable {}

    private func loadFixSeedData() throws -> [SeedFix] {
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "fixes", withExtension: "json") else {
            guard let mainUrl = Bundle.main.url(forResource: "fixes", withExtension: "json") else {
                XCTFail("fixes.json not found in any bundle")
                return []
            }
            let data = try Data(contentsOf: mainUrl)
            return try JSONDecoder().decode([SeedFix].self, from: data)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([SeedFix].self, from: data)
    }

    func test_SeedData_fixesExist() throws {
        let fixes = try loadFixSeedData()
        XCTAssertGreaterThanOrEqual(fixes.count, 270, "Should have at least 270 fixes, got \(fixes.count)")
    }

    func test_SeedData_perBugMinimum() throws {
        let fixes = try loadFixSeedData()
        let byBug = Dictionary(grouping: fixes, by: { $0.bugSlug })

        let expectedSlugs = [
            "need-to-be-right", "need-to-be-liked", "need-to-control",
            "need-to-compare", "need-to-impress", "need-to-deflect", "need-to-narrate"
        ]

        for slug in expectedSlugs {
            let count = byBug[slug]?.count ?? 0
            XCTAssertGreaterThanOrEqual(count, 38, "Bug \(slug) should have at least 38 fixes, got \(count)")
        }
    }

    func test_SeedData_interactionTypeCoveragePerBug() throws {
        let fixes = try loadFixSeedData()
        let byBug = Dictionary(grouping: fixes, by: { $0.bugSlug })

        for (slug, bugFixes) in byBug {
            let types = Set(bugFixes.compactMap { $0.interactionType })
            XCTAssertGreaterThanOrEqual(types.count, 10, "Bug \(slug) should have at least 10 distinct interaction types, got \(types.count)")
        }
    }

    func test_SeedData_severityDistribution() throws {
        let fixes = try loadFixSeedData()
        let total = Double(fixes.count)
        let low = Double(fixes.filter { $0.severity == "low" }.count)
        let medium = Double(fixes.filter { $0.severity == "medium" }.count)
        let high = Double(fixes.filter { $0.severity == "high" }.count)

        // Expect roughly 40% low, 40% medium, 20% high (±15% tolerance)
        XCTAssertGreaterThan(low / total, 0.25, "Low severity should be >25%, got \(low / total)")
        XCTAssertGreaterThan(medium / total, 0.25, "Medium severity should be >25%, got \(medium / total)")
        XCTAssertGreaterThan(high / total, 0.10, "High severity should be >10%, got \(high / total)")
        XCTAssertLessThan(high / total, 0.40, "High severity should be <40%, got \(high / total)")
    }

    func test_SeedData_noLegacyBugFixes() throws {
        let fixes = try loadFixSeedData()
        let legacyFixes = fixes.filter { $0.bugSlug == "need-to-avoid-failure" }
        XCTAssertEqual(legacyFixes.count, 0, "No fixes should reference removed bug")
    }

    func test_SeedData_allBugsHaveFixes() throws {
        let fixes = try loadFixSeedData()
        let fixBugSlugs = Set(fixes.map { $0.bugSlug })

        let expectedSlugs: Set<String> = [
            "need-to-be-right", "need-to-be-liked", "need-to-control",
            "need-to-compare", "need-to-impress", "need-to-deflect", "need-to-narrate"
        ]

        for slug in expectedSlugs {
            XCTAssertTrue(fixBugSlugs.contains(slug), "No fixes for bug: \(slug)")
        }
    }

    func test_SeedData_fixesHaveValidInteractionTypes() throws {
        let fixes = try loadFixSeedData()
        let validTypes: Set<String> = [
            "standard", "timed", "multiStep", "quiz", "scenario", "counter",
            "observation", "abstain", "substitute", "journal", "reversal",
            "predict", "body", "audit"
        ]

        for fix in fixes {
            if let type = fix.interactionType {
                XCTAssertTrue(validTypes.contains(type), "Invalid interaction type '\(type)' in fix \(fix.id)")
            }
        }
    }

    func test_SeedData_fixesNoDuplicateIDs() throws {
        let fixes = try loadFixSeedData()
        let ids = fixes.map { $0.id }
        XCTAssertEqual(ids.count, Set(ids).count, "Duplicate fix IDs found")
    }

    func test_SeedData_allFixesHaveInteractionType() throws {
        let fixes = try loadFixSeedData()
        for fix in fixes {
            XCTAssertNotNil(fix.interactionType, "Fix \(fix.id) missing interactionType")
            XCTAssertFalse(fix.interactionType?.isEmpty ?? true, "Fix \(fix.id) has empty interactionType")
        }
    }

    func test_SeedData_fixesCoverNewInteractionTypes() throws {
        let fixes = try loadFixSeedData()
        let types = Set(fixes.compactMap { $0.interactionType })

        let newTypes = ["observation", "abstain", "substitute", "journal", "reversal", "predict", "body", "audit"]
        for type in newTypes {
            XCTAssertTrue(types.contains(type), "Missing new interaction type: \(type)")
        }
    }

    // MARK: - Micro-Education Seed Data

    private struct SeedMicroEducation: Codable {
        let id: String
        let bugSlug: String
        let trigger: String
        let body: String
    }

    private func loadMicroEducationSeedData() throws -> [SeedMicroEducation] {
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "micro_education", withExtension: "json") else {
            guard let mainUrl = Bundle.main.url(forResource: "micro_education", withExtension: "json") else {
                XCTFail("micro_education.json not found in any bundle")
                return []
            }
            let data = try Data(contentsOf: mainUrl)
            return try JSONDecoder().decode([SeedMicroEducation].self, from: data)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([SeedMicroEducation].self, from: data)
    }

    func test_SeedData_microEducationExists() throws {
        let tidbits = try loadMicroEducationSeedData()
        XCTAssertGreaterThanOrEqual(tidbits.count, 100, "Should have at least 100 micro-education tidbits, got \(tidbits.count)")
    }

    func test_SeedData_microEducationPerBug() throws {
        let tidbits = try loadMicroEducationSeedData()
        let byBug = Dictionary(grouping: tidbits, by: { $0.bugSlug })

        let expectedSlugs = [
            "need-to-be-right", "need-to-be-liked", "need-to-control",
            "need-to-compare", "need-to-impress", "need-to-deflect", "need-to-narrate"
        ]

        for slug in expectedSlugs {
            let count = byBug[slug]?.count ?? 0
            XCTAssertGreaterThanOrEqual(count, 12, "Bug \(slug) should have at least 12 tidbits, got \(count)")
        }
    }

    func test_SeedData_microEducationTriggers() throws {
        let tidbits = try loadMicroEducationSeedData()
        let triggers = Set(tidbits.map { $0.trigger })
        let expectedTriggers: Set<String> = ["postApply", "postSkip", "postCrash", "general"]
        XCTAssertEqual(triggers, expectedTriggers, "Should cover all 4 trigger types")
    }

    func test_SeedData_microEducationNoDuplicateIDs() throws {
        let tidbits = try loadMicroEducationSeedData()
        let ids = tidbits.map { $0.id }
        XCTAssertEqual(ids.count, Set(ids).count, "Duplicate micro-education IDs found")
    }
}
