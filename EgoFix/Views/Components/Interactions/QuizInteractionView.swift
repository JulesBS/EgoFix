import SwiftUI

struct QuizInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager

    private var config: QuizConfig? {
        interactionManager.quizConfig
    }

    private var selectedOption: QuizConfig.QuizOption? {
        interactionManager.selectedQuizOption
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            InteractionHeader(type: "ASSESSMENT", status: interactionManager.quizAnswered ? "Submitted" : "Select one")

            // Question
            if let question = config?.question {
                Text(question)
                    .font(EgoTheme.mono())
                    .foregroundColor(EgoTheme.textPrimary)
                    .lineSpacing(4)
            }

            // Options
            if let options = config?.options {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(options) { option in
                        optionRow(option)
                    }
                }
                .padding(.top, 4)
            }

            // Post-selection insight
            if interactionManager.quizAnswered {
                if let insight = interactionManager.selectedQuizInsight {
                    Text("// \(insight)")
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textMuted)
                        .italic()
                        .padding(.top, 4)
                        .transition(.opacity)
                }

                // General explanation
                if let explanation = config?.explanationAfter {
                    Text("// \(explanation)")
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
    private func optionRow(_ option: QuizConfig.QuizOption) -> some View {
        let isSelected = interactionManager.selectedOptionId == option.id
        let isDisabled = interactionManager.quizAnswered && !isSelected

        Button(action: {
            guard !interactionManager.quizAnswered else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                interactionManager.selectQuizOption(option)
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
        .disabled(interactionManager.quizAnswered)
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
        if interactionManager.quizAnswered {
            return .green.opacity(0.5)
        } else if interactionManager.selectedOptionId != nil {
            return .green.opacity(0.3)
        }
        return EgoTheme.surface
    }
}

