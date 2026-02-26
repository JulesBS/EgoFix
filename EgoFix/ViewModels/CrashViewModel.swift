import Foundation
import SwiftUI
import Combine

enum CrashFlowState {
    case initial
    case selectBug
    case crashed(Crash)
    case quickFix(FixCompletion, Fix)
}

@MainActor
final class CrashViewModel: ObservableObject {
    @Published var state: CrashFlowState = .initial
    @Published var availableBugs: [Bug] = []
    @Published var selectedBug: Bug?
    @Published var note: String = ""
    @Published var isLoading = false

    private let crashService: CrashService
    private let bugRepository: BugRepository
    private let fixRepository: FixRepository

    init(
        crashService: CrashService,
        bugRepository: BugRepository,
        fixRepository: FixRepository
    ) {
        self.crashService = crashService
        self.bugRepository = bugRepository
        self.fixRepository = fixRepository
    }

    func loadBugs() async {
        isLoading = true

        do {
            availableBugs = try await bugRepository.getActive()
        } catch {
            availableBugs = []
        }

        isLoading = false
    }

    func startCrashLog() {
        state = .selectBug
    }

    func selectBug(_ bug: Bug) {
        selectedBug = bug
    }

    func confirmCrash() async {
        isLoading = true

        do {
            let crash = try await crashService.logCrash(
                bugId: selectedBug?.id,
                note: note.isEmpty ? nil : note
            )

            if let crash = crash {
                state = .crashed(crash)

                // Try to assign a quick fix
                if let completion = try await crashService.assignQuickFix(for: crash.id),
                   let fix = try await fixRepository.getById(completion.fixId) {
                    state = .quickFix(completion, fix)
                }
            }
        } catch {
            // Handle error silently
        }

        isLoading = false
    }

    func reboot() async {
        guard case .crashed(let crash) = state else { return }

        do {
            try await crashService.reboot(crashId: crash.id)
            reset()
        } catch {
            // Handle error silently
        }
    }

    func reset() {
        state = .initial
        selectedBug = nil
        note = ""
    }
}
