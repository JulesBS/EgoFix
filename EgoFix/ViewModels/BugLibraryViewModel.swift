import Foundation
import Combine

@MainActor
final class BugLibraryViewModel: ObservableObject {
    @Published var bugs: [BugLifecycleInfo] = []
    @Published var isLoading = false
    @Published var selectedBugId: UUID?

    private let bugRepository: BugRepository
    private let userRepository: UserRepository
    private let bugLifecycleService: BugLifecycleService

    init(
        bugRepository: BugRepository,
        userRepository: UserRepository,
        bugLifecycleService: BugLifecycleService
    ) {
        self.bugRepository = bugRepository
        self.userRepository = userRepository
        self.bugLifecycleService = bugLifecycleService
    }

    func loadBugs() async {
        isLoading = true

        do {
            let allBugs = try await bugRepository.getAll()
            bugs = allBugs.map { bugLifecycleService.getLifecycleInfo(for: $0) }
                .sorted { lhs, rhs in
                    // Sort by status: active > stable > resolved > identified
                    statusOrder(lhs.status) < statusOrder(rhs.status)
                }
        } catch {
            // Handle silently
        }

        isLoading = false
    }

    func activateBug(_ bugId: UUID) async {
        do {
            try await bugLifecycleService.activate(bugId)
            await loadBugs()
        } catch {
            // Handle silently
        }
    }

    func deactivateBug(_ bugId: UUID) async {
        do {
            try await bugLifecycleService.deactivate(bugId)
            await loadBugs()
        } catch {
            // Handle silently
        }
    }

    func resolveBug(_ bugId: UUID) async {
        do {
            try await bugLifecycleService.resolve(bugId)
            await loadBugs()
        } catch {
            // Handle silently
        }
    }

    func reactivateBug(_ bugId: UUID) async {
        do {
            try await bugLifecycleService.reactivate(bugId)
            await loadBugs()
        } catch {
            // Handle silently
        }
    }

    private func statusOrder(_ status: BugStatus) -> Int {
        switch status {
        case .active: return 0
        case .stable: return 1
        case .resolved: return 2
        case .identified: return 3
        }
    }

    var activeBugCount: Int {
        bugs.filter { $0.status == .active }.count
    }

    var stableBugCount: Int {
        bugs.filter { $0.status == .stable }.count
    }

    var resolvedBugCount: Int {
        bugs.filter { $0.status == .resolved }.count
    }
}
