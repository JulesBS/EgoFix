import Foundation
import SwiftUI
import Combine

enum OnboardingStep {
    case welcome
    case rankBugs
    case confirmation
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var availableBugs: [Bug] = []
    @Published var rankedBugs: [Bug] = []  // User's ranked order (first = highest priority)
    @Published var isLoading = false
    @Published var isComplete = false
    @Published var showingAllBugs = false

    private let bugRepository: BugRepository
    private let userRepository: UserRepository

    init(
        bugRepository: BugRepository,
        userRepository: UserRepository
    ) {
        self.bugRepository = bugRepository
        self.userRepository = userRepository
    }

    func checkOnboardingNeeded() async -> Bool {
        do {
            let user = try await userRepository.get()
            return user == nil || (user?.bugPriorities.isEmpty ?? true && user?.primaryBugId == nil)
        } catch {
            return true
        }
    }

    /// Maximum bugs to show initially (show more reveals the rest)
    private let initialBugsToShow = 5

    /// All bugs loaded from the repository
    private var allLoadedBugs: [Bug] = []

    func loadBugs() async {
        isLoading = true

        do {
            allLoadedBugs = try await bugRepository.getAll()
            availableBugs = Array(allLoadedBugs.prefix(initialBugsToShow))
            rankedBugs = availableBugs
            showingAllBugs = allLoadedBugs.count <= initialBugsToShow
        } catch {
            allLoadedBugs = []
            availableBugs = []
            rankedBugs = []
        }

        isLoading = false
    }

    var hasMoreBugs: Bool {
        !showingAllBugs && allLoadedBugs.count > initialBugsToShow
    }

    func showMore() {
        guard hasMoreBugs else { return }
        let additionalBugs = Array(allLoadedBugs.suffix(from: initialBugsToShow))
        availableBugs.append(contentsOf: additionalBugs)
        rankedBugs = availableBugs
        showingAllBugs = true
    }

    func moveBug(from source: IndexSet, to destination: Int) {
        rankedBugs.move(fromOffsets: source, toOffset: destination)
    }

    func goToRankBugs() {
        currentStep = .rankBugs
    }

    func confirmRanking() {
        currentStep = .confirmation
    }

    func confirmSelection() async {
        guard !rankedBugs.isEmpty else { return }

        isLoading = true

        do {
            // Activate all ranked bugs
            for bug in rankedBugs {
                bug.isActive = true
                bug.status = .active
                bug.activatedAt = Date()
                bug.updatedAt = Date()
                try await bugRepository.save(bug)
            }

            // Create bug priorities from ranked order
            let priorities = rankedBugs.enumerated().map { index, bug in
                BugPriority(bugId: bug.id, rank: index + 1)
            }

            // Create or update user profile with priorities
            let user = UserProfile(bugPriorities: priorities)
            try await userRepository.save(user)

            isComplete = true
        } catch {
            // Handle error silently
        }

        isLoading = false
    }

    func goBack() {
        switch currentStep {
        case .welcome:
            break
        case .rankBugs:
            currentStep = .welcome
        case .confirmation:
            currentStep = .rankBugs
        }
    }

    /// Top 3 priorities for confirmation display
    var topPriorities: [Bug] {
        Array(rankedBugs.prefix(3))
    }
}
