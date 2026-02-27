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

    // MARK: - Helpers

    private static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
