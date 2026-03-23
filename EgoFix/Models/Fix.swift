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

    /// Human-readable label for morning briefing (pre-accept)
    var typeLabel: String {
        switch self {
        case .standard: return "A practice"
        case .counter: return "Track a pattern"
        case .observation: return "Something to notice"
        case .abstain: return "A challenge"
        case .substitute: return "A swap"
        case .journal: return "A question"
        case .reversal: return "Do the opposite"
        case .predict: return "A test"
        case .body: return "A body scan"
        case .audit: return "End-of-day review"
        case .multiStep: return "A sequence"
        case .timed: return "Sit with it"
        case .quiz: return "Self-assessment"
        case .scenario: return "A situation"
        }
    }

    /// Estimated mission duration for briefing display
    var estimatedTime: String {
        switch self {
        case .timed: return "5-10 min"
        case .quiz: return "~30 seconds"
        case .scenario: return "~1 minute"
        case .audit: return "Evening"
        default: return "All day"
        }
    }

    /// Whether this type completes immediately in-app (no day-long mission)
    var isImmediate: Bool {
        switch self {
        case .timed, .quiz, .scenario: return true
        default: return false
        }
    }

    /// Type-flavored teaser comment for morning briefing
    var teaserComment: String {
        switch self {
        case .standard: return "// Something to try in the wild."
        case .counter: return "// Count it. Don't fix it."
        case .observation: return "// Not to fix. Just to see."
        case .abstain: return "// Can you not?"
        case .substitute: return "// When X, try Y instead."
        case .journal: return "// 2-3 sentences. Be honest."
        case .reversal: return "// This will feel wrong."
        case .predict: return "// Predict. Then observe."
        case .body: return "// Your body already knows."
        case .audit: return "// Tonight, look back."
        case .multiStep: return "// Three steps. In order."
        case .timed: return "// Set a timer. Stay put."
        case .quiz: return "// No right answer."
        case .scenario: return "// What would you do?"
        }
    }
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

    var bodyConfig: BodyConfig? {
        guard interactionType == .body, let data = configurationData else { return nil }
        return try? JSONDecoder().decode(BodyConfig.self, from: data)
    }

    /// Stable, deterministic fix number derived from UUID (consistent across launches)
    var fixNumber: String {
        let hex = id.uuidString.replacingOccurrences(of: "-", with: "").prefix(4)
        let value = UInt32(hex, radix: 16) ?? 0
        return String(format: "%04d", value % 10000)
    }

    func setConfiguration<T: Encodable>(_ config: T) {
        configurationData = try? JSONEncoder().encode(config)
    }

    /// Complexity level (1-5) based on interaction type.
    /// Week 1 users only see complexity 1-2, Week 4+ see all.
    var complexity: Int {
        switch interactionType {
        case .standard:    return 1
        case .counter:     return 1
        case .abstain:     return 2
        case .reversal:    return 2
        case .observation: return 2
        case .body:        return 2
        case .journal:     return 3
        case .substitute:  return 3
        case .timed:       return 3
        case .predict:     return 3
        case .scenario:    return 4
        case .multiStep:   return 4
        case .quiz:        return 4
        case .audit:       return 5
        }
    }
}
