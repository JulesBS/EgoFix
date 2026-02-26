import SwiftUI

/// Terminal-style boot sequence animation displayed on cold app launch.
/// Shows green monospaced text appearing line-by-line with animated progress bars.
struct BootSequenceView: View {
    let onComplete: () -> Void

    @State private var currentLineIndex = 0
    @State private var progressValues: [Int] = [0, 0, 0]
    @State private var cursorVisible = true
    @State private var cursorBlinkCount = 0
    @State private var showCursor = false

    private let lines: [BootLine] = [
        .text("EgoFix v1.0"),
        .text("Loading modules..."),
        .progressBar(label: "bugs.db", index: 0),
        .progressBar(label: "fixes.db", index: 1),
        .progressBar(label: "patterns.db", index: 2),
        .text("System ready."),
        .cursor
    ]

    private enum BootLine {
        case text(String)
        case progressBar(label: String, index: Int)
        case cursor
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 4) {
                ForEach(0..<min(currentLineIndex + 1, lines.count), id: \.self) { index in
                    lineView(for: lines[index])
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .onAppear {
            startSequence()
        }
    }

    @ViewBuilder
    private func lineView(for line: BootLine) -> some View {
        switch line {
        case .text(let text):
            Text(text)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.green)

        case .progressBar(let label, let index):
            HStack(spacing: 0) {
                Text("[")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.green)

                Text(progressString(for: progressValues[index]))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.green)

                Text("] ")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.green)

                Text(label)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.green)
            }

        case .cursor:
            HStack(spacing: 0) {
                Text("> ")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.green)

                if showCursor {
                    Text("_")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.green)
                        .opacity(cursorVisible ? 1 : 0)
                }
            }
        }
    }

    private func progressString(for value: Int) -> String {
        let filled = String(repeating: "#", count: value)
        let empty = String(repeating: " ", count: 16 - value)
        return filled + empty
    }

    private func startSequence() {
        showNextLine()
    }

    private func showNextLine() {
        guard currentLineIndex < lines.count else {
            return
        }

        let line = lines[currentLineIndex]

        switch line {
        case .text:
            // Show text line, then delay before next
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                currentLineIndex += 1
                showNextLine()
            }

        case .progressBar(_, let index):
            // Animate progress bar
            animateProgressBar(index: index) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    currentLineIndex += 1
                    showNextLine()
                }
            }

        case .cursor:
            // Show cursor and blink twice, then complete
            showCursor = true
            startCursorBlink()
        }
    }

    private func animateProgressBar(index: Int, completion: @escaping () -> Void) {
        let totalSteps = 16
        let stepDuration = 0.025

        func animateStep(_ step: Int) {
            guard step <= totalSteps else {
                completion()
                return
            }

            progressValues[index] = step

            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration) {
                animateStep(step + 1)
            }
        }

        animateStep(1)
    }

    private func startCursorBlink() {
        let blinkDuration = 0.3
        let totalBlinks = 3

        func blink(_ count: Int) {
            guard count < totalBlinks * 2 else {
                // Done blinking, complete the sequence
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onComplete()
                }
                return
            }

            cursorVisible.toggle()

            DispatchQueue.main.asyncAfter(deadline: .now() + blinkDuration) {
                blink(count + 1)
            }
        }

        cursorVisible = true
        DispatchQueue.main.asyncAfter(deadline: .now() + blinkDuration) {
            blink(0)
        }
    }
}

#Preview {
    BootSequenceView(onComplete: {})
}
