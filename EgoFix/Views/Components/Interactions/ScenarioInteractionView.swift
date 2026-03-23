import SwiftUI

struct ScenarioInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager

    private var config: ScenarioConfig? {
        interactionManager.scenarioConfig
    }

    private var selectedOption: ScenarioConfig.ScenarioOption? {
        interactionManager.selectedScenarioOption
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            InteractionHeader(type: "SCENARIO", status: interactionManager.scenarioAnswered ? "Completed" : "Choose response")

            // Situation description
            if let situation = config?.situation {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Situation:")
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textMuted)

                    Text(situation)
                        .font(EgoTheme.mono())
                        .foregroundColor(EgoTheme.textPrimary)
                        .lineSpacing(4)
                }
            }

            // Response options
            if let options = config?.options {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How would you respond?")
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textMuted)
                        .padding(.top, 4)

                    ForEach(options) { option in
                        optionRow(option)
                    }
                }
                .padding(.top, 4)
            }

            // Post-selection reflection
            if interactionManager.scenarioAnswered {
                if let reflection = selectedOption?.reflection {
                    Text("// \(reflection)")
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textMuted)
                        .italic()
                        .padding(.top, 4)
                        .transition(.opacity)
                }

                // General debrief
                if let debrief = config?.debrief {
                    Text("// \(debrief)")
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textMuted)
                        .padding(.top, 2)
                        .transition(.opacity)
                }
            }
        }
        .interactionCard(borderColor: borderColor)
    }

    // MARK: - Option Row

    @ViewBuilder
    private func optionRow(_ option: ScenarioConfig.ScenarioOption) -> some View {
        let isSelected = interactionManager.selectedScenarioOptionId == option.id
        let isDisabled = interactionManager.scenarioAnswered && !isSelected

        Button(action: {
            guard !interactionManager.scenarioAnswered else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                interactionManager.selectScenarioOption(option)
            }
        }) {
            HStack(alignment: .top, spacing: 8) {
                // Selection indicator
                Text(isSelected ? ">" : " ")
                    .font(EgoTheme.mono())
                    .foregroundColor(isSelected ? .green : EgoTheme.textMuted)
                    .frame(width: 12)

                // Option text
                Text(option.text)
                    .font(EgoTheme.mono())
                    .foregroundColor(optionTextColor(isSelected: isSelected, isDisabled: isDisabled))
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.green.opacity(0.05) : Color.clear)
            .cornerRadius(2)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(interactionManager.scenarioAnswered)
    }

    // MARK: - Helpers

    private func optionTextColor(isSelected: Bool, isDisabled: Bool) -> Color {
        if isDisabled {
            return EgoTheme.textMuted
        } else if isSelected {
            return .white
        }
        return EgoTheme.textPrimary
    }

    private var borderColor: Color {
        if interactionManager.scenarioAnswered {
            return .green.opacity(0.5)
        } else if interactionManager.selectedScenarioOptionId != nil {
            return .green.opacity(0.3)
        }
        return EgoTheme.surface
    }
}

