import Foundation
import SwiftUI
import Combine

struct DiagnosticBugState: Identifiable {
    let id: UUID
    let bug: Bug
    var intensity: BugIntensity?
    var context: EventContext?
}

@MainActor
final class WeeklyDiagnosticViewModel: ObservableObject {
    @Published var shouldShowPrompt = false
    @Published var bugs: [DiagnosticBugState] = []
    @Published var currentBugIndex = 0
    @Published var isComplete = false
    @Published var isLoading = false

    private let weeklyDiagnosticService: WeeklyDiagnosticService

    init(weeklyDiagnosticService: WeeklyDiagnosticService) {
        self.weeklyDiagnosticService = weeklyDiagnosticService
    }

    var currentBug: DiagnosticBugState? {
        guard currentBugIndex < bugs.count else { return nil }
        return bugs[currentBugIndex]
    }

    var needsContextQuestion: Bool {
        guard let current = currentBug else { return false }
        return current.intensity != nil && current.intensity != .quiet && current.context == nil
    }

    func checkShouldPrompt() async {
        do {
            shouldShowPrompt = try await weeklyDiagnosticService.shouldPromptDiagnostic()

            if shouldShowPrompt {
                let diagnosticBugs = try await weeklyDiagnosticService.getBugsForDiagnostic()
                bugs = diagnosticBugs.map { bug in
                    DiagnosticBugState(id: bug.id, bug: bug)
                }
            }
        } catch {
            shouldShowPrompt = false
        }
    }

    func setIntensity(_ intensity: BugIntensity) {
        guard currentBugIndex < bugs.count else { return }
        bugs[currentBugIndex].intensity = intensity

        // If quiet, skip context and move to next
        if intensity == .quiet {
            moveToNextBug()
        }
    }

    func setContext(_ context: EventContext) {
        guard currentBugIndex < bugs.count else { return }
        bugs[currentBugIndex].context = context
        moveToNextBug()
    }

    func skipContext() {
        guard currentBugIndex < bugs.count else { return }
        bugs[currentBugIndex].context = .unknown
        moveToNextBug()
    }

    private func moveToNextBug() {
        if currentBugIndex < bugs.count - 1 {
            currentBugIndex += 1
        } else {
            Task {
                await submit()
            }
        }
    }

    func submit() async {
        isLoading = true

        let responses = bugs.compactMap { state -> BugDiagnosticResponse? in
            guard let intensity = state.intensity else { return nil }
            return BugDiagnosticResponse(
                bugId: state.id,
                intensity: intensity,
                primaryContext: state.context
            )
        }

        do {
            try await weeklyDiagnosticService.submitDiagnostic(responses: responses)
            isComplete = true
            shouldShowPrompt = false
        } catch {
            // Handle error silently
        }

        isLoading = false
    }

    func skip() async {
        do {
            try await weeklyDiagnosticService.skipDiagnostic()
            shouldShowPrompt = false
        } catch {
            // Handle error silently
        }
    }
}
