import Foundation
import SwiftUI
import Combine

enum PredictPhase {
    case predicting
    case observing
}

@MainActor
final class FixInteractionManager: ObservableObject {
    // MARK: - Published State (General)

    @Published private(set) var currentFix: Fix?
    @Published private(set) var currentFixCompletionId: UUID?
    @Published private(set) var interactionType: InteractionType = .standard

    // MARK: - Published State (Timer - for timed interaction type)

    @Published private(set) var session: TimerSession?
    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var progress: Double = 0
    @Published private(set) var isTimerRequired: Bool = false
    @Published private(set) var timerDuration: Int = 0

    // MARK: - Published State (Multi-Step)

    @Published private(set) var currentStepIndex: Int = 0
    @Published private(set) var completedSteps: [MultiStepOutcome.StepCompletion] = []
    @Published private(set) var multiStepConfig: MultiStepConfig?

    // MARK: - Published State (Quiz)

    @Published private(set) var selectedOptionId: String?
    @Published private(set) var quizAnswered: Bool = false
    @Published private(set) var selectedQuizInsight: String?
    @Published private(set) var quizConfig: QuizConfig?

    // MARK: - Published State (Scenario)

    @Published private(set) var selectedScenarioOptionId: String?
    @Published private(set) var scenarioAnswered: Bool = false
    @Published private(set) var scenarioReflection: String?
    @Published private(set) var scenarioConfig: ScenarioConfig?

    // MARK: - Published State (Counter)

    @Published private(set) var counterValue: Int = 0
    @Published private(set) var counterHistory: [CounterOutcome.CountEvent] = []
    @Published private(set) var counterConfig: CounterConfig?

    // MARK: - Published State (Observation)

    @Published var observationReport: String = ""

    // MARK: - Published State (Abstain)

    @Published var abstainCompleted: Bool = false
    @Published private(set) var abstainTimerMode: Bool = false
    @Published private(set) var abstainDurationSeconds: Int = 0
    @Published private(set) var abstainRemainingSeconds: Int = 0
    @Published private(set) var abstainProgress: Double = 0
    @Published private(set) var abstainTimerRunning: Bool = false
    @Published private(set) var abstainSlips: [AbstainOutcome.SlipEvent] = []
    @Published private(set) var abstainConfig: AbstainConfig?

    // MARK: - Published State (Body)

    @Published private(set) var selectedBodyRegions: Set<String> = []
    @Published private(set) var selectedBodySensations: Set<String> = []
    @Published private(set) var bodyConfig: BodyConfig?

    // MARK: - Published State (Substitute)

    @Published var substituteCount: Int = 0
    @Published var urgeCount: Int = 0

    // MARK: - Published State (Journal)

    @Published var journalText: String = ""

    // MARK: - Published State (Predict)

    @Published var predictPhase: PredictPhase = .predicting
    @Published var predictionText: String = ""
    @Published var observationText: String = ""

    // MARK: - Published State (Audit)

    @Published var auditItems: [String: String] = [:]

    // MARK: - Timer Computed Properties

    var timerStatus: TimerStatus {
        session?.status ?? .idle
    }

    var isTimerRunning: Bool {
        timerStatus == .running
    }

    var isTimerPaused: Bool {
        timerStatus == .paused
    }

    var isTimerCompleted: Bool {
        timerStatus == .completed
    }

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progressBarString: String {
        let totalBars = 20
        let filledBars = Int(progress * Double(totalBars))
        let filled = String(repeating: "\u{2588}", count: filledBars)
        let empty = String(repeating: "\u{2591}", count: totalBars - filledBars)
        return "[\(filled)\(empty)]"
    }

    // MARK: - Multi-Step Computed Properties

    var currentStep: MultiStepConfig.StepItem? {
        guard let config = multiStepConfig,
              currentStepIndex < config.steps.count else {
            return nil
        }
        return config.steps[currentStepIndex]
    }

    var totalSteps: Int {
        multiStepConfig?.steps.count ?? 0
    }

    var allStepsProcessed: Bool {
        guard let config = multiStepConfig else { return false }
        return completedSteps.count >= config.steps.count
    }

    var hasCompletedAtLeastOneStep: Bool {
        completedSteps.contains { !$0.skipped }
    }

