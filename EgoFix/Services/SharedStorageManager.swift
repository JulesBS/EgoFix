import Foundation
import WidgetKit

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
}

/// Manages shared storage via App Group UserDefaults
final class SharedStorageManager {
    static let shared = SharedStorageManager()

    /// App Group identifier - must match the one configured in Xcode
    private let appGroupIdentifier = "group.egofix.shared"

    private let fixStateKey = "fixState"

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {}

    // MARK: - Fix State

    /// Save current fix state for widget access
    func saveFixState(_ state: SharedFixState) {
        guard let defaults = sharedDefaults else {
            #if DEBUG
            print("SharedStorageManager: Could not access App Group UserDefaults")
            #endif
            return
        }

        do {
            let data = try JSONEncoder().encode(state)
            defaults.set(data, forKey: fixStateKey)
            defaults.synchronize()

            // Trigger widget refresh
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            #if DEBUG
            print("SharedStorageManager: Failed to encode fix state: \(error)")
            #endif
        }
    }

    /// Load fix state from shared storage
    func loadFixState() -> SharedFixState? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: fixStateKey) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(SharedFixState.self, from: data)
        } catch {
            #if DEBUG
            print("SharedStorageManager: Failed to decode fix state: \(error)")
            #endif
            return nil
        }
    }

    /// Clear fix state
    func clearFixState() {
        sharedDefaults?.removeObject(forKey: fixStateKey)
        sharedDefaults?.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Convenience Methods

    /// Update fix state with current fix information
    func updateForFix(prompt: String, fixNumber: String, outcome: FixOutcome) {
        let state = SharedFixState(
            hasFixToday: true,
            fixPrompt: prompt,
            fixNumber: fixNumber,
            outcome: outcome.rawValue,
            timer: nil
        )
        saveFixState(state)
    }

    /// Update fix state with timer information
    func updateForTimer(
        prompt: String,
        fixNumber: String,
        outcome: FixOutcome,
        timerEndDate: Date?,
        isPaused: Bool,
        isCompleted: Bool,
        durationSeconds: Int,
        remainingSeconds: Int
    ) {
        var timerState: SharedTimerState? = nil

        if let endDate = timerEndDate {
            timerState = SharedTimerState(
                endDate: endDate,
                isPaused: isPaused,
                isCompleted: isCompleted,
                durationSeconds: durationSeconds,
                remainingSeconds: remainingSeconds
            )
        } else if isCompleted || remainingSeconds > 0 {
            // Timer exists but not running
            timerState = SharedTimerState(
                endDate: Date(),
                isPaused: isPaused,
                isCompleted: isCompleted,
                durationSeconds: durationSeconds,
                remainingSeconds: remainingSeconds
            )
        }

        let state = SharedFixState(
            hasFixToday: true,
            fixPrompt: prompt,
            fixNumber: fixNumber,
            outcome: outcome.rawValue,
            timer: timerState
        )
        saveFixState(state)
    }

    /// Clear state when no fix is available
    func updateNoFix() {
        saveFixState(SharedFixState.empty)
    }

    /// Update when fix is completed
    func updateCompleted(outcome: FixOutcome) {
        if let current = loadFixState() {
            let state = SharedFixState(
                hasFixToday: true,
                fixPrompt: current.fixPrompt,
                fixNumber: current.fixNumber,
                outcome: outcome.rawValue,
                timer: nil,
                missionState: "done",
                bugSlug: current.bugSlug,
                typeLabel: current.typeLabel,
                severity: current.severity
            )
            saveFixState(state)
        }
    }

    // MARK: - Mission State Convenience Methods

    /// Update widget for mission waiting state (pre-accept briefing)
    func updateForMissionWaiting(bugSlug: String, typeLabel: String, severity: String, fixNumber: String) {
        let state = SharedFixState(
            hasFixToday: true,
            fixNumber: fixNumber,
            outcome: "pending",
            missionState: "waiting",
            bugSlug: bugSlug,
            typeLabel: typeLabel,
            severity: severity
        )
        saveFixState(state)
    }

    /// Update widget for active mission state
    func updateForMissionActive(
        prompt: String,
        fixNumber: String,
        missionEndDate: Date?,
        inlineComment: String?,
        educationTeaser: String?,
        bugSlug: String?,
        typeLabel: String?,
        severity: String?
    ) {
        let state = SharedFixState(
            hasFixToday: true,
            fixPrompt: prompt,
            fixNumber: fixNumber,
            outcome: "pending",
            missionState: "active",
            bugSlug: bugSlug,
            typeLabel: typeLabel,
            severity: severity,
            missionEndDate: missionEndDate,
            educationTeaser: educationTeaser,
            inlineComment: inlineComment
        )
        saveFixState(state)
    }

    /// Update widget for check-in state
    func updateForMissionCheckIn(fixNumber: String) {
        if let current = loadFixState() {
            let state = SharedFixState(
                hasFixToday: true,
                fixPrompt: current.fixPrompt,
                fixNumber: fixNumber,
                outcome: "pending",
                missionState: "checkIn",
                bugSlug: current.bugSlug,
                typeLabel: current.typeLabel,
                severity: current.severity
            )
            saveFixState(state)
        }
    }
}
