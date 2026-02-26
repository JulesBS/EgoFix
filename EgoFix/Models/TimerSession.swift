import Foundation
import SwiftData

enum TimerStatus: String, Codable {
    case idle
    case running
    case paused
    case completed
}

@Model
final class TimerSession {
    @Attribute(.unique) var id: UUID
    var fixCompletionId: UUID
    var durationSeconds: Int
    var startedAt: Date?
    var pausedAt: Date?
    var completedAt: Date?
    var accumulatedSeconds: Int  // Time accumulated before current run (for pause/resume)
    var status: TimerStatus
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        fixCompletionId: UUID,
        durationSeconds: Int,
        startedAt: Date? = nil,
        pausedAt: Date? = nil,
        completedAt: Date? = nil,
        accumulatedSeconds: Int = 0,
        status: TimerStatus = .idle,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.fixCompletionId = fixCompletionId
        self.durationSeconds = durationSeconds
        self.startedAt = startedAt
        self.pausedAt = pausedAt
        self.completedAt = completedAt
        self.accumulatedSeconds = accumulatedSeconds
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Calculated remaining seconds based on current state
    var remainingSeconds: Int {
        switch status {
        case .idle:
            return durationSeconds
        case .running:
            guard let startedAt = startedAt else { return durationSeconds }
            let elapsed = Int(Date().timeIntervalSince(startedAt)) + accumulatedSeconds
            return max(0, durationSeconds - elapsed)
        case .paused:
            return max(0, durationSeconds - accumulatedSeconds)
        case .completed:
            return 0
        }
    }

    /// Calculated end date for Live Activities (only valid when running)
    var timerEndDate: Date? {
        guard status == .running, let startedAt = startedAt else { return nil }
        let remainingFromStart = durationSeconds - accumulatedSeconds
        return startedAt.addingTimeInterval(TimeInterval(remainingFromStart))
    }

    /// Progress from 0.0 to 1.0
    var progress: Double {
        guard durationSeconds > 0 else { return 0 }
        let elapsed = durationSeconds - remainingSeconds
        return min(1.0, Double(elapsed) / Double(durationSeconds))
    }
}
