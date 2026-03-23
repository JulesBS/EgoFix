import SwiftUI

struct CounterInteractionView: View {
    let fix: Fix
    @ObservedObject var interactionManager: FixInteractionManager

    private var config: CounterConfig? {
        interactionManager.counterConfig
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            InteractionHeader(type: "COUNTER", status: "Today")

            // Counter prompt
            if let prompt = config?.counterPrompt {
                Text(prompt)
                    .font(EgoTheme.mono())
                    .foregroundColor(EgoTheme.textPrimary)
                    .lineSpacing(4)
            }

            // Big count display
            HStack {
                Spacer()

                Text("[ \(formattedCount) ]")
                    .font(.system(.largeTitle, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(countColor)
                    .monospacedDigit()
                    .accessibilityLabel("Count: \(interactionManager.counterValue)")

                Spacer()
            }
            .padding(.vertical, 8)

            // Increment button
            HStack {
                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        interactionManager.incrementCounter()
                    }
                }) {
                    Text("[ + ]")
                        .font(.system(.title, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Increment count")
                .accessibilityHint("Adds one to the counter")

                Spacer()
            }

            // Decrement option (smaller, secondary)
            if interactionManager.counterValue > 0 {
                HStack {
                    Spacer()

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            interactionManager.decrementCounter()
                        }
                    }) {
                        Text("[ - ]")
                            .font(EgoTheme.mono(.callout))
                            .foregroundColor(EgoTheme.textMuted)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Decrement count")
                    .accessibilityHint("Subtracts one from the counter")

                    Spacer()
                }
            }

            // Event count comment
            Text("// \(eventCountLabel)")
                .font(EgoTheme.mono(.caption))
                .foregroundColor(EgoTheme.textMuted)

            // Target indicator (if set)
            if let targetLabel = targetLabel {
                Text("// Target: \(targetLabel)")
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(targetColor)
            }
        }
        .interactionCard(borderColor: borderColor)
        .accessibilityLabel("Counter interaction, count: \(interactionManager.counterValue)")
    }

    // MARK: - Computed Properties

    private var formattedCount: String {
        String(format: "%03d", interactionManager.counterValue)
    }

    private var eventCountLabel: String {
        let count = interactionManager.counterHistory.count
        if count == 1 {
            return "1 event today"
        }
        return "\(count) events today"
    }

    private var countColor: Color {
        guard let config = config else { return .white }

        // Check if below min target
        if let min = config.minTarget, interactionManager.counterValue < min {
            return EgoTheme.textMuted
        }

        // Check if above max target (warning)
        if let max = config.maxTarget, interactionManager.counterValue > max {
            return .yellow
        }

        return .green
    }

    private var targetLabel: String? {
        guard let config = config else { return nil }

        if let min = config.minTarget, let max = config.maxTarget {
            return "\(min)-\(max)"
        } else if let min = config.minTarget {
            return "min \(min)"
        } else if let max = config.maxTarget {
            return "max \(max)"
        }

        return nil
    }

    private var targetColor: Color {
        interactionManager.counterMeetsTarget ? EgoTheme.textMuted : .yellow
    }

    private var borderColor: Color {
        if interactionManager.counterValue > 0 {
            return .green.opacity(0.3)
        }
        return EgoTheme.surface
    }
}

