import SwiftUI

struct FixCardView: View {
    let fix: Fix
    var bugTitle: String?
    @ObservedObject var interactionManager: FixInteractionManager
    let onApplied: () -> Void
    let onSkipped: () -> Void
    let onFailed: () -> Void
    var onShare: (() -> Void)?

    @State private var appeared = false
    @State private var showValidation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (FIXED - always visible at top)
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text("FIX #\(fixNumber)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)

                    // Share button
                    if let onShare = onShare {
                        Button(action: onShare) {
                            Text("[ share ]")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.gray.opacity(0.6))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.leading, 8)
                    }

                    Spacer()

                    // Show compact timer status in header when timer is running/paused
                    if fix.interactionType == .timed && (interactionManager.isTimerRunning || interactionManager.isTimerPaused) {
                        CompactInteractionTimerView(interactionManager: interactionManager)
                    } else {
                        Text("Severity: \(severityLabel)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(severityColor)
                    }
                }

                // Bug badge
                if let bugTitle = bugTitle {
                    Text("// \(bugTitle)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.red.opacity(0.7))
                }
            }
            .padding(.bottom, 24)

            // Scrollable content area
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

                    // Validation criteria (for standard type only - others handle in interaction view)
                    if fix.interactionType == .standard {
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showValidation.toggle() } }) {
                                HStack(spacing: 6) {
                                    Text(showValidation ? "▼" : "▶")
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundColor(.green)
                                        .frame(width: 12)

                                    Text("VALIDATION")
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundColor(.green)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())

                            if showValidation {
                                Text(fix.validation)
                                    .font(.system(.subheadline, design: .monospaced))
                                    .foregroundColor(Color(white: 0.6))
                                    .lineSpacing(4)
                                    .padding(.leading, 18)
                                    .padding(.top, 4)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(.bottom, 16)

                        // Inline comment (for standard type only)
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
            }

            Spacer(minLength: 16)

            // Type indicator (FIXED - always visible at bottom)
            HStack {
                Text(typeLabel)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(typeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(typeColor.opacity(0.1))
                    .cornerRadius(2)

                // Interaction type badge
                Text(interactionTypeLabel)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(interactionTypeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(interactionTypeColor.opacity(0.1))
                    .cornerRadius(2)

                Spacer()

                // Completion requirement indicator
                if !interactionManager.canMarkApplied {
                    Text("// \(completionRequirementText)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(Color(white: 0.35))
                }
            }
            .padding(.bottom, 24)

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
        .padding(24)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }
        }
    }

    private var fixNumber: String {
        // Generate a consistent 4-digit number from UUID
        let hash = abs(fix.id.hashValue)
        return String(format: "%04d", hash % 10000)
    }

    private var severityLabel: String {
        switch fix.severity {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    private var severityColor: Color {
        switch fix.severity {
        case .low: return Color(white: 0.5)
        case .medium: return Color(red: 1.0, green: 0.85, blue: 0.3) // Warmer, brighter yellow
        case .high: return .red
        }
    }

    private var typeLabel: String {
        switch fix.type {
        case .daily: return "DAILY"
        case .weekly: return "WEEKLY"
        case .quickFix: return "QUICK FIX"
        }
    }

    private var typeColor: Color {
        switch fix.type {
        case .daily: return .blue
        case .weekly: return .purple
        case .quickFix: return .orange
        }
    }

    private var interactionTypeLabel: String {
        switch fix.interactionType {
        case .standard: return "STANDARD"
        case .timed: return "TIMED"
        case .multiStep: return "MULTI-STEP"
        case .quiz: return "QUIZ"
        case .scenario: return "SCENARIO"
        case .counter: return "COUNTER"
        case .observation: return "OBSERVATION"
        case .abstain: return "ABSTAIN"
        case .substitute: return "SUBSTITUTE"
        case .journal: return "JOURNAL"
        case .reversal: return "REVERSAL"
        case .predict: return "PREDICT"
        case .body: return "BODY"
        case .audit: return "AUDIT"
        }
    }

    private var interactionTypeColor: Color {
        switch fix.interactionType {
        case .standard: return Color(white: 0.5)
        case .timed: return .cyan
        case .multiStep: return .mint
        case .quiz: return .indigo
        case .scenario: return .pink
        case .counter: return .teal
        case .observation: return .yellow
        case .abstain: return .red
        case .substitute: return .orange
        case .journal: return .blue
        case .reversal: return .purple
        case .predict: return .green
        case .body: return .mint
        case .audit: return .gray
        }
    }

    private var completionRequirementText: String {
        switch fix.interactionType {
        case .standard, .reversal, .body: return ""
        case .timed: return "Timer required"
        case .multiStep: return "Complete all steps"
        case .quiz: return "Select an answer"
        case .scenario: return "Choose your response"
        case .counter: return ""
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
                .foregroundColor(isDisabled ? Color(white: 0.3) : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(isPressed && !isDisabled ? color.opacity(0.15) : Color.clear)
                .cornerRadius(2)
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
