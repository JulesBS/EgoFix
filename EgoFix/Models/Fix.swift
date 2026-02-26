import Foundation
import SwiftData

enum FixType: String, Codable {
    case daily
    case weekly
    case quickFix
}

enum FixSeverity: String, Codable {
    case low
    case medium
    case high
}

enum InteractionType: String, Codable {
    case standard
    case timed
    case multiStep
    case quiz
    case scenario
    case counter
    case observation
    case abstain
    case substitute
    case journal
    case reversal
    case predict
    case body
    case audit
}

@Model
final class Fix {
    @Attribute(.unique) var id: UUID
    var bugId: UUID
    var type: FixType
    var severity: FixSeverity
    var interactionType: InteractionType
    var prompt: String
    var validation: String
    var inlineComment: String?
    var configurationData: Data?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        bugId: UUID,
        type: FixType,
        severity: FixSeverity,
        interactionType: InteractionType = .standard,
        prompt: String,
        validation: String,
        inlineComment: String? = nil,
        configurationData: Data? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.bugId = bugId
        self.type = type
        self.severity = severity
        self.interactionType = interactionType
        self.prompt = prompt
        self.validation = validation
        self.inlineComment = inlineComment
        self.configurationData = configurationData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}

// MARK: - Configuration Access

extension Fix {
    var timedConfig: TimedConfig? {
        guard interactionType == .timed, let data = configurationData else { return nil }
        return try? JSONDecoder().decode(TimedConfig.self, from: data)
    }

    var multiStepConfig: MultiStepConfig? {
        guard interactionType == .multiStep, let data = configurationData else { return nil }
        return try? JSONDecoder().decode(MultiStepConfig.self, from: data)
    }

    var quizConfig: QuizConfig? {
        guard interactionType == .quiz, let data = configurationData else { return nil }
        return try? JSONDecoder().decode(QuizConfig.self, from: data)
    }

    var scenarioConfig: ScenarioConfig? {
        guard interactionType == .scenario, let data = configurationData else { return nil }
        return try? JSONDecoder().decode(ScenarioConfig.self, from: data)
    }

    var counterConfig: CounterConfig? {
        guard interactionType == .counter, let data = configurationData else { return nil }
        return try? JSONDecoder().decode(CounterConfig.self, from: data)
    }

    var observationConfig: ObservationConfig? {
        guard interactionType == .observation, let data = configurationData else { return nil }
        return try? JSONDecoder().decode(ObservationConfig.self, from: data)
    }

    var abstainConfig: AbstainConfig? {
        guard interactionType == .abstain, let data = configurationData else { return nil }
        return try? JSONDecoder().decode(AbstainConfig.self, from: data)
    }

    var substituteConfig: SubstituteConfig? {
        guard interactionType == .substitute, let data = configurationData else { return nil }
        return try? JSONDecoder().decode(SubstituteConfig.self, from: data)
    }

    var predictConfig: PredictConfig? {
        guard interactionType == .predict, let data = configurationData else { return nil }
        return try? JSONDecoder().decode(PredictConfig.self, from: data)
    }

    var auditConfig: AuditConfig? {
        guard interactionType == .audit, let data = configurationData else { return nil }
        return try? JSONDecoder().decode(AuditConfig.self, from: data)
    }

    func setConfiguration<T: Encodable>(_ config: T) {
        configurationData = try? JSONEncoder().encode(config)
    }
}
