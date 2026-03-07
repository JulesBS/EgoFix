import Foundation
import SwiftUI
import Combine

enum TodayViewState {
    case loading
    case diagnostic                      // weekly diagnostic inline
    case diagnosticComplete              // diagnostic just finished, show summary
    case noFix
    case fixBriefing(FixCompletion, Fix)        // morning — see today's fix
    case fixEducation(FixCompletion, Fix, String) // post-accept — why this pattern exists
    case fixActive(FixCompletion, Fix)           // during day — fix accepted
    case checkIn(FixCompletion, Fix)            // evening — report outcome
    case fixAvailable(FixCompletion, Fix)       // for timed/quiz (immediate in-app)
    case completed(FixOutcome, String?)  // outcome + optional micro-education tidbit
    case debrief(DebriefContent)                // post-outcome insight
    case doneForToday                    // resting state after outcome
    case pattern(DetectedPattern)

    /// Stable key for animating transitions between states.
    var stateKey: String {
        switch self {
        case .loading: return "loading"
        case .diagnostic: return "diagnostic"
        case .diagnosticComplete: return "diagnosticComplete"
        case .noFix: return "noFix"
        case .fixBriefing: return "fixBriefing"
        case .fixEducation: return "fixEducation"
        case .fixActive: return "fixActive"
        case .checkIn: return "checkIn"
        case .fixAvailable: return "fixAvailable"
        case .completed: return "completed"
        case .debrief: return "debrief"
        case .doneForToday: return "doneForToday"
        case .pattern: return "pattern"
        }
    }
}

