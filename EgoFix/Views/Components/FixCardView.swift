import SwiftUI

struct FixCardView: View {
    let fix: Fix
    var bugTitle: String?
    @ObservedObject var interactionManager: FixInteractionManager
    let onApplied: () -> Void
    let onSkipped: () -> Void
    let onFailed: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text("FIX #\(fixNumber)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)

                    Spacer()

                    // Show compact timer status in header when timer is running/paused
                    if fix.interactionType == .timed && (interactionManager.isTimerRunning || interactionManager.isTimerPaused) {
                        CompactInteractionTimerView(interactionManager: interactionManager)
                    }
                }

                // Bug nickname + severity as comment
                if let bugTitle = bugTitle {
                    Text("// \(bugTitle) \u{00B7} \(severityLabel)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            .padding(.bottom, 24)

            // Content area
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    // Prompt (only for standard type, others show in interaction view)
                    if fix.interactionType == .standard {
                        Text(fix.prompt)
                            .font(.system(.title3, design: .monospaced))
                            .foregroundColor(.white)
                            .lineSpacing(6)
                            .padding(.bottom, 16)
                    }

                    // Interaction-specific UI
                    if fix.interactionType != .standard {
                        FixInteractionView(fix: fix, interactionManager: interactionManager)
                            .padding(.bottom, 16)
                    }

                    // Inline comment — always visible
                    if let comment = fix.inlineComment {
                        Text("// \(comment)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(Color(white: 0.35))
                            .italic()
                            .lineSpacing(4)
                            .padding(.bottom, 16)
                    }
                }
            }

            Spacer(minLength: 16)

            // Completion requirement
            if !interactionManager.canMarkApplied && !completionRequirementText.isEmpty {
                Text("// \(completionRequirementText)")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(Color(white: 0.35))
                    .padding(.bottom, 16)
            }

            // Action buttons
            HStack(spacing: 16) {
                ActionButton(
                    label: "Apply",
                    color: interactionManager.canMarkApplied ? .green : Color(white: 0.3),
                    isDisabled: !interactionManager.canMarkApplied,
                    action: onApplied
                )
                ActionButton(label: "Skip", color: .yellow, action: onSkipped)
                ActionButton(label: "Fail", color: .red, action: onFailed)
            }
        }
        .padding(.vertical, 8)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }
        }
    }

    private var fixNumber: String {
        let hash = abs(fix.id.hashValue)
        return String(format: "%04d", hash % 10000)
    }

    private var severityLabel: String {
        switch fix.severity {
        case .low: return "low"
        case .medium: return "medium"
        case .high: return "high"
        }
    }

    private var completionRequirementText: String {
        switch fix.interactionType {
        case .standard, .reversal, .body, .counter: return ""
        case .timed: return "Timer required"
        case .multiStep: return "Complete all steps"
        case .quiz: return "Select an answer"
        case .scenario: return "Choose your response"
        case .observation: return "Report your observation"
        case .abstain: return "Mark when period ends"
        case .substitute: return "Track substitutions"
        case .journal: return "Write your reflection"
        case .predict: return "Predict, then observe"
        case .audit: return "Complete your audit"
        }
    }
}

struct ActionButton: View {
    let label: String
    let color: Color
    var isDisabled: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            guard !isDisabled else { return }
            action()
        }) {
            Text("[ \(label) ]")
                .font(.system(.subheadline, design: .monospaced))
                .foregroundColor(isPressed && !isDisabled ? .black : (isDisabled ? Color(white: 0.3) : color))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(isPressed && !isDisabled ? color : Color.clear)
                .cornerRadius(2)
                .shadow(color: isDisabled ? .clear : color.opacity(0.4), radius: 4, x: 0, y: 0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isDisabled { isPressed = true } }
                .onEnded { _ in isPressed = false }
        )
        .opacity(isDisabled ? 0.5 : 1)
    }
}
