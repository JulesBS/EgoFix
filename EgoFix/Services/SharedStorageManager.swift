import Foundation
import WidgetKit

/// Shared data structures for App Group communication between app and widgets
struct SharedFixState: Codable {
    let hasFixToday: Bool
    let fixPrompt: String?
    let fixNumber: String?
    let outcome: String?  // pending/applied/skipped/failed
    let timer: SharedTimerState?
    let updatedAt: Date

    init(
        hasFixToday: Bool = false,
        fixPrompt: String? = nil,
        fixNumber: String? = nil,
        outcome: String? = nil,
        timer: SharedTimerState? = nil
    ) {
        self.hasFixToday = hasFixToday
        self.fixPrompt = fixPrompt
        self.fixNumber = fixNumber
        self.outcome = outcome
        self.timer = timer
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
            print("SharedStorageManager: Could not access App Group UserDefaults")
            return
        }

        do {
            let data = try JSONEncoder().encode(state)
            defaults.set(data, forKey: fixStateKey)
            defaults.synchronize()

            // Trigger widget refresh
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("SharedStorageManager: Failed to encode fix state: \(error)")
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
            print("SharedStorageManager: Failed to decode fix state: \(error)")
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
                timer: nil
            )
            saveFixState(state)
        }
    }
}
