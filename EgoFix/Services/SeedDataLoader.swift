import Foundation
import SwiftData

final class SeedDataLoader {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadSeedDataIfNeeded() async throws {
        // Check if bugs already exist
        let bugDescriptor = FetchDescriptor<Bug>()
        let existingBugs = try modelContext.fetch(bugDescriptor)

        guard existingBugs.isEmpty else { return }

        try await loadBugs()
        try await loadFixes()
        try await loadMicroEducation()
    }

    private func loadBugs() async throws {
        guard let url = Bundle.main.url(forResource: "bugs", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return
        }

        let decoder = JSONDecoder()
        let seedBugs = try decoder.decode([SeedBug].self, from: data)

        for seedBug in seedBugs {
            let bug = Bug(
                id: UUID(uuidString: seedBug.id) ?? UUID(),
                slug: seedBug.slug,
                title: seedBug.title,
                description: seedBug.description
            )
            modelContext.insert(bug)
        }

        try modelContext.save()
    }

    private func loadFixes() async throws {
        guard let url = Bundle.main.url(forResource: "fixes", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return
        }

        // First, get all bugs to map slugs to IDs
        let bugDescriptor = FetchDescriptor<Bug>()
        let bugs = try modelContext.fetch(bugDescriptor)
        let bugsBySlug = Dictionary(uniqueKeysWithValues: bugs.map { ($0.slug, $0.id) })

        let decoder = JSONDecoder()
        let seedFixes = try decoder.decode([SeedFix].self, from: data)

        for seedFix in seedFixes {
            guard let bugId = bugsBySlug[seedFix.bugSlug] else { continue }

            let interactionType = InteractionType(rawValue: seedFix.interactionType ?? "standard") ?? .standard
            let configData = seedFix.encodeConfiguration()

            let fix = Fix(
                id: UUID(uuidString: seedFix.id) ?? UUID(),
                bugId: bugId,
                type: FixType(rawValue: seedFix.type) ?? .daily,
                severity: FixSeverity(rawValue: seedFix.severity) ?? .medium,
                interactionType: interactionType,
                prompt: seedFix.prompt,
                validation: seedFix.validation,
                inlineComment: seedFix.inlineComment,
                configurationData: configData
            )
            modelContext.insert(fix)
        }

        try modelContext.save()
    }

    private func loadMicroEducation() async throws {
        guard let url = Bundle.main.url(forResource: "micro_education", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return
        }

        let decoder = JSONDecoder()
        let seedItems = try decoder.decode([SeedMicroEducation].self, from: data)

        for item in seedItems {
            let trigger = EducationTrigger(rawValue: item.trigger) ?? .general
            let education = MicroEducation(
                id: UUID(uuidString: item.id) ?? UUID(),
                bugSlug: item.bugSlug,
                trigger: trigger,
                body: item.body
            )
            modelContext.insert(education)
        }

        try modelContext.save()
    }
}

// MARK: - Seed Data Models

private struct SeedBug: Codable {
    let id: String
    let slug: String
    let title: String
    let description: String
}

private struct SeedFix: Codable {
    let id: String
    let bugSlug: String
    let type: String
    let severity: String
    let interactionType: String?
    let prompt: String
    let validation: String
    let inlineComment: String?
    let configuration: SeedFixConfiguration?

    func encodeConfiguration() -> Data? {
        guard let config = configuration else { return nil }

        let encoder = JSONEncoder()

        if let timed = config.timed {
            return try? encoder.encode(timed)
        } else if let multiStep = config.multiStep {
            return try? encoder.encode(multiStep)
        } else if let quiz = config.quiz {
            return try? encoder.encode(quiz)
        } else if let scenario = config.scenario {
            return try? encoder.encode(scenario)
        } else if let counter = config.counter {
            return try? encoder.encode(counter)
        } else if let observation = config.observation {
            return try? encoder.encode(observation)
        } else if let abstain = config.abstain {
            return try? encoder.encode(abstain)
        } else if let substitute = config.substitute {
            return try? encoder.encode(substitute)
        } else if let predict = config.predict {
            return try? encoder.encode(predict)
        } else if let audit = config.audit {
            return try? encoder.encode(audit)
        }

        return nil
    }
}

private struct SeedFixConfiguration: Codable {
    let timed: TimedConfig?
    let multiStep: MultiStepConfig?
    let quiz: QuizConfig?
    let scenario: ScenarioConfig?
    let counter: CounterConfig?
    let observation: ObservationConfig?
    let abstain: AbstainConfig?
    let substitute: SubstituteConfig?
    let predict: PredictConfig?
    let audit: AuditConfig?
}

private struct SeedMicroEducation: Codable {
    let id: String
    let bugSlug: String
    let trigger: String
    let body: String
}