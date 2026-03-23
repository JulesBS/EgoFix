import Foundation
import SwiftUI
import Combine

/// Tracks app progression milestones and controls when features unlock.
/// Persists all state via @AppStorage (UserDefaults) so it survives restarts
/// without needing SwiftData queries on every launch.
@MainActor
final class AppProgressTracker: ObservableObject {

    // MARK: - Persisted Counters

    @AppStorage("apt_totalFixesCompleted") var totalFixesCompleted: Int = 0
    @AppStorage("apt_firstDiagnosticCompleted") var firstDiagnosticCompleted: Bool = false
    @AppStorage("apt_firstPatternDetected") var firstPatternDetected: Bool = false
    @AppStorage("apt_daysActive") var daysActive: Int = 0
    @AppStorage("apt_lastActiveDate") var lastActiveDate: String = ""

    // MARK: - Mission Time Settings

    @AppStorage("apt_windDownTime") var windDownTime: String = "21:00"
    @AppStorage("apt_morningNotificationTime") var morningNotificationTime: String = "08:00"
    @AppStorage("apt_antiNotificationsEnabled") var antiNotificationsEnabled: Bool = true

    // MARK: - One-Time Unlock Prompt Flags

    @AppStorage("hasSeenHistoryUnlock") var hasSeenHistoryUnlock: Bool = false
    @AppStorage("hasSeenPatternsUnlock") var hasSeenPatternsUnlock: Bool = false
    @AppStorage("hasSeenBugLibraryUnlock") var hasSeenBugLibraryUnlock: Bool = false

    // MARK: - Computed Unlock States

    var isHistoryUnlocked: Bool {
        totalFixesCompleted >= 3
    }

    var isPatternsUnlocked: Bool {
        firstPatternDetected
    }

    var isBugLibraryUnlocked: Bool {
        totalFixesCompleted >= 7
    }

    var isFullNavUnlocked: Bool {
        daysActive >= 14 && totalFixesCompleted >= 10
    }

    // MARK: - One-Time Prompts

    var shouldShowHistoryUnlockPrompt: Bool {
        isHistoryUnlocked && !hasSeenHistoryUnlock
    }

    var shouldShowPatternsUnlockPrompt: Bool {
        isPatternsUnlocked && !hasSeenPatternsUnlock
    }

    var shouldShowBugLibraryUnlockPrompt: Bool {
        isBugLibraryUnlocked && !hasSeenBugLibraryUnlock
    }

    // MARK: - Actions

    func recordFixCompletion() {
        totalFixesCompleted += 1
        objectWillChange.send()
    }

    func recordDiagnosticCompleted() {
        if !firstDiagnosticCompleted {
            firstDiagnosticCompleted = true
            objectWillChange.send()
        }
    }

    func recordPatternDetected() {
        if !firstPatternDetected {
            firstPatternDetected = true
            objectWillChange.send()
        }
    }

    func recordDayActive() {
        let today = Self.todayString()
        if lastActiveDate != today {
            lastActiveDate = today
            daysActive += 1
            objectWillChange.send()
        }
    }

    func markHistoryUnlockSeen() {
        hasSeenHistoryUnlock = true
        objectWillChange.send()
    }

    func markPatternsUnlockSeen() {
        hasSeenPatternsUnlock = true
        objectWillChange.send()
    }

    func markBugLibraryUnlockSeen() {
        hasSeenBugLibraryUnlock = true
        objectWillChange.send()
    }

    // MARK: - Mission Time Helpers

    /// Today's wind-down date, computed from the stored HH:mm string
    func windDownDateToday() -> Date {
        let components = parseTimeString(windDownTime)
        var calendar = Calendar.current
        calendar.timeZone = .current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        dateComponents.hour = components.hour
        dateComponents.minute = components.minute
        return calendar.date(from: dateComponents) ?? Date()
    }

    /// Today's morning notification date
    func morningDateToday() -> Date {
        let components = parseTimeString(morningNotificationTime)
        var calendar = Calendar.current
        calendar.timeZone = .current
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        dateComponents.hour = components.hour
        dateComponents.minute = components.minute
        return calendar.date(from: dateComponents) ?? Date()
    }

    /// Parse "HH:mm" string into (hour, minute)
    func parseTimeString(_ timeString: String) -> (hour: Int, minute: Int) {
        let parts = timeString.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else {
            return (hour: 21, minute: 0) // default 9pm
        }
        return (hour: hour, minute: minute)
    }

    // MARK: - Helpers

    private static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
