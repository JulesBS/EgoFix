import Foundation

// MARK: - Timed Outcome

struct TimedOutcome: Codable, Equatable {
    let timerCompleted: Bool
    let actualDurationSeconds: Int?
}

// MARK: - Multi-Step Outcome

struct MultiStepOutcome: Codable, Equatable {
    let stepsCompleted: [StepCompletion]

    struct StepCompletion: Codable, Equatable {
        let stepId: String
        let completedAt: Date
        let skipped: Bool
    }

    var allStepsCompleted: Bool {
        !stepsCompleted.isEmpty && stepsCompleted.allSatisfy { !$0.skipped }
    }

    var completedCount: Int {
        stepsCompleted.filter { !$0.skipped }.count
    }

    var skippedCount: Int {
        stepsCompleted.filter { $0.skipped }.count
    }
}

// MARK: - Quiz Outcome

struct QuizOutcome: Codable, Equatable {
    let selectedOptionId: String
    let weightModifierApplied: Double
}

// MARK: - Scenario Outcome

struct ScenarioOutcome: Codable, Equatable {
    let selectedOptionId: String
    let weightModifierApplied: Double
}

// MARK: - Counter Outcome

struct CounterOutcome: Codable, Equatable {
    let finalCount: Int
    let countHistory: [CountEvent]

    struct CountEvent: Codable, Equatable {
        let timestamp: Date
        let delta: Int
    }
}

// MARK: - Observation Outcome

struct ObservationOutcome: Codable, Equatable {
    let report: String
}

// MARK: - Abstain Outcome

struct AbstainOutcome: Codable, Equatable {
    let completed: Bool
    let slipCount: Int
}

// MARK: - Substitute Outcome

struct SubstituteOutcome: Codable, Equatable {
    let substituteCount: Int
    let urgeCount: Int
}

// MARK: - Predict Outcome

struct PredictOutcome: Codable, Equatable {
    let prediction: String
    let actualResult: String
}

// MARK: - Audit Outcome

struct AuditOutcome: Codable, Equatable {
    let items: [AuditItem]

    struct AuditItem: Codable, Equatable {
        let categoryId: String
        let note: String
    }
}