    var completedStepsCount: Int {
        completedSteps.filter { !$0.skipped }.count
    }

    var skippedStepsCount: Int {
        completedSteps.filter { $0.skipped }.count
    }

    // MARK: - Quiz Computed Properties

    var selectedQuizOption: QuizConfig.QuizOption? {
        guard let optionId = selectedOptionId,
              let config = quizConfig else { return nil }
        return config.options.first { $0.id == optionId }
    }

    // MARK: - Scenario Computed Properties

    var selectedScenarioOption: ScenarioConfig.ScenarioOption? {
        guard let optionId = selectedScenarioOptionId,
              let config = scenarioConfig else { return nil }
        return config.options.first { $0.id == optionId }
    }

    // MARK: - Counter Computed Properties

    var counterMeetsTarget: Bool {
        guard let config = counterConfig else { return true }

        if let min = config.minTarget, counterValue < min {
            return false
        }
        if let max = config.maxTarget, counterValue > max {
            return false
        }
        return true
    }

    // MARK: - Abstain Computed Properties

    var abstainFormattedTime: String {
        let hours = abstainRemainingSeconds / 3600
        let minutes = (abstainRemainingSeconds % 3600) / 60
        let seconds = abstainRemainingSeconds % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var abstainProgressBarString: String {
        let totalBars = 20
        let filledBars = Int(abstainProgress * Double(totalBars))
        let filled = String(repeating: "\u{2588}", count: filledBars)
        let empty = String(repeating: "\u{2591}", count: totalBars - filledBars)
        return "[\(filled)\(empty)]"
    }

    // MARK: - canMarkApplied Computed Property

    var canMarkApplied: Bool {
        switch interactionType {
        case .standard, .reversal:
            return true

        case .body:
            return !selectedBodyRegions.isEmpty && !selectedBodySensations.isEmpty

        case .timed:
            return !isTimerRequired || isTimerCompleted

        case .multiStep:
            return allStepsProcessed && hasCompletedAtLeastOneStep

        case .quiz:
            return quizAnswered

        case .scenario:
            return scenarioAnswered

        case .counter:
            return true

        case .observation:
            return !observationReport.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        case .abstain:
            return abstainCompleted

        case .substitute:
            return urgeCount > 0

        case .journal:
            return !journalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        case .predict:
            return predictPhase == .observing &&
                   !observationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        case .audit:
            return !auditItems.isEmpty && auditItems.values.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }
    }

    // MARK: - Private Properties

    private let timerService: TimerService
    private let notificationService = NotificationService.shared
    private let liveActivityService = LiveActivityService.shared
    private var tickTimer: Timer?
    private var abstainTickTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var currentFixNumber: String = ""
    private var currentFixPrompt: String = ""
    private var notificationIdentifier: String?

    // Callbacks for external coordination
    var onTimerComplete: (() -> Void)?
    var onInteractionComplete: (() -> Void)?

    // MARK: - Initialization

    init(timerService: TimerService) {
        self.timerService = timerService
        notificationService.setupCategories()
        liveActivityService.cleanupStaleActivities()
    }

    // MARK: - Setup

    /// Initialize interaction manager for a specific fix and fix completion
    func setup(for fix: Fix, fixCompletionId: UUID) async {
        // Store fix info
        currentFix = fix
        currentFixCompletionId = fixCompletionId
        interactionType = fix.interactionType

        currentFixNumber = fix.fixNumber
        currentFixPrompt = fix.prompt
        notificationIdentifier = "interaction_\(fixCompletionId.uuidString)"

        // Dispatch to appropriate setup based on interaction type
        switch fix.interactionType {
        case .standard:
            setupStandard()

        case .timed:
            await setupTimed(for: fix, fixCompletionId: fixCompletionId)

        case .multiStep:
            setupMultiStep(for: fix)

        case .quiz:
            setupQuiz(for: fix)

        case .scenario:
            setupScenario(for: fix)

        case .counter:
            setupCounter(for: fix)

        case .observation:
            observationReport = ""

        case .abstain:
            setupAbstain(for: fix)

        case .substitute:
            substituteCount = 0
            urgeCount = 0

        case .journal:
            journalText = ""

        case .reversal:
            break

        case .body:
            setupBody(for: fix)

        case .predict:
            predictPhase = .predicting
            predictionText = ""
            observationText = ""

        case .audit:
            auditItems = [:]
        }
    }

    /// Reset for a new fix
    func reset() {
        // Reset timer state
        stopTick()
        cancelNotification()
        liveActivityService.endCurrentActivity()
        session = nil
        remainingSeconds = 0
        progress = 0
        isTimerRequired = false
        timerDuration = 0

        // Reset multi-step state
        currentStepIndex = 0
        completedSteps = []
        multiStepConfig = nil

        // Reset quiz state
        selectedOptionId = nil
        quizAnswered = false
        selectedQuizInsight = nil
        quizConfig = nil

        // Reset scenario state
        selectedScenarioOptionId = nil
        scenarioAnswered = false
        scenarioReflection = nil
        scenarioConfig = nil

        // Reset counter state
        counterValue = 0
        counterHistory = []
        counterConfig = nil

        // Reset new type state
        observationReport = ""
        abstainCompleted = false
        abstainTimerMode = false
        abstainDurationSeconds = 0
        abstainRemainingSeconds = 0
        abstainProgress = 0
        abstainTimerRunning = false
        stopAbstainTick()
        abstainSlips = []
        abstainConfig = nil
        selectedBodyRegions = []
        selectedBodySensations = []
        bodyConfig = nil
        substituteCount = 0
        urgeCount = 0
        journalText = ""
        predictPhase = .predicting
        predictionText = ""
        observationText = ""
        auditItems = [:]

        // Reset general state
        currentFix = nil
        currentFixCompletionId = nil
        interactionType = .standard
        currentFixNumber = ""
        currentFixPrompt = ""
        notificationIdentifier = nil
    }

    // MARK: - Private Setup Methods

    private func setupStandard() {
        // Standard fixes have no special state to set up
    }

    private func setupTimed(for fix: Fix, fixCompletionId: UUID) async {
        // First check if there's an explicit timed config
        if let config = fix.timedConfig {
            isTimerRequired = true
            timerDuration = config.durationSeconds
        }
        // Fall back to parsing from prompt (legacy support)
        else if let duration = timerService.parseTimerDuration(from: fix.prompt) {
            isTimerRequired = true
            timerDuration = duration
        } else {
            isTimerRequired = false
            timerDuration = 0
            return
        }

        do {
            let session = try await timerService.getOrCreateSession(
                for: fixCompletionId,
                durationSeconds: timerDuration
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
            #if DEBUG
            print("Failed to setup timer session: \(error)")
            #endif
        }
    }

    private func setupMultiStep(for fix: Fix) {
        guard let config = fix.multiStepConfig else {
            #if DEBUG
            print("Multi-step fix missing configuration")
            #endif
            return
        }

        multiStepConfig = config
        currentStepIndex = 0
        completedSteps = []
    }

    private func setupQuiz(for fix: Fix) {
        guard let config = fix.quizConfig else {
            #if DEBUG
            print("Quiz fix missing configuration")
            #endif
            return
        }

        quizConfig = config
        selectedOptionId = nil
        quizAnswered = false
        selectedQuizInsight = nil
    }

    private func setupScenario(for fix: Fix) {
        guard let config = fix.scenarioConfig else {
            #if DEBUG
            print("Scenario fix missing configuration")
            #endif
            return
        }

        scenarioConfig = config
        selectedScenarioOptionId = nil
        scenarioAnswered = false
        scenarioReflection = nil
    }

    private func setupCounter(for fix: Fix) {
        guard let config = fix.counterConfig else {
            #if DEBUG
            print("Counter fix missing configuration")
            #endif
            return
        }

        counterConfig = config
        counterValue = 0
        counterHistory = []
    }

    // MARK: - Body Methods

    func toggleBodyRegion(_ region: String) {
        if selectedBodyRegions.contains(region) {
            selectedBodyRegions.remove(region)
        } else {
            selectedBodyRegions.insert(region)
        }
    }

    func toggleBodySensation(_ sensation: String) {
        if selectedBodySensations.contains(sensation) {
            selectedBodySensations.remove(sensation)
        } else {
            selectedBodySensations.insert(sensation)
        }
    }

    // MARK: - Abstain Timer Methods

    func startAbstainTimer() {
        guard abstainTimerMode, !abstainTimerRunning, !abstainCompleted else { return }
        abstainTimerRunning = true
        startAbstainTick()
    }

    func logAbstainSlip(note: String? = nil) {
        let slip = AbstainOutcome.SlipEvent(timestamp: Date(), note: note)
        abstainSlips.append(slip)
    }

    // MARK: - Private Setup Methods (Body + Abstain)

    private func setupBody(for fix: Fix) {
        bodyConfig = fix.bodyConfig
        selectedBodyRegions = []
        selectedBodySensations = []
    }

    private func setupAbstain(for fix: Fix) {
        let config = fix.abstainConfig
        abstainConfig = config
        abstainCompleted = false
        abstainSlips = []
        abstainTimerRunning = false
        abstainProgress = 0

        if let duration = config?.durationSeconds, duration > 0 {
            abstainTimerMode = true
            abstainDurationSeconds = duration
            abstainRemainingSeconds = duration
        } else {
            abstainTimerMode = false
            abstainDurationSeconds = 0
            abstainRemainingSeconds = 0
        }
    }

    // MARK: - Private Abstain Timer Helpers

    private func startAbstainTick() {
        stopAbstainTick()
        abstainTickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.abstainTick()
            }
        }
    }

