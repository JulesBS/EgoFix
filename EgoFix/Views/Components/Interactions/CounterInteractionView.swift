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
            HStack {
                Text("COUNTER")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.green)

                Spacer()

                Text("Today")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(Color(white: 0.5))
            }

            // Counter prompt
            if let prompt = config?.counterPrompt {
                Text(prompt)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white)
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
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(Color(white: 0.5))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()
                }
            }

            // Event count comment
            Text("// \(eventCountLabel)")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(Color(white: 0.35))

            // Target indicator (if set)
            if let targetLabel = targetLabel {
                Text("// Target: \(targetLabel)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(targetColor)
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
            return Color(white: 0.5)
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
        interactionManager.counterMeetsTarget ? Color(white: 0.35) : .yellow
    }

    private var borderColor: Color {
        if interactionManager.counterValue > 0 {
            return .green.opacity(0.3)
        }
        return Color(white: 0.15)
    }
}

