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
    let slips: [SlipEvent]
    let timerUsed: Bool
    let durationSeconds: Int?

    struct SlipEvent: Codable, Equatable {
        let timestamp: Date
        let note: String?
    }

    /// Backward-compatible convenience init for toggle-only mode
    init(completed: Bool, slipCount: Int) {
        self.completed = completed
        self.slipCount = slipCount
        self.slips = []
        self.timerUsed = false
        self.durationSeconds = nil
    }

    init(completed: Bool, slipCount: Int, slips: [SlipEvent], timerUsed: Bool, durationSeconds: Int?) {
        self.completed = completed
        self.slipCount = slipCount
        self.slips = slips
        self.timerUsed = timerUsed
        self.durationSeconds = durationSeconds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        completed = try container.decode(Bool.self, forKey: .completed)
        slipCount = try container.decode(Int.self, forKey: .slipCount)
        slips = try container.decodeIfPresent([SlipEvent].self, forKey: .slips) ?? []
        timerUsed = try container.decodeIfPresent(Bool.self, forKey: .timerUsed) ?? false
        durationSeconds = try container.decodeIfPresent(Int.self, forKey: .durationSeconds)
    }

    private enum CodingKeys: String, CodingKey {
        case completed, slipCount, slips, timerUsed, durationSeconds
    }
}

// MARK: - Body Outcome

struct BodyOutcome: Codable, Equatable {
    let selectedRegions: [String]
    let selectedSensations: [String]
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
