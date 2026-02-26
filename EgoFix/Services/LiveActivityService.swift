import Foundation
import ActivityKit

// EgoFixWidgetAttributes is defined in Shared/LiveActivityAttributes.swift
// That file must be added to BOTH targets (EgoFix and EgoFixWidgetExtension)

/// Manages Live Activities for timer display on Dynamic Island and Lock Screen
final class LiveActivityService {
    static let shared = LiveActivityService()

    private var currentActivity: Activity<EgoFixWidgetAttributes>?

    private init() {}

    // MARK: - Availability

    /// Check if Live Activities are supported and enabled
    var isAvailable: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    // MARK: - Start Activity

    /// Start a new Live Activity for a timer
    @discardableResult
    func startTimerActivity(
        fixNumber: String,
        fixPrompt: String,
        durationSeconds: Int,
        endDate: Date
    ) -> Bool {
        guard isAvailable else {
            print("LiveActivityService: Live Activities not available")
            return false
        }

        // End any existing activity first
        endCurrentActivity()

        let attributes = EgoFixWidgetAttributes(
            fixNumber: fixNumber,
            fixPrompt: fixPrompt,
            totalDurationSeconds: durationSeconds
        )

        let progress = 0.0
        let contentState = EgoFixWidgetAttributes.ContentState(
            timerEndDate: endDate,
            isPaused: false,
            remainingSeconds: durationSeconds,
            progress: progress
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: endDate.addingTimeInterval(60)),
                pushType: nil
            )
            currentActivity = activity
            print("LiveActivityService: Started activity \(activity.id)")
            return true
        } catch {
            print("LiveActivityService: Failed to start activity: \(error)")
            return false
        }
    }

    // MARK: - Update Activity

    /// Update the Live Activity with new timer state
    func updateTimerActivity(
        endDate: Date,
        isPaused: Bool,
        remainingSeconds: Int,
        totalDurationSeconds: Int
    ) async {
        guard let activity = currentActivity else { return }

        let elapsed = totalDurationSeconds - remainingSeconds
        let progress = totalDurationSeconds > 0 ? Double(elapsed) / Double(totalDurationSeconds) : 0

        let contentState = EgoFixWidgetAttributes.ContentState(
            timerEndDate: endDate,
            isPaused: isPaused,
            remainingSeconds: remainingSeconds,
            progress: min(1.0, progress)
        )

        await activity.update(
            ActivityContent(
                state: contentState,
                staleDate: isPaused ? nil : endDate.addingTimeInterval(60)
            )
        )
    }

    /// Pause the timer Live Activity
    func pauseTimerActivity(remainingSeconds: Int, totalDurationSeconds: Int) async {
        await updateTimerActivity(
            endDate: Date(),
            isPaused: true,
            remainingSeconds: remainingSeconds,
            totalDurationSeconds: totalDurationSeconds
        )
    }

    /// Resume the timer Live Activity
    func resumeTimerActivity(
        endDate: Date,
        remainingSeconds: Int,
        totalDurationSeconds: Int
    ) async {
        await updateTimerActivity(
            endDate: endDate,
            isPaused: false,
            remainingSeconds: remainingSeconds,
            totalDurationSeconds: totalDurationSeconds
        )
    }

    // MARK: - End Activity

    /// End the current Live Activity
    func endCurrentActivity() {
        guard let activity = currentActivity else { return }

        Task {
            // Create final state showing completion
            let finalState = EgoFixWidgetAttributes.ContentState(
                timerEndDate: Date(),
                isPaused: false,
                remainingSeconds: 0,
                progress: 1.0
            )

            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
            print("LiveActivityService: Ended activity \(activity.id)")
        }

        currentActivity = nil
    }

    /// End activity with a delay (shows completion state briefly)
    func endCurrentActivityWithDelay(seconds: TimeInterval = 3) {
        guard let activity = currentActivity else { return }

        Task {
            let finalState = EgoFixWidgetAttributes.ContentState(
                timerEndDate: Date(),
                isPaused: false,
                remainingSeconds: 0,
                progress: 1.0
            )

            await activity.end(
                ActivityContent(state: finalState, staleDate: Date().addingTimeInterval(seconds)),
                dismissalPolicy: .after(Date().addingTimeInterval(seconds))
            )
            print("LiveActivityService: Ending activity \(activity.id) after \(seconds)s")
        }

        currentActivity = nil
    }

    // MARK: - Query

    /// Check if there's an active timer Live Activity
    var hasActiveActivity: Bool {
        currentActivity != nil
    }

    /// Get all active EgoFix activities
    func getAllActivities() -> [Activity<EgoFixWidgetAttributes>] {
        Activity<EgoFixWidgetAttributes>.activities
    }

    /// Clean up any stale activities from previous sessions
    func cleanupStaleActivities() {
        for activity in Activity<EgoFixWidgetAttributes>.activities {
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        currentActivity = nil
    }
}
