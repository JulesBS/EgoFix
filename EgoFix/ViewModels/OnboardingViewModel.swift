import Foundation
import SwiftUI
import Combine

// MARK: - Phase

enum OnboardingPhase: Equatable {
    case awakening
    case scenario(index: Int)   // 0, 1, 2
    case reframe(index: Int)    // 0, 1, 2
    case reveal
    case committing
}

// MARK: - ViewModel

@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: Published State

    @Published var phase: OnboardingPhase = .awakening
    @Published var selectedBugId: UUID?
    @Published var isComplete = false
    @Published var isLoading = false
    @Published var commitError: String?

    /// Maps scenario index → selected option ID
    @Published var scenarioSelections: [Int: String] = [:]

    /// Running totals: bugSlug → accumulated weight
    @Published var accumulatedWeights: [String: Double] = [:]

    /// All 7 bugs sorted by accumulated weight (descending), set after final scenario
    @Published private(set) var rankedBugs: [Bug] = []

    /// Whether "Show all 7" is expanded in the reveal phase
    @Published var showAllBugs = false

    // MARK: Data

    /// All 7 bugs in canonical order (loaded from repository)
    private(set) var allBugs: [Bug] = []

    /// Loaded scenario definitions
    private(set) var scenarios: [OnboardingScenario] = []

    // MARK: Dependencies

    private let bugRepository: BugRepository
    private let userRepository: UserRepository
    private let fixRepository: FixRepository
    private let fixCompletionRepository: FixCompletionRepository
    private let analyticsEventRepository: AnalyticsEventRepository

    // MARK: Static Content

    /// Inline comments for each bug during onboarding
    static let inlineComments: [String: String] = [
        "need-to-be-right": "// You're not helping them. You're helping yourself feel certain.",
        "need-to-impress": "// The applause isn't for you. It's for the version of you that showed up.",
        "need-to-be-liked": "// You've been so many people, you're not sure which one is real.",
        "need-to-control": "// If you let go, nothing bad happens. That's the part you don't believe.",
        "need-to-compare": "// You're not measuring them. You're measuring yourself against them.",
        "need-to-deflect": "// The joke lands, the moment passes, and the feeling stays.",
        "need-to-narrate": "// You've told this story so many times it feels like it happened to someone else.",
    ]

    /// Daily-life examples for each bug (shown in reveal phase cards)
    static let dailyLifeExamples: [String: [String]] = [
        "need-to-be-right": [
            "Fact-checking someone mid-conversation",
            "Replaying arguments you already won",
            "Correcting minor errors that don't matter",
        ],
        "need-to-impress": [
            "Name-dropping people, companies, or places",
            "Steering conversations to your expertise",
            "Checking how many likes your post got",
        ],
        "need-to-be-liked": [
            "Saying \"yes\" when you mean \"no\"",
            "Changing your opinion to match the room",
            "Over-apologizing for things that aren't your fault",
        ],
        "need-to-control": [
            "Redoing someone's work because it wasn't done \"right\"",
            "Anxiety when plans change last-minute",
            "Difficulty delegating without hovering",
        ],
        "need-to-compare": [
            "Checking what peers earn, own, or achieved",
            "Feeling a pang when a friend succeeds",
            "Mentally ranking yourself in every room",
        ],
        "need-to-deflect": [
            "Making a joke when things get serious",
            "Answering \"how are you?\" with performance",
            "Never asking for help, even when drowning",
        ],
        "need-to-narrate": [
            "Rehearsing arguments in your head",
            "Telling the same complaint to multiple people",
            "Narrating your day as if documenting injustices",
        ],
    ]

    /// Canonical bug display order
    static let slugOrder = [
        "need-to-be-right",
        "need-to-be-liked",
        "need-to-control",
        "need-to-compare",
        "need-to-impress",
        "need-to-deflect",
        "need-to-narrate",
    ]

    // MARK: Init

    init(
        bugRepository: BugRepository,
        userRepository: UserRepository,
        fixRepository: FixRepository,
        fixCompletionRepository: FixCompletionRepository,
        analyticsEventRepository: AnalyticsEventRepository
    ) {
        self.bugRepository = bugRepository
        self.userRepository = userRepository
        self.fixRepository = fixRepository
        self.fixCompletionRepository = fixCompletionRepository
        self.analyticsEventRepository = analyticsEventRepository
    }

    // MARK: - Loading

    func loadBugs() async {
        isLoading = true
        do {
            let loaded = try await bugRepository.getAll()
            allBugs = loaded.sorted { a, b in
                let indexA = Self.slugOrder.firstIndex(of: a.slug) ?? Int.max
                let indexB = Self.slugOrder.firstIndex(of: b.slug) ?? Int.max
                return indexA < indexB
            }
        } catch {
            allBugs = []
        }
        scenarios = OnboardingScenarioLoader.loadScenarios()
        isLoading = false
    }

    // MARK: - Computed Properties

    /// Current scenario for the active phase, or nil
    var currentScenario: OnboardingScenario? {
        guard case .scenario(let index) = phase, index < scenarios.count else { return nil }
        return scenarios[index]
    }

    /// Current reframe text for the active reframe phase, or nil
    var currentReframe: String? {
        guard case .reframe(let index) = phase, index < scenarios.count else { return nil }
        return scenarios[index].reframe
    }

    /// Top 3 bugs from the ranked list (shown in reveal phase)
    var topBugs: [Bug] {
        Array(rankedBugs.prefix(3))
    }

    /// Remaining bugs not in the top 3 (shown when "Show all 7" is expanded)
    var remainingBugs: [Bug] {
        Array(rankedBugs.dropFirst(3))
    }

    // MARK: - Accessors

    func nickname(for slug: String) -> String {
        slug
    }

    func inlineComment(for slug: String) -> String {
        Self.inlineComments[slug] ?? ""
    }

    func examples(for slug: String) -> [String] {
        Self.dailyLifeExamples[slug] ?? []
    }

    /// Returns the accumulated weight for a bug slug, normalized to 0.0-1.0
    /// based on the maximum weight across all bugs.
    func normalizedScore(for slug: String) -> Double {
        let raw = accumulatedWeights[slug] ?? 0
        let maxWeight = accumulatedWeights.values.max() ?? 1
        guard maxWeight > 0 else { return 0 }
        return raw / maxWeight
    }

    // MARK: - Phase Transitions

    /// Fallback: skip directly to reveal phase (e.g., when scenario data is missing)
    func skipToReveal() {
        calculateRankedBugs()
        if rankedBugs.isEmpty { rankedBugs = allBugs }
        phase = .reveal
    }

    /// Called when the awakening phase is complete (user taps "Begin scan")
    func beginScenarios() {
        guard !scenarios.isEmpty else {
            // Fallback: skip to reveal with canonical order if no scenarios loaded
            rankedBugs = allBugs
            phase = .reveal
            return
        }
        phase = .scenario(index: 0)
    }

    /// Called when the user selects a scenario option
    func selectScenarioOption(_ optionId: String, forScenario scenarioIndex: Int) {
        scenarioSelections[scenarioIndex] = optionId
        accumulatedWeights = ScenarioWeightCalculator.accumulateWeights(
            from: scenarioSelections,
            scenarios: scenarios
        )
        phase = .reframe(index: scenarioIndex)
    }

    /// Called when the reframe phase is complete (auto-advance or tap)
    func advanceFromReframe(_ scenarioIndex: Int) {
        let nextIndex = scenarioIndex + 1
        if nextIndex < scenarios.count {
            phase = .scenario(index: nextIndex)
        } else {
            calculateRankedBugs()
            phase = .reveal
        }
    }

    /// Calculates ranked bugs from accumulated weights
    func calculateRankedBugs() {
        let rankedSlugs = ScenarioWeightCalculator.rankBugSlugs(by: accumulatedWeights)
        rankedBugs = rankedSlugs.compactMap { slug in
            allBugs.first(where: { $0.slug == slug })
        }
    }

    /// Returns the cube indices that should flicker when a scenario option is selected.
    /// Maps the option's weighted bug slugs to their canonical indices.
    func cubeIndicesForOption(_ option: ScenarioOption) -> [Int] {
        option.weights.compactMap { slug, _ in
            ScenarioWeightCalculator.allBugSlugs.firstIndex(of: slug)
        }
    }

    // MARK: - Commit

    func commitAndAssignFirstFix() async {
        guard let selectedId = selectedBugId,
              let selectedBug = allBugs.first(where: { $0.id == selectedId }) else { return }

        isLoading = true
        commitError = nil

        do {
            // Activate selected bug
            selectedBug.isActive = true
            selectedBug.status = .active
            selectedBug.activatedAt = Date()
            selectedBug.updatedAt = Date()
            try await bugRepository.save(selectedBug)

            // Build priority list using scenario weights for ranking
            var priorities: [BugPriority] = []
            var rank = 1

            // Selected bug is always rank 1
            priorities.append(BugPriority(bugId: selectedId, rank: rank))
            rank += 1

            // Remaining bugs ordered by accumulated weight (descending)
            let otherBugs = rankedBugs.filter { $0.id != selectedId }
            for bug in otherBugs {
                bug.isActive = false
                bug.status = .identified
                bug.updatedAt = Date()
                try await bugRepository.save(bug)
                priorities.append(BugPriority(bugId: bug.id, rank: rank))
                rank += 1
            }

            // Reuse existing profile if present (e.g., replay onboarding) to avoid duplicates
            let user = (try? await userRepository.get()) ?? UserProfile(bugPriorities: priorities)
            user.bugPriorities = priorities
            try await userRepository.save(user)

            // Assign first fix immediately
            let dailyFixService = DailyFixService(
                fixRepository: fixRepository,
                fixCompletionRepository: fixCompletionRepository,
                userRepository: userRepository,
                analyticsEventRepository: analyticsEventRepository
            )
            _ = try await dailyFixService.assignDailyFix()

            isComplete = true
        } catch {
            NSLog("[OnboardingViewModel] Commit failed: %@", "\(error)")
            commitError = "Failed to assign fix. Tap to retry."
        }

        isLoading = false
    }

    // MARK: - Legacy Compatibility

    /// Check if onboarding is needed (no user profile exists)
    func checkOnboardingNeeded() async -> Bool {
        do {
            let user = try await userRepository.get()
            return user == nil || user!.bugPriorities.isEmpty
        } catch {
            return true
        }
    }
}
