//
//  SharedTypes.swift
//  EgoFixWidget
//
//  Shared data structures for App Group communication between app and widget
//

import Foundation

/// Shared data structures for App Group communication between app and widgets
struct SharedFixState: Codable {
    let hasFixToday: Bool
    let fixPrompt: String?
    let fixNumber: String?
    let outcome: String?  // pending/applied/skipped/failed
    let timer: SharedTimerState?
    let missionState: String?  // waiting/active/checkIn/done
    let bugSlug: String?
    let typeLabel: String?
    let severity: String?
    let missionEndDate: Date?
    let educationTeaser: String?
    let inlineComment: String?
    let updatedAt: Date

    init(
        hasFixToday: Bool = false,
        fixPrompt: String? = nil,
        fixNumber: String? = nil,
        outcome: String? = nil,
        timer: SharedTimerState? = nil,
        missionState: String? = nil,
        bugSlug: String? = nil,
        typeLabel: String? = nil,
        severity: String? = nil,
        missionEndDate: Date? = nil,
        educationTeaser: String? = nil,
        inlineComment: String? = nil
    ) {
        self.hasFixToday = hasFixToday
        self.fixPrompt = fixPrompt
        self.fixNumber = fixNumber
        self.outcome = outcome
        self.timer = timer
        self.missionState = missionState
        self.bugSlug = bugSlug
        self.typeLabel = typeLabel
        self.severity = severity
        self.missionEndDate = missionEndDate
        self.educationTeaser = educationTeaser
        self.inlineComment = inlineComment
        self.updatedAt = Date()
    }

    static var empty: SharedFixState {
        SharedFixState()
    }
}

struct SharedTimerState: Codable {
    let endDate: Date
    let isPaused: Bool
    let isCompleted: Bool
    let durationSeconds: Int
    let remainingSeconds: Int

    init(
        endDate: Date,
        isPaused: Bool = false,
        isCompleted: Bool = false,
        durationSeconds: Int,
        remainingSeconds: Int
    ) {
        self.endDate = endDate
        self.isPaused = isPaused
        self.isCompleted = isCompleted
        self.durationSeconds = durationSeconds
        self.remainingSeconds = remainingSeconds
    }

    var progress: Double {
        guard durationSeconds > 0 else { return 0 }
        let elapsed = durationSeconds - remainingSeconds
        return min(1.0, Double(elapsed) / Double(durationSeconds))
    }
}

/// Widget-side storage manager for reading shared state
final class WidgetStorageManager {
    static let shared = WidgetStorageManager()

    private let appGroupIdentifier = "group.egofix.shared"
    private let fixStateKey = "fixState"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {}

    /// Load fix state from shared storage
    func loadFixState() -> SharedFixState? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: fixStateKey) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(SharedFixState.self, from: data)
        } catch {
            print("WidgetStorageManager: Failed to decode fix state: \(error)")
            return nil
        }
    }
}
