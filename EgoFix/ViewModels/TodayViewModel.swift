import Foundation
import SwiftUI
import Combine

enum TodayViewState {
    case loading
    case noFix
    case fixAvailable(FixCompletion, Fix)
    case completed(FixOutcome, String?)  // outcome + optional micro-education tidbit
    case pattern(DetectedPattern)
}

struct WeeklySummaryData: Identifiable {
    let id = UUID()
    let applied: Int
    let skipped: Int
    let failed: Int

    var total: Int { applied + skipped + failed }

    var comment: String {
        if failed > applied {
            return "// Rough week. The data doesn't judge."
        } else if applied > skipped + failed {
            return "// Solid week. Keep going."
        } else if skipped > applied {
            return "// A lot of skips. No judgment — sometimes you're not ready."
        } else {
            return "// Logged. Patterns emerge over time."
        }
    }
}

@MainActor
final class TodayViewModel: ObservableObject {
    @Published var state: TodayViewState = .loading
    @Published var currentFix: Fix?
    @Published var currentCompletion: FixCompletion?
    @Published var currentBugTitle: String?
    @Published private(set) var interactionManager: FixInteractionManager
    @Published var showWeeklyDiagnostic = false
    @Published var weeklySummary: WeeklySummaryData?

    private let dailyFixService: DailyFixService
    private let fixRepository: FixRepository
    private let bugRepository: BugRepository
    private let patternSurfacingService: PatternSurfacingService
    private let timerService: TimerService
    private let microEducationService: MicroEducationService
    private let streakService: StreakService
    private let userRepository: UserRepository
    private let weeklyDiagnosticService: WeeklyDiagnosticService?
    private let fixCompletionRepository: FixCompletionRepository?
    private let diagnosticEngine: DiagnosticEngine?
    private let sharedStorage = SharedStorageManager.shared

    init(
        dailyFixService: DailyFixService,
        fixRepository: FixRepository,
        bugRepository: BugRepository,
        patternSurfacingService: PatternSurfacingService,
        timerService: TimerService,
        microEducationService: MicroEducationService,
        streakService: StreakService,
        userRepository: UserRepository,
        weeklyDiagnosticService: WeeklyDiagnosticService? = nil,
        fixCompletionRepository: FixCompletionRepository? = nil,
        diagnosticEngine: DiagnosticEngine? = nil
    ) {
        self.dailyFixService = dailyFixService
        self.fixRepository = fixRepository
        self.bugRepository = bugRepository
        self.patternSurfacingService = patternSurfacingService
        self.timerService = timerService
        self.microEducationService = microEducationService
        self.streakService = streakService
        self.userRepository = userRepository
        self.weeklyDiagnosticService = weeklyDiagnosticService
        self.fixCompletionRepository = fixCompletionRepository
        self.diagnosticEngine = diagnosticEngine
        self.interactionManager = FixInteractionManager(timerService: timerService)
    }

    // MARK: - Widget Sync

    private func syncWidgetState() {
        guard let fix = currentFix else {
            sharedStorage.updateNoFix()
            return
        }

        let hash = abs(fix.id.hashValue)
        let fixNumber = String(format: "%04d", hash % 10000)
        let outcome = currentCompletion?.outcome ?? .pending

        if interactionManager.isTimerRequired {
            sharedStorage.updateForTimer(
                prompt: fix.prompt,
                fixNumber: fixNumber,
                outcome: outcome,
                timerEndDate: interactionManager.session?.timerEndDate,
                isPaused: interactionManager.isTimerPaused,
                isCompleted: interactionManager.isTimerCompleted,
                durationSeconds: interactionManager.timerDuration,
                remainingSeconds: interactionManager.remainingSeconds
            )
        } else {
            sharedStorage.updateForFix(
                prompt: fix.prompt,
                fixNumber: fixNumber,
                outcome: outcome
            )
        }
    }

    func checkWeeklyDiagnostic() async {
        guard let service = weeklyDiagnosticService else { return }
        do {
            if try await service.shouldPromptDiagnostic() {
                showWeeklyDiagnostic = true
            }
        } catch {
            // Handle silently
        }
    }

    func onDiagnosticComplete() async {
        showWeeklyDiagnostic = false

        // Run pattern detection after weekly diagnostic
        await runDiagnosticsIfNeeded()

        // Calculate and show weekly summary
        if let summary = await calculateWeeklySummary() {
            weeklySummary = summary
        }
    }

    /// Run pattern detection diagnostics if scheduled
    private func runDiagnosticsIfNeeded() async {
        guard let engine = diagnosticEngine,
              let user = try? await userRepository.get() else { return }

        do {
            _ = try await engine.runDiagnostics(for: user.id)
        } catch {
            // Handle silently - pattern detection is non-critical
        }
    }

