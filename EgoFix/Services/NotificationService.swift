import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permission

    /// Request notification permission
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }

    /// Check current authorization status
    func checkPermission() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Timer Notifications

    /// Schedule a notification for timer completion
    func scheduleTimerCompletion(
        fixNumber: String,
        in seconds: TimeInterval,
        identifier: String
    ) async throws {
        // Request permission if not granted
        let status = await checkPermission()
        if status == .notDetermined {
            let granted = await requestPermission()
            guard granted else { return }
        } else if status == .denied {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Timer Complete"
        content.body = "FIX #\(fixNumber) timer has finished. Time to mark your outcome."
        content.sound = .default
        content.categoryIdentifier = "TIMER_COMPLETE"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, seconds),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    /// Cancel a scheduled timer notification
    func cancelTimerNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Cancel all timer notifications
    func cancelAllTimerNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    // MARK: - Daily Reminder

    /// Schedule a daily fix reminder at a specific time
    func scheduleDailyReminder(hour: Int, minute: Int) async throws {
        // Request permission if not granted
        let status = await checkPermission()
        if status == .notDetermined {
            let granted = await requestPermission()
            guard granted else { return }
        } else if status == .denied {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Daily Fix Available"
        content.body = "Your daily fix is ready. Time to debug your ego."
        content.sound = .default
        content.categoryIdentifier = "DAILY_REMINDER"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    /// Cancel the daily reminder
    func cancelDailyReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
    }

    // MARK: - Fix Notifications

    /// Schedule a mid-day reminder with the fix prompt (fires ~4 hours after accept)
    func scheduleFixReminder(
        fixPrompt: String,
        identifier: String
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Fix Active"
        content.body = fixPrompt
        content.sound = .default
        content.categoryIdentifier = "FIX_REMINDER"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 4 * 60 * 60,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    /// Schedule an evening check-in notification (fires at 8 PM today or tomorrow)
    func scheduleEveningCheckIn(identifier: String) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Ready to check in?"
        content.body = "How did today's fix go?"
        content.sound = .default
        content.categoryIdentifier = "EVENING_CHECKIN"

        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
    }

    /// Cancel fix-related notifications
    func cancelFixNotifications(fixId: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [
            "fix_midday_\(fixId)",
            "fix_evening_\(fixId)"
        ])
    }

    // MARK: - Notification Categories

    /// Setup notification categories for actions
    func setupCategories() {
        let timerCategory = UNNotificationCategory(
            identifier: "TIMER_COMPLETE",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let dailyCategory = UNNotificationCategory(
            identifier: "DAILY_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let fixCategory = UNNotificationCategory(
            identifier: "FIX_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let checkInCategory = UNNotificationCategory(
            identifier: "EVENING_CHECKIN",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([timerCategory, dailyCategory, fixCategory, checkInCategory])
    }
}
