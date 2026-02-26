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
            HStack {
                Text("ASSESSMENT")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.green)

                Spacer()

                if interactionManager.quizAnswered {
                    Text("Submitted")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.green)
                } else {
                    Text("Select one")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(Color(white: 0.5))
                }
            }

            // Question
            if let question = config?.question {
                Text(question)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white)
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
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.35))
                        .italic()
                        .padding(.top, 4)
                        .transition(.opacity)
                }

                // General explanation
                if let explanation = config?.explanationAfter {
                    Text("// \(explanation)")
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
        .disabled(interactionManager.quizAnswered)
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
        if interactionManager.quizAnswered {
            return .green.opacity(0.5)
        } else if interactionManager.selectedOptionId != nil {
            return .green.opacity(0.3)
        }
        return Color(white: 0.15)
    }
}