    private func stopAbstainTick() {
        abstainTickTimer?.invalidate()
        abstainTickTimer = nil
    }

    private func abstainTick() {
        guard abstainTimerRunning, abstainRemainingSeconds > 0 else {
            if abstainRemainingSeconds <= 0 && abstainTimerMode && abstainTimerRunning {
                completeAbstainTimer()
            }
            return
        }
        abstainRemainingSeconds -= 1
        if abstainDurationSeconds > 0 {
            abstainProgress = 1.0 - (Double(abstainRemainingSeconds) / Double(abstainDurationSeconds))
        }
        if abstainRemainingSeconds <= 0 {
            completeAbstainTimer()
        }
    }

    private func completeAbstainTimer() {
        stopAbstainTick()
        abstainTimerRunning = false
        abstainCompleted = true
        abstainProgress = 1.0
        onInteractionComplete?()
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
            #if DEBUG
            print("Failed to start timer: \(error)")
            #endif
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
            #if DEBUG
            print("Failed to pause timer: \(error)")
            #endif
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
            #if DEBUG
            print("Failed to reset timer: \(error)")
            #endif
        }
    }

    // MARK: - Multi-Step Methods

    /// Complete the current step and advance to next
    func completeCurrentStep() {
        guard let config = multiStepConfig,
              currentStepIndex < config.steps.count else { return }

        let step = config.steps[currentStepIndex]
        let completion = MultiStepOutcome.StepCompletion(
            stepId: step.id,
            completedAt: Date(),
            skipped: false
        )
        completedSteps.append(completion)
        advanceToNextStep()
    }

    /// Skip the current step and advance to next
    func skipCurrentStep() {
        guard let config = multiStepConfig,
              currentStepIndex < config.steps.count else { return }

        let step = config.steps[currentStepIndex]
        let completion = MultiStepOutcome.StepCompletion(
            stepId: step.id,
            completedAt: Date(),
            skipped: true
        )
        completedSteps.append(completion)
        advanceToNextStep()
    }

    /// Advance to the next step (internal)
    private func advanceToNextStep() {
        guard let config = multiStepConfig else { return }

        if currentStepIndex < config.steps.count - 1 {
            currentStepIndex += 1
        } else {
            // All steps processed
            onInteractionComplete?()
        }
    }

    // MARK: - Quiz Methods

    /// Select a quiz option
    func selectQuizOption(_ option: QuizConfig.QuizOption) {
        guard !quizAnswered else { return }

        selectedOptionId = option.id
        selectedQuizInsight = option.insight
        quizAnswered = true
        onInteractionComplete?()
    }

    // MARK: - Scenario Methods

    /// Select a scenario option
    func selectScenarioOption(_ option: ScenarioConfig.ScenarioOption) {
        guard !scenarioAnswered else { return }

        selectedScenarioOptionId = option.id
        scenarioReflection = option.reflection
        scenarioAnswered = true
        onInteractionComplete?()
    }

    // MARK: - Counter Methods

    /// Increment the counter
    func incrementCounter() {
        counterValue += 1
        let event = CounterOutcome.CountEvent(timestamp: Date(), delta: 1)
        counterHistory.append(event)
    }

    /// Decrement the counter (for corrections)
    func decrementCounter() {
        guard counterValue > 0 else { return }
        counterValue -= 1
        let event = CounterOutcome.CountEvent(timestamp: Date(), delta: -1)
        counterHistory.append(event)
    }

    // MARK: - Completion Data Generation

    /// Generate outcome data as encoded Data for storage
    func generateOutcomeData() -> Data? {
        switch interactionType {
        case .standard, .reversal, .journal:
            return nil

        case .body:
            let outcome = BodyOutcome(
                selectedRegions: Array(selectedBodyRegions),
                selectedSensations: Array(selectedBodySensations)
            )
            return try? JSONEncoder().encode(outcome)

        case .timed:
            let outcome = generateTimedOutcome()
            return try? JSONEncoder().encode(outcome)

        case .multiStep:
            let outcome = generateMultiStepOutcome()
            return try? JSONEncoder().encode(outcome)

        case .quiz:
            guard let outcome = generateQuizOutcome() else { return nil }
            return try? JSONEncoder().encode(outcome)

        case .scenario:
            guard let outcome = generateScenarioOutcome() else { return nil }
            return try? JSONEncoder().encode(outcome)

        case .counter:
            let outcome = generateCounterOutcome()
            return try? JSONEncoder().encode(outcome)

        case .observation:
            let outcome = ObservationOutcome(report: observationReport)
            return try? JSONEncoder().encode(outcome)

        case .abstain:
            let outcome = AbstainOutcome(
                completed: abstainCompleted,
                slipCount: abstainSlips.count,
                slips: abstainSlips,
                timerUsed: abstainTimerMode,
                durationSeconds: abstainTimerMode ? abstainDurationSeconds : nil
            )
            return try? JSONEncoder().encode(outcome)

        case .substitute:
            let outcome = SubstituteOutcome(substituteCount: substituteCount, urgeCount: urgeCount)
            return try? JSONEncoder().encode(outcome)

        case .predict:
            let outcome = PredictOutcome(prediction: predictionText, actualResult: observationText)
            return try? JSONEncoder().encode(outcome)

        case .audit:
            let items = auditItems.map { AuditOutcome.AuditItem(categoryId: $0.key, note: $0.value) }
            let outcome = AuditOutcome(items: items)
            return try? JSONEncoder().encode(outcome)
        }
    }

    private func generateTimedOutcome() -> TimedOutcome {
        let actualDuration: Int?
        if let session = session, session.status == .completed {
            actualDuration = session.durationSeconds
        } else {
            actualDuration = nil
        }

        return TimedOutcome(
            timerCompleted: isTimerCompleted,
            actualDurationSeconds: actualDuration
        )
    }

    private func generateMultiStepOutcome() -> MultiStepOutcome {
        return MultiStepOutcome(stepsCompleted: completedSteps)
    }

    private func generateQuizOutcome() -> QuizOutcome? {
        guard let optionId = selectedOptionId,
              let option = selectedQuizOption else { return nil }

        return QuizOutcome(
            selectedOptionId: optionId,
            weightModifierApplied: option.weightModifier
        )
    }

    private func generateScenarioOutcome() -> ScenarioOutcome? {
        guard let optionId = selectedScenarioOptionId,
              let option = selectedScenarioOption else { return nil }

        return ScenarioOutcome(
            selectedOptionId: optionId,
            weightModifierApplied: option.weightModifier
        )
    }

    private func generateCounterOutcome() -> CounterOutcome {
        return CounterOutcome(
            finalCount: counterValue,
            countHistory: counterHistory
        )
    }

    // MARK: - Private Timer Helpers

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
            cancelNotification()
            liveActivityService.endCurrentActivityWithDelay(seconds: 5)

            onTimerComplete?()
            onInteractionComplete?()
        } catch {
            #if DEBUG
            print("Failed to complete timer: \(error)")
            #endif
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
            #if DEBUG
            print("Failed to schedule notification: \(error)")
            #endif
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
        abstainTickTimer?.invalidate()
    }
}
