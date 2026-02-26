import SwiftUI

struct FixInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager

    var body: some View {
        Group {
            switch fix.interactionType {
            case .standard:
                StandardInteractionView(
                    fix: fix,
                    interactionManager: interactionManager
                )

            case .timed:
                TimedInteractionView(
                    fix: fix,
                    interactionManager: interactionManager
                )

            case .multiStep:
                MultiStepInteractionView(
                    fix: fix,
                    interactionManager: interactionManager
                )

            case .quiz:
                QuizInteractionView(
                    fix: fix,
                    interactionManager: interactionManager
                )

            case .scenario:
                ScenarioInteractionView(
                    fix: fix,
                    interactionManager: interactionManager
                )

            case .counter:
                CounterInteractionView(
                    fix: fix,
                    interactionManager: interactionManager
                )

            case .observation:
                ObservationInteractionView(
                    fix: fix,
                    interactionManager: interactionManager
                )

            case .abstain:
                AbstainInteractionView(
                    fix: fix,
                    interactionManager: interactionManager
                )

            case .substitute:
                SubstituteInteractionView(
                    fix: fix,
                    interactionManager: interactionManager
                )

            case .journal:
                JournalInteractionView(
                    fix: fix,
                    interactionManager: interactionManager
                )

            case .reversal:
                ReversalInteractionView(
                    fix: fix,
                    interactionManager: interactionManager
                )

            case .predict:
                PredictInteractionView(
                    fix: fix,
                    interactionManager: interactionManager
                )

            case .body:
                BodyInteractionView(
                    fix: fix,
                    interactionManager: interactionManager
                )

            case .audit:
                AuditInteractionView(
                    fix: fix,
                    interactionManager: interactionManager
                )
            }
        }
    }
}

