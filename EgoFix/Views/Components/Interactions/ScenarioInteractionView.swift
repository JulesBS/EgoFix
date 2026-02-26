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
            HStack {
                Text("SCENARIO")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.green)

                Spacer()

                if interactionManager.scenarioAnswered {
                    Text("Completed")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.green)
                } else {
                    Text("Choose response")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(Color(white: 0.5))
                }
            }

            // Situation description
            if let situation = config?.situation {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Situation:")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.5))

                    Text(situation)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white)
                        .lineSpacing(4)
                }
            }

            // Response options
            if let options = config?.options {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How would you respond?")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.5))
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
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.35))
                        .italic()
                        .padding(.top, 4)
                        .transition(.opacity)
                }

                // General debrief
                if let debrief = config?.debrief {
                    Text("// \(debrief)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.35))
                        .padding(.top, 2)
                        .transition(.opacity)
                }
            }
        }
        .padding(16)
        .background(Color(white: 0.06))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(borderColor, lineWidth: 1)
        )
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
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(isSelected ? .green : Color(white: 0.3))
                    .frame(width: 12)

                // Option text
                Text(option.text)
                    .font(.system(.body, design: .monospaced))
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
            return Color(white: 0.3)
        } else if isSelected {
            return .white
        }
        return Color(white: 0.6)
    }

    private var borderColor: Color {
        if interactionManager.scenarioAnswered {
            return .green.opacity(0.5)
        } else if interactionManager.selectedScenarioOptionId != nil {
            return .green.opacity(0.3)
        }
        return Color(white: 0.15)
    }
}

