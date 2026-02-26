import Foundation
import SwiftUI
import Combine

@MainActor
final class FixTimerManager: ObservableObject {
    // MARK: - Published State

    @Published private(set) var session: TimerSession?
    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var progress: Double = 0
    @Published private(set) var isTimerRequired: Bool = false
    @Published private(set) var timerDuration: Int = 0

    var status: TimerStatus {
        session?.status ?? .idle
    }

    var isRunning: Bool {
        status == .running
    }

    var isPaused: Bool {
        status == .paused
    }

    var isCompleted: Bool {
        status == .completed
    }

    var canMarkApplied: Bool {
        // If timer is required, must be completed to mark as applied
        !isTimerRequired || isCompleted
    }

    // MARK: - Formatted Display

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progressBarString: String {
        let totalBars = 20
        let filledBars = Int(progress * Double(totalBars))
        let filled = String(repeating: "\u{2588}", count: filledBars)  // Full block
        let empty = String(repeating: "\u{2591}", count: totalBars - filledBars)  // Light shade
        return "[\(filled)\(empty)]"
    }

    // MARK: - Private

    private let timerService: TimerService
    private let notificationService = NotificationService.shared
    private let liveActivityService = LiveActivityService.shared
    private var tickTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var currentFixNumber: String = ""
    private var currentFixPrompt: String = ""
    private var notificationIdentifier: String?

    // Callbacks for external coordination
    var onTimerComplete: (() -> Void)?

    // MARK: - Initialization

    init(timerService: TimerService) {
        self.timerService = timerService
        notificationService.setupCategories()
        liveActivityService.cleanupStaleActivities()
    }

    // MARK: - Setup

    /// Initialize timer manager for a specific fix and fix completion
    func setup(for fix: Fix, fixCompletionId: UUID) async {
        // Store fix info for notifications and Live Activities
        let hash = abs(fix.id.hashValue)
        currentFixNumber = String(format: "%04d", hash % 10000)
        currentFixPrompt = fix.prompt
        notificationIdentifier = "timer_\(fixCompletionId.uuidString)"

        // Check if fix requires a timer
        if let duration = timerService.parseTimerDuration(from: fix.prompt) {
            isTimerRequired = true
            timerDuration = duration

            do {
                // Get or create session
                let session = try await timerService.getOrCreateSession(
                    for: fixCompletionId,
                    durationSeconds: duration
                )
                self.session = session
                updateDisplayFromSession()

                // If timer was running, resume tick, notification, and Live Activity
                if session.status == .running {
                    startTick()
                    await scheduleCompletionNotification()
                    startLiveActivity()
                }
            } catch {
                print("Failed to setup timer session: \(error)")
            }
        } else {
            isTimerRequired = false
            timerDuration = 0
            session = nil
        }
    }

    /// Reset for a new fix
    func reset() {
        stopTick()
        cancelNotification()
        liveActivityService.endCurrentActivity()
        session = nil
        remainingSeconds = 0
        progress = 0
        isTimerRequired = false
        timerDuration = 0
        currentFixNumber = ""
        currentFixPrompt = ""
        notificationIdentifier = nil
    }

    // MARK: - Timer Controls

    func startTimer() async {
        guard let session = session else { return }

        do {
            try await timerService.startTimer(session)
            self.session = session
            updateDisplayFromSession()
            startTick()
            await scheduleCompletionNotification()
            startLiveActivity()
        } catch {
            print("Failed to start timer: \(error)")
        }
    }

    func pauseTimer() async {
        guard let session = session else { return }

        do {
            try await timerService.pauseTimer(session)
            self.session = session
            updateDisplayFromSession()
            stopTick()
            cancelNotification()
            await pauseLiveActivity()
        } catch {
            print("Failed to pause timer: \(error)")
        }
    }

    func resumeTimer() async {
        await startTimer()
    }

    func resetTimer() async {
        guard let session = session else { return }

        do {
            try await timerService.resetTimer(session)
            self.session = session
            updateDisplayFromSession()
            stopTick()
            cancelNotification()
            liveActivityService.endCurrentActivity()
        } catch {
            print("Failed to reset timer: \(error)")
        }
    }

    // MARK: - Private Helpers

    private func startTick() {
        stopTick()

        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    private func stopTick() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    private func tick() {
        guard let session = session, session.status == .running else {
            stopTick()
            return
        }

        updateDisplayFromSession()

        // Check if timer completed
        if remainingSeconds <= 0 {
            Task {
                await completeTimer()
            }
        }
    }

    private func completeTimer() async {
        guard let session = session else { return }

        do {
            try await timerService.completeTimer(session)
            self.session = session
            updateDisplayFromSession()
            stopTick()
            cancelNotification()  // Cancel since we're handling completion in-app
            liveActivityService.endCurrentActivityWithDelay(seconds: 5)  // Show completion briefly

            // Notify completion
            onTimerComplete?()
        } catch {
            print("Failed to complete timer: \(error)")
        }
    }

    // MARK: - Notification Helpers

    private func scheduleCompletionNotification() async {
        guard let identifier = notificationIdentifier, remainingSeconds > 0 else { return }

        do {
            try await notificationService.scheduleTimerCompletion(
                fixNumber: currentFixNumber,
                in: TimeInterval(remainingSeconds),
                identifier: identifier
            )
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }

    private func cancelNotification() {
        guard let identifier = notificationIdentifier else { return }
        notificationService.cancelTimerNotification(identifier: identifier)
    }

    // MARK: - Live Activity Helpers

    private func startLiveActivity() {
        guard let session = session, let endDate = session.timerEndDate else { return }

        liveActivityService.startTimerActivity(
            fixNumber: currentFixNumber,
            fixPrompt: currentFixPrompt,
            durationSeconds: timerDuration,
            endDate: endDate
        )
    }

    private func pauseLiveActivity() async {
        await liveActivityService.pauseTimerActivity(
            remainingSeconds: remainingSeconds,
            totalDurationSeconds: timerDuration
        )
    }

    private func updateDisplayFromSession() {
        guard let session = session else {
            remainingSeconds = timerDuration
            progress = 0
            return
        }

        remainingSeconds = session.remainingSeconds
        progress = session.progress
    }

    deinit {
        tickTimer?.invalidate()
    }
}
