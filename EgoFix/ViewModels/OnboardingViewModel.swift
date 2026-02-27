import Foundation
import SwiftUI
import Combine

enum OnboardingState: Equatable {
    case boot
    case scanning(bugIndex: Int)
    case moreDetected
    case confirmation
    case committing

    static func == (lhs: OnboardingState, rhs: OnboardingState) -> Bool {
        switch (lhs, rhs) {
        case (.boot, .boot): return true
        case (.scanning(let a), .scanning(let b)): return a == b
        case (.moreDetected, .moreDetected): return true
        case (.confirmation, .confirmation): return true
        case (.committing, .committing): return true
        default: return false
        }
    }
}

enum BugResponse: Int, CaseIterable {
    case yesOften = 3
    case sometimes = 2
    case rarely = 1

    var label: String {
        switch self {
        case .yesOften: return "Yes, often"
        case .sometimes: return "Sometimes"
        case .rarely: return "Rarely"
        }
    }
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var state: OnboardingState = .boot
    @Published var responses: [UUID: BugResponse] = [:]
    @Published var isComplete = false
    @Published var isLoading = false

    private let bugRepository: BugRepository
    private let userRepository: UserRepository

    /// All 7 bugs in display order
    private(set) var allBugs: [Bug] = []

    /// Slug-to-nickname mapping (delegates to Bug.slugNicknames)
    static var nicknames: [String: String] { Bug.slugNicknames }

    /// Inline comments for each bug during scan
    static let inlineComments: [String: String] = [
        "need-to-be-right": "// You're not helping them. You're helping yourself feel certain.",
        "need-to-impress": "// The applause isn't for you. It's for the version of you that showed up.",
        "need-to-be-liked": "// You've been so many people, you're not sure which one is real.",
        "need-to-control": "// If you let go, nothing bad happens. That's the part you don't believe.",
        "need-to-compare": "// You're not measuring them. You're measuring yourself against them.",
        "need-to-deflect": "// The joke lands, the moment passes, and the feeling stays.",
        "need-to-narrate": "// You've told this story so many times it feels like it happened to someone else.",
    ]

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

    /// Canonical bug display order (matches seed data ordering)
    private static let slugOrder = [
        "need-to-be-right",
        "need-to-be-liked",
        "need-to-control",
        "need-to-compare",
        "need-to-impress",
        "need-to-deflect",
        "need-to-narrate",
    ]

    func loadBugs() async {
        isLoading = true
        do {
            let loaded = try await bugRepository.getAll()
            // Sort by canonical order so scan always shows bugs in a consistent sequence
            allBugs = loaded.sorted { a, b in
                let indexA = Self.slugOrder.firstIndex(of: a.slug) ?? Int.max
                let indexB = Self.slugOrder.firstIndex(of: b.slug) ?? Int.max
                return indexA < indexB
            }
        } catch {
            allBugs = []
        }
        isLoading = false
    }

    // MARK: - Navigation

    func beginScan() {
        guard !allBugs.isEmpty else { return }
        state = .scanning(bugIndex: 0)
    }

    func respondToBug(_ bugId: UUID, response: BugResponse) {
        responses[bugId] = response

        guard case .scanning(let index) = state else { return }

        let nextIndex = index + 1

        // After 5th bug (index 4), show "2 more detected" pause
        if nextIndex == 5 && allBugs.count > 5 {
            state = .moreDetected
        } else if nextIndex < allBugs.count {
            state = .scanning(bugIndex: nextIndex)
        } else {
            state = .confirmation
        }
    }

    func continueAfterMoreDetected() {
        state = .scanning(bugIndex: 5)
    }

    // MARK: - Computed properties

    /// Current bug being scanned
    var currentBug: Bug? {
        guard case .scanning(let index) = state, index < allBugs.count else {
            return nil
        }
        return allBugs[index]
    }

    /// Current scan index (0-based)
    var currentScanIndex: Int {
        guard case .scanning(let index) = state else { return 0 }
        return index
    }

    /// Nickname for a bug slug
    func nickname(for slug: String) -> String {
        Self.nicknames[slug] ?? "Unknown"
    }

    /// Inline comment for a bug slug
    func inlineComment(for slug: String) -> String {
        Self.inlineComments[slug] ?? ""
    }

    /// Top bugs sorted by response weight, then by original order for ties.
    /// Top 3 with weight >= 2 become active. If all rated "Rarely", take top 3 by original order.
    var activeBugs: [Bug] {
        let sorted = allBugs.sorted { a, b in
            let weightA = responses[a.id]?.rawValue ?? 1
            let weightB = responses[b.id]?.rawValue ?? 1
            if weightA != weightB {
                return weightA > weightB
            }
            // Preserve original order for ties
            let indexA = allBugs.firstIndex(where: { $0.id == a.id }) ?? 0
            let indexB = allBugs.firstIndex(where: { $0.id == b.id }) ?? 0
            return indexA < indexB
        }
        return Array(sorted.prefix(3))
    }

    /// Deprioritized bugs (not in top 3)
    var deprioritizedBugs: [Bug] {
        let activeIds = Set(activeBugs.map(\.id))
        return allBugs.filter { !activeIds.contains($0.id) }
    }

    /// Whether all bugs were rated "Rarely"
    var allRatedRarely: Bool {
        guard !responses.isEmpty else { return false }
        return responses.values.allSatisfy { $0 == .rarely }
    }

    /// Response label for display in confirmation (e.g. "runs often")
    func responseLabel(for bug: Bug) -> String {
        switch responses[bug.id] {
        case .yesOften: return "// runs often"
        case .sometimes: return "// runs sometimes"
        case .rarely: return "// runs rarely"
        case nil: return ""
        }
    }

    // MARK: - Commit

    func commitConfiguration() async {
        guard !activeBugs.isEmpty else { return }

        state = .committing
        isLoading = true

        do {
            // Activate top bugs
            for (index, bug) in activeBugs.enumerated() {
                bug.isActive = true
                bug.status = .active
                bug.activatedAt = Date()
                bug.updatedAt = Date()
                try await bugRepository.save(bug)

                // Priority is 1-indexed
                _ = index + 1
            }

            // Set remaining as identified (not active)
            for bug in deprioritizedBugs {
                bug.isActive = false
                bug.status = .identified
                bug.updatedAt = Date()
                try await bugRepository.save(bug)
            }

            // Build priorities from all bugs sorted by weight
            let allSorted = allBugs.sorted { a, b in
                let weightA = responses[a.id]?.rawValue ?? 1
                let weightB = responses[b.id]?.rawValue ?? 1
                if weightA != weightB {
                    return weightA > weightB
                }
                let indexA = allBugs.firstIndex(where: { $0.id == a.id }) ?? 0
                let indexB = allBugs.firstIndex(where: { $0.id == b.id }) ?? 0
                return indexA < indexB
            }

            let priorities = allSorted.enumerated().map { index, bug in
                BugPriority(bugId: bug.id, rank: index + 1)
            }

            let user = UserProfile(bugPriorities: priorities)
            try await userRepository.save(user)

            isComplete = true
        } catch {
            // Revert to confirmation on error
            state = .confirmation
        }

        isLoading = false
    }
}
