import SwiftUI

/// Displays text where a specific substring briefly glitches with random characters
/// before resolving to the correct text. Used for the "ego" glitch in boot sequence.
struct GlitchText: View {
    let text: String
    let glitchWord: String
    let glitchDuration: Double
    var color: Color = .green
    var font: Font = .system(.body, design: .monospaced)
    var onComplete: (() -> Void)?

    @State private var displayText: String = ""
    @State private var isGlitching = false

    private let glitchCharacters = "!@#$%^&*<>{}[]|/\\~`?=+_-"
    private let glitchSteps = 6
    private var stepDuration: Double { glitchDuration / Double(glitchSteps) }

    var body: some View {
        Text(displayText)
            .font(font)
            .foregroundColor(color)
            .onAppear {
                displayText = text
                startGlitch()
            }
    }

    private func startGlitch() {
        guard let range = text.range(of: glitchWord) else {
            onComplete?()
            return
        }

        isGlitching = true
        performGlitchStep(0, wordRange: range)
    }

    private func performGlitchStep(_ step: Int, wordRange: Range<String.Index>) {
        guard step < glitchSteps else {
            // Resolve to real text
            displayText = text
            isGlitching = false
            onComplete?()
            return
        }

        // Last 2 steps: start resolving (show real text with minor corruption)
        if step >= glitchSteps - 2 {
            displayText = text
        } else {
            // Replace the glitch word with random characters
            var chars = Array(text)
            let startIndex = text.distance(from: text.startIndex, to: wordRange.lowerBound)
            let endIndex = text.distance(from: text.startIndex, to: wordRange.upperBound)

            for i in startIndex..<endIndex {
                if let randomChar = glitchCharacters.randomElement() {
                    chars[i] = randomChar
                }
            }
            displayText = String(chars)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration) {
            performGlitchStep(step + 1, wordRange: wordRange)
        }
    }
}