/// Content for the post-outcome debrief screen
struct DebriefContent: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let comment: String
    let template: DebriefTemplate

    enum DebriefTemplate {
        case comparisonToSelf   // 5+ completions for this bug
        case crossBug           // 2+ active bugs, 3+ completions this week
        case tomorrowPreview    // default/fallback
        case milestone          // fix 5, 10, 14, 21, 30
    }
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
    @Published var currentBugSlug: String?
    @Published private(set) var interactionManager: FixInteractionManager
    @Published var showWeeklyDiagnostic = false
    @Published var weeklySummary: WeeklySummaryData?

    // Header data
    @Published var currentVersion: String = "1.0"
    @Published var currentStreak: Int = 0
    @Published var currentIntensity: BugIntensity = .present

    // Status line — set once per session
    @Published var statusLine: String = "// System initializing..."

    // Soul reaction (visible before completion view appears)
    @Published var soulReaction: SoulReaction?

    // Done-for-today state
    @Published var lastOutcome: FixOutcome?
    @Published var doneStatusLine: String = ""

    // Inline diagnostic state
    @Published var diagnosticBugs: [DiagnosticBugState] = []
    @Published var diagnosticBugIndex: Int = 0
    @Published var diagnosticNeedsContext: Bool = false
    @Published var diagnosticResults: [(bugTitle: String, intensity: BugIntensity)] = []

    private let dailyFixService: DailyFixService
    private let fixRepository: FixRepository
    private let bugRepository: BugRepository
    private let patternSurfacingService: PatternSurfacingService
    private let timerService: TimerService
    private let microEducationService: MicroEducationService
    private let streakService: StreakService
    private let userRepository: UserRepository
    private let versionService: VersionService
    private let weeklyDiagnosticService: WeeklyDiagnosticService?
    private let fixCompletionRepository: FixCompletionRepository?
    private let diagnosticEngine: DiagnosticEngine?
    private let bugIntensityProvider: BugIntensityProvider?
    private let debriefService: DebriefService?
    private let sharedStorage = SharedStorageManager.shared
    private let progressTracker: AppProgressTracker?

    init(
        dailyFixService: DailyFixService,
        fixRepository: FixRepository,
        bugRepository: BugRepository,
        patternSurfacingService: PatternSurfacingService,
        timerService: TimerService,
        microEducationService: MicroEducationService,
        streakService: StreakService,
        userRepository: UserRepository,
        versionService: VersionService,
        weeklyDiagnosticService: WeeklyDiagnosticService? = nil,
        fixCompletionRepository: FixCompletionRepository? = nil,
        diagnosticEngine: DiagnosticEngine? = nil,
        bugIntensityProvider: BugIntensityProvider? = nil,
        debriefService: DebriefService? = nil,
        progressTracker: AppProgressTracker? = nil
    ) {
        self.dailyFixService = dailyFixService
        self.fixRepository = fixRepository
        self.bugRepository = bugRepository
        self.patternSurfacingService = patternSurfacingService
        self.timerService = timerService
        self.microEducationService = microEducationService
        self.streakService = streakService
        self.userRepository = userRepository
        self.versionService = versionService
        self.weeklyDiagnosticService = weeklyDiagnosticService
        self.fixCompletionRepository = fixCompletionRepository
        self.diagnosticEngine = diagnosticEngine
        self.bugIntensityProvider = bugIntensityProvider
        self.debriefService = debriefService
        self.progressTracker = progressTracker
        self.interactionManager = FixInteractionManager(timerService: timerService)
    }

    // MARK: - Header Data Loading

    /// Load version, streak, and intensity on appear.
    func loadHeaderData() async {
        // Track day active
        progressTracker?.recordDayActive()

        do {
            // Version
            currentVersion = (try? await versionService.getCurrentVersion()) ?? "1.0"

            // Streak
            if let user = try await userRepository.get() {
                if let info = try? await streakService.getStreakInfo(userId: user.id) {
                    currentStreak = info.currentStreak
                }

                // Intensity for primary bug
                if let priorities = user.bugPriorities.first,
                   let provider = bugIntensityProvider {
                    let bugId = priorities.bugId
                    currentIntensity = (try? await provider.currentIntensity(for: bugId, userId: user.id)) ?? .present

                    // Also fetch slug and title for soul + status line
                    if let bug = try? await bugRepository.getById(bugId) {
                        currentBugSlug = bug.slug
                        if currentBugTitle == nil {
                            currentBugTitle = bug.nickname
                        }
                    }
                }
            }

            // Status line — pick once per session
            let context: StatusLineProvider.StatusContext
            if currentStreak == 0 {
                context = .firstDay
            } else if currentStreak >= 7 {
                context = .longStreak(currentStreak)
            } else {
                context = .normal
            }
            statusLine = StatusLineProvider.line(
                for: currentIntensity,
                bugTitle: currentBugTitle ?? "The pattern",
                context: context
            )
        } catch {
            // Use defaults
        }
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

    // MARK: - Weekly Diagnostic

    func checkWeeklyDiagnostic() async {
        guard let service = weeklyDiagnosticService else { return }
        do {
            if try await service.shouldPromptDiagnostic() {
                let bugs = try await service.getBugsForDiagnostic()
                diagnosticBugs = bugs.map { DiagnosticBugState(id: $0.id, bug: $0) }
                diagnosticBugIndex = 0
                diagnosticNeedsContext = false
                diagnosticResults = []
                state = .diagnostic
            }
        } catch {
            // Handle silently
        }
    }

    var currentDiagnosticBug: DiagnosticBugState? {
        guard diagnosticBugIndex < diagnosticBugs.count else { return nil }
        return diagnosticBugs[diagnosticBugIndex]
    }

    var diagnosticRemainingCount: Int {
        max(0, diagnosticBugs.count - diagnosticBugIndex - 1)
    }

    func setDiagnosticIntensity(_ intensity: BugIntensity) {
        guard diagnosticBugIndex < diagnosticBugs.count else { return }
        diagnosticBugs[diagnosticBugIndex].intensity = intensity

        if intensity == .quiet {
            // Skip context for quiet bugs
            advanceDiagnostic()
        } else {
            diagnosticNeedsContext = true
        }
    }

    func setDiagnosticContext(_ context: EventContext) {
        guard diagnosticBugIndex < diagnosticBugs.count else { return }
        diagnosticBugs[diagnosticBugIndex].context = context
        diagnosticNeedsContext = false
        advanceDiagnostic()
    }

    func skipDiagnosticContext() {
        guard diagnosticBugIndex < diagnosticBugs.count else { return }
        diagnosticBugs[diagnosticBugIndex].context = .unknown
        diagnosticNeedsContext = false
        advanceDiagnostic()
    }

    private func advanceDiagnostic() {
        // Record result for summary
        if let current = currentDiagnosticBug, let intensity = current.intensity {
            diagnosticResults.append((bugTitle: current.bug.nickname, intensity: intensity))
        }

        if diagnosticBugIndex < diagnosticBugs.count - 1 {
            diagnosticBugIndex += 1
        } else {
            Task { await submitDiagnostic() }
        }
    }

    func skipDiagnostic() async {
        guard let service = weeklyDiagnosticService else { return }
        do {
            try await service.skipDiagnostic()
        } catch { }
        await loadTodaysFix()
    }

    private func submitDiagnostic() async {
        guard let service = weeklyDiagnosticService else { return }

        let responses = diagnosticBugs.compactMap { bug -> BugDiagnosticResponse? in
            guard let intensity = bug.intensity else { return nil }
            return BugDiagnosticResponse(
                bugId: bug.id,
                intensity: intensity,
                primaryContext: bug.context
            )
        }

        do {
            try await service.submitDiagnostic(responses: responses)
        } catch { }

        // Track diagnostic completion
        progressTracker?.recordDiagnosticCompleted()

        // Run pattern detection after weekly diagnostic
        await runDiagnosticsIfNeeded()

        state = .diagnosticComplete
    }

    func continuePastDiagnostic() async {
        // Calculate and show weekly summary
        if let summary = await calculateWeeklySummary() {
            weeklySummary = summary
        }
        await loadTodaysFix()
    }

    func onDiagnosticComplete() async {
        showWeeklyDiagnostic = false

        // Track diagnostic completion
        progressTracker?.recordDiagnosticCompleted()

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

    // MARK: - Fix Loading

    func loadTodaysFix() async {
        state = .loading
        interactionManager.reset()

        // Run diagnostics on launch if >7 days since last run
        await checkAndRunScheduledDiagnostics()

        do {
            // Check for pattern to show before fix
            if let pattern = try await patternSurfacingService.shouldShowPatternBeforeFix() {
                progressTracker?.recordPatternDetected()
                state = .pattern(pattern)
                return
            }

            // Try to get existing fix for today
            if let completion = try await dailyFixService.getTodaysFix() {
                // If already completed, go to done state
                if completion.outcome != .pending {
                    currentCompletion = completion
                    if let fix = try await fixRepository.getById(completion.fixId) {
                        currentFix = fix
                        currentBugTitle = await fetchBugTitle(for: fix.bugId)
                    }
                    lastOutcome = completion.outcome
                    doneStatusLine = doneStatusMessage(for: completion.outcome)
                    weeklySummary = await calculateWeeklySummary()
                    state = .doneForToday
                    return
                }

                if let fix = try await fixRepository.getById(completion.fixId) {
                    currentCompletion = completion
                    currentFix = fix
                    currentBugTitle = await fetchBugTitle(for: fix.bugId)
                    await interactionManager.setup(for: fix, fixCompletionId: completion.id)
                    state = routeFixState(completion: completion, fix: fix)
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
                    state = routeFixState(completion: completion, fix: fix)
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

    // MARK: - Outcome

    func markOutcome(_ outcome: FixOutcome) async {
        guard let completion = currentCompletion else { return }

        // Trigger soul reaction (soul stays on screen during transition)
        switch outcome {
        case .applied: soulReaction = .applied
        case .failed: soulReaction = .failed
        default: soulReaction = nil
        }

        do {
            // Generate outcome data from interaction manager
            let outcomeData = interactionManager.generateOutcomeData()
            try await dailyFixService.markOutcome(completion.id, outcome: outcome, outcomeData: outcomeData)

            // Record streak engagement
            if let user = try? await userRepository.get() {
                try? await streakService.recordEngagement(userId: user.id)
            }

            // Check version increment
            _ = try? await versionService.checkAndIncrementVersion()
            currentVersion = (try? await versionService.getCurrentVersion()) ?? currentVersion

            // Refresh streak
            if let user = try? await userRepository.get(),
               let info = try? await streakService.getStreakInfo(userId: user.id) {
                currentStreak = info.currentStreak
            }

            // Fetch micro-education tidbit — only for immediate flow (timed/quiz).
            // Day-long fixes get education at acceptance, not after outcome.
            var tidbitText: String?
            if let fix = currentFix,
               immediateInteractionTypes.contains(fix.interactionType),
               let bug = try? await bugRepository.getById(fix.bugId) {
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

            // End fix Live Activity if active
            LiveActivityService.shared.endCurrentActivity()

            state = .completed(outcome, tidbitText)
            lastOutcome = outcome
            sharedStorage.updateCompleted(outcome: outcome)

            // Track progression
            progressTracker?.recordFixCompletion()

            // Check for pattern to show after fix
            if let pattern = try await patternSurfacingService.shouldShowPatternAfterFix() {
                progressTracker?.recordPatternDetected()
                state = .pattern(pattern)
                return
            }

            // Prepare done state data for auto-transition
            doneStatusLine = doneStatusMessage(for: outcome)
            weeklySummary = await calculateWeeklySummary()
        } catch {
            // Handle error silently - state remains unchanged
        }
    }

    /// Called by the view after the completion animation finishes.
    /// Routes through debrief if available, otherwise straight to done.
    func transitionToDone() {
        Task {
            await transitionToDebrief()
        }
    }

    // MARK: - Pattern Handling

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

    // MARK: - Fix Flow

    /// Determines whether a fix should use the day-long flow or immediate in-app flow.
    private var immediateInteractionTypes: Set<InteractionType> {
        [.timed, .quiz]
    }

    /// Route a pending fix to the appropriate state based on interaction type and acceptance status.
    private func routeFixState(completion: FixCompletion, fix: Fix) -> TodayViewState {
        // Timed/quiz are in-app interactions — use existing immediate flow
        if immediateInteractionTypes.contains(fix.interactionType) {
            return .fixAvailable(completion, fix)
        }

        // Day-long fix flow: briefing → active → check-in
        if completion.fixAcceptedAt != nil {
            return .fixActive(completion, fix)
        } else {
            return .fixBriefing(completion, fix)
        }
    }

    /// User taps "Accept fix" in the morning briefing.
    func acceptFix() async {
        guard let completion = currentCompletion, let fix = currentFix else { return }

        completion.fixAcceptedAt = Date()
        completion.updatedAt = Date()

        do {
            if let repo = fixCompletionRepository {
                try await repo.save(completion)
            }
        } catch {
            // Continue even if save fails — we have the in-memory state
        }

        // Start fix Live Activity
        let hash = abs(fix.id.hashValue)
        let fixNumber = String(format: "%04d", hash % 10000)
        LiveActivityService.shared.startFixActivity(
            fixNumber: fixNumber,
            fixPrompt: fix.prompt
        )

        // Schedule mid-day reminder notification
        await scheduleMidDayReminder(for: fix)

        // Schedule evening check-in notification
        await scheduleEveningCheckIn(for: fix)

        // Fetch micro-education to prime the user before they go face the day
        var educationBody: String?
        if let bug = try? await bugRepository.getById(fix.bugId) {
            if let tidbit = try? await microEducationService.getRandomTidbit(bugSlug: bug.slug, trigger: .general) {
                educationBody = tidbit.body
            }
        }

        if let body = educationBody {
            state = .fixEducation(completion, fix, body)
        } else {
            state = .fixActive(completion, fix)
        }
        syncWidgetState()
    }

    /// User taps "Continue →" after reading the pre-fix education.
    func continuePastEducation() {
        guard let completion = currentCompletion, let fix = currentFix else { return }
        state = .fixActive(completion, fix)
    }

    /// User taps "Check in" from fixActive state.
    func beginCheckIn() {
        guard let completion = currentCompletion, let fix = currentFix else { return }
        state = .checkIn(completion, fix)
    }

    /// Transition to debrief after completion, or skip debrief if no content.
    func transitionToDebrief() async {
        if let debrief = await generateDebrief() {
            state = .debrief(debrief)
        } else {
            state = .doneForToday
        }
    }

    /// Dismiss debrief and move to done-for-today.
    func dismissDebrief() {
        state = .doneForToday
    }

    private func generateDebrief() async -> DebriefContent? {
        guard let debriefService = debriefService else { return nil }
        guard let fix = currentFix,
              let bug = try? await bugRepository.getById(fix.bugId),
              let user = try? await userRepository.get() else { return nil }

        return await debriefService.generateDebrief(
            bugSlug: bug.slug,
            bugLabel: bug.slug,
            userId: user.id,
            lastOutcome: lastOutcome ?? .applied
        )
    }

    // MARK: - Fix Notifications

    private func scheduleMidDayReminder(for fix: Fix) async {
        let notificationService = NotificationService.shared
        let status = await notificationService.checkPermission()
        guard status == .authorized else { return }

        do {
            try await notificationService.scheduleFixReminder(
                fixPrompt: fix.prompt,
                identifier: "fix_midday_\(fix.id.uuidString)"
            )
        } catch { }
    }

    private func scheduleEveningCheckIn(for fix: Fix) async {
        let notificationService = NotificationService.shared
        let status = await notificationService.checkPermission()
        guard status == .authorized else { return }

        do {
            try await notificationService.scheduleEveningCheckIn(
                identifier: "fix_evening_\(fix.id.uuidString)"
            )
        } catch { }
    }

    // MARK: - Helpers

    private func fetchBugTitle(for bugId: UUID) async -> String? {
        guard let bug = try? await bugRepository.getById(bugId) else { return nil }
        return bug.nickname
    }

    private func doneStatusMessage(for outcome: FixOutcome) -> String {
        switch outcome {
        case .applied: return "// Fix applied. System stable."
        case .skipped: return "// Fix skipped. No judgment."
        case .failed: return "// Fix failed. Data logged."
        case .pending: return "// Standing by."
        }
    }
}
