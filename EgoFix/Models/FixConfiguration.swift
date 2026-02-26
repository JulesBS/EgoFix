import Foundation

// MARK: - Timed Configuration

struct TimedConfig: Codable, Equatable {
    let durationSeconds: Int
}

// MARK: - Multi-Step Configuration

struct MultiStepConfig: Codable, Equatable {
    let steps: [StepItem]

    struct StepItem: Codable, Equatable, Identifiable {
        let id: String
        let prompt: String
        let validation: String?
        let inlineComment: String?
    }
}

// MARK: - Quiz Configuration

struct QuizConfig: Codable, Equatable {
    let question: String
    let options: [QuizOption]
    let explanationAfter: String?

    struct QuizOption: Codable, Equatable, Identifiable {
        let id: String
        let text: String
        let weightModifier: Double
        let insight: String?
    }
}

// MARK: - Scenario Configuration

struct ScenarioConfig: Codable, Equatable {
    let situation: String
    let options: [ScenarioOption]
    let debrief: String?

    struct ScenarioOption: Codable, Equatable, Identifiable {
        let id: String
        let text: String
        let weightModifier: Double
        let reflection: String?
    }
}

// MARK: - Counter Configuration

struct CounterConfig: Codable, Equatable {
    let counterPrompt: String
    let minTarget: Int?
    let maxTarget: Int?
}

// MARK: - Observation Configuration

struct ObservationConfig: Codable, Equatable {
    let reportPrompt: String
}

// MARK: - Abstain Configuration

struct AbstainConfig: Codable, Equatable {
    let durationDescription: String
    let endTime: String?
}

// MARK: - Substitute Configuration

struct SubstituteConfig: Codable, Equatable {
    let triggerBehavior: String
    let replacementBehavior: String
}

// MARK: - Predict Configuration

struct PredictConfig: Codable, Equatable {
    let predictionPrompt: String
    let observationPrompt: String
}

// MARK: - Audit Configuration

struct AuditConfig: Codable, Equatable {
    let auditPrompt: String
    let categories: [AuditCategory]

    struct AuditCategory: Codable, Equatable, Identifiable {
        let id: String
        let label: String
    }
}
