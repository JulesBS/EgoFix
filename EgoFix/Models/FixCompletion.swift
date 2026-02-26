import Foundation
import SwiftData

enum FixOutcome: String, Codable {
    case pending
    case applied
    case skipped
    case failed
}

@Model
final class FixCompletion {
    @Attribute(.unique) var id: UUID
    var fixId: UUID
    var userId: UUID
    var outcome: FixOutcome
    var reflection: String?
    var outcomeData: Data?
    var assignedAt: Date
    var completedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        fixId: UUID,
        userId: UUID,
        outcome: FixOutcome = .pending,
        reflection: String? = nil,
        outcomeData: Data? = nil,
        assignedAt: Date = Date(),
        completedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.fixId = fixId
        self.userId = userId
        self.outcome = outcome
        self.reflection = reflection
        self.outcomeData = outcomeData
        self.assignedAt = assignedAt
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}

// MARK: - Outcome Data Access

extension FixCompletion {
    var timedOutcome: TimedOutcome? {
        guard let data = outcomeData else { return nil }
        return try? JSONDecoder().decode(TimedOutcome.self, from: data)
    }

    var multiStepOutcome: MultiStepOutcome? {
        guard let data = outcomeData else { return nil }
        return try? JSONDecoder().decode(MultiStepOutcome.self, from: data)
    }

    var quizOutcome: QuizOutcome? {
        guard let data = outcomeData else { return nil }
        return try? JSONDecoder().decode(QuizOutcome.self, from: data)
    }

    var scenarioOutcome: ScenarioOutcome? {
        guard let data = outcomeData else { return nil }
        return try? JSONDecoder().decode(ScenarioOutcome.self, from: data)
    }

    var counterOutcome: CounterOutcome? {
        guard let data = outcomeData else { return nil }
        return try? JSONDecoder().decode(CounterOutcome.self, from: data)
    }

    var observationOutcome: ObservationOutcome? {
        guard let data = outcomeData else { return nil }
        return try? JSONDecoder().decode(ObservationOutcome.self, from: data)
    }

    var abstainOutcome: AbstainOutcome? {
        guard let data = outcomeData else { return nil }
        return try? JSONDecoder().decode(AbstainOutcome.self, from: data)
    }

    var substituteOutcome: SubstituteOutcome? {
        guard let data = outcomeData else { return nil }
        return try? JSONDecoder().decode(SubstituteOutcome.self, from: data)
    }

    var predictOutcome: PredictOutcome? {
        guard let data = outcomeData else { return nil }
        return try? JSONDecoder().decode(PredictOutcome.self, from: data)
    }

    var auditOutcome: AuditOutcome? {
        guard let data = outcomeData else { return nil }
        return try? JSONDecoder().decode(AuditOutcome.self, from: data)
    }

    func setOutcomeData<T: Encodable>(_ data: T) {
        outcomeData = try? JSONEncoder().encode(data)
    }
}
