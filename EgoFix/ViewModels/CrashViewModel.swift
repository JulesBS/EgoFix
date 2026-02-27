import Foundation
import SwiftUI
import Combine

enum CrashFlowState {
    case selectBug
    case crashed(Crash, Bug?)
    case quickFix(FixCompletion, Fix)
}

@MainActor
final class CrashViewModel: ObservableObject {
    @Published var state: CrashFlowState = .selectBug
    @Published var availableBugs: [Bug] = []
    @Published var note: String = ""
    @Published var isLoading = false

    private let crashService: CrashService
    private let bugRepository: BugRepository
    private let fixRepository: FixRepository

    /// Pool of crash confirmation messages, rotated randomly.
    static let crashMessages: [String] = [
        "// It happens. That's the whole point of logging.",
        "// Crash logged. You caught it. That's progress.",
        "// The bug won this round. You'll get another.",
        "// Noted. No judgment. Just data.",
    ]

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

    /// Tapping a bug immediately logs the crash.
    func selectAndLogCrash(_ bug: Bug) async {
        isLoading = true

        do {
            let crash = try await crashService.logCrash(
                bugId: bug.id,
                note: note.isEmpty ? nil : note
            )

            if let crash = crash {
                // Try to assign a quick fix
                if let completion = try await crashService.assignQuickFix(for: crash.id),
                   let fix = try await fixRepository.getById(completion.fixId) {
                    state = .quickFix(completion, fix)
                } else {
                    state = .crashed(crash, bug)
                }
            }
        } catch {
            // Handle error silently
        }

        isLoading = false
    }

    func reboot() async {
        guard case .crashed(let crash, _) = state else { return }

        do {
            try await crashService.reboot(crashId: crash.id)
            reset()
        } catch {
            // Handle error silently
        }
    }

    func reset() {
        state = .selectBug
        note = ""
    }

    /// Returns a random crash confirmation message.
    static func randomCrashMessage() -> String {
        crashMessages.randomElement() ?? "// It happens."
    }
}