    /// Check if diagnostics should run (>7 days since last) and run if needed
    private func checkAndRunScheduledDiagnostics() async {
        guard let engine = diagnosticEngine,
              let user = try? await userRepository.get() else { return }

        do {
            if try await engine.shouldRunDiagnostics(for: user.id) {
                _ = try await engine.runDiagnostics(for: user.id)
            }
        } catch {
            // Handle silently - pattern detection is non-critical
        }
    }

    func dismissWeeklySummary() {
        weeklySummary = nil
    }

    private func calculateWeeklySummary() async -> WeeklySummaryData? {
        guard let repo = fixCompletionRepository,
              let user = try? await userRepository.get() else { return nil }

        do {
            let completions = try await repo.getForUser(user.id)

            // Filter to this week
            let calendar = Calendar.current
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
            let thisWeekCompletions = completions.filter { $0.completedAt ?? $0.assignedAt >= startOfWeek }

            let applied = thisWeekCompletions.filter { $0.outcome == .applied }.count
            let skipped = thisWeekCompletions.filter { $0.outcome == .skipped }.count
            let failed = thisWeekCompletions.filter { $0.outcome == .failed }.count

            return WeeklySummaryData(applied: applied, skipped: skipped, failed: failed)
        } catch {
            return nil
        }
    }

    func loadTodaysFix() async {
        state = .loading
        interactionManager.reset()

        // Run diagnostics on launch if >7 days since last run
        await checkAndRunScheduledDiagnostics()

        do {
            // Check for pattern to show before fix
            if let pattern = try await patternSurfacingService.shouldShowPatternBeforeFix() {
                state = .pattern(pattern)
                return
            }

            // Try to get existing fix for today
            if let completion = try await dailyFixService.getTodaysFix() {
                if let fix = try await fixRepository.getById(completion.fixId) {
                    currentCompletion = completion
                    currentFix = fix
                    currentBugTitle = await fetchBugTitle(for: fix.bugId)
                    await interactionManager.setup(for: fix, fixCompletionId: completion.id)
                    state = .fixAvailable(completion, fix)
                    syncWidgetState()
                    return
                }
            }

            // Assign new daily fix
            if let completion = try await dailyFixService.assignDailyFix() {
                if let fix = try await fixRepository.getById(completion.fixId) {
                    currentCompletion = completion
                    currentFix = fix
                    currentBugTitle = await fetchBugTitle(for: fix.bugId)
                    await interactionManager.setup(for: fix, fixCompletionId: completion.id)
                    state = .fixAvailable(completion, fix)
                    syncWidgetState()
                    return
                }
            }

            state = .noFix
            sharedStorage.updateNoFix()

        } catch {
            state = .noFix
            sharedStorage.updateNoFix()
        }
    }

    func markOutcome(_ outcome: FixOutcome) async {
        guard let completion = currentCompletion else { return }

        do {
            // Generate outcome data from interaction manager
            let outcomeData = interactionManager.generateOutcomeData()
            try await dailyFixService.markOutcome(completion.id, outcome: outcome, outcomeData: outcomeData)

            // Record streak engagement
            if let user = try? await userRepository.get() {
                try? await streakService.recordEngagement(userId: user.id)
            }

            // Fetch micro-education tidbit
            var tidbitText: String?
            if let fix = currentFix, let bug = try? await bugRepository.getById(fix.bugId) {
                let trigger: EducationTrigger
                switch outcome {
                case .applied: trigger = .postApply
                case .skipped: trigger = .postSkip
                case .failed: trigger = .postCrash
                case .pending: trigger = .general
                }
                if let tidbit = try? await microEducationService.getRandomTidbit(bugSlug: bug.slug, trigger: trigger) {
                    tidbitText = tidbit.body
                }
            }

            state = .completed(outcome, tidbitText)
            sharedStorage.updateCompleted(outcome: outcome)

            // Check for pattern to show after fix
            if let pattern = try await patternSurfacingService.shouldShowPatternAfterFix() {
                state = .pattern(pattern)
            }
        } catch {
            // Handle error silently - state remains unchanged
        }
    }

    func dismissPattern(_ patternId: UUID) async {
        do {
            try await patternSurfacingService.dismissPattern(patternId)
            await loadTodaysFix()
        } catch {
            // Handle error silently
        }
    }

    func acknowledgePattern(_ patternId: UUID) async {
        do {
            try await patternSurfacingService.markPatternShown(patternId)
            await loadTodaysFix()
        } catch {
            // Handle error silently
        }
    }

    private func fetchBugTitle(for bugId: UUID) async -> String? {
        guard let bug = try? await bugRepository.getById(bugId) else { return nil }
        return bug.title
    }
}
