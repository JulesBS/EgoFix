import SwiftUI

/// Types out text character by character, then glitches a specific word after typing completes.
/// Combines TypewriterText + GlitchText into one sequential animation.
struct GlitchTypewriterLine: View {
    let text: String
    let glitchWord: String
    let characterDelay: Double
    var color: Color = .green
    let onComplete: () -> Void

    @State private var phase: Phase = .typing
    @State private var displayedCount: Int = 0
    @State private var glitchDisplay: String = ""

    private enum Phase {
        case typing
        case glitching
        case done
    }

    private let glitchCharacters = "!@#$%^&*<>{}[]|/\\~`?=+_-"
    private let glitchSteps = 6
    private let glitchStepDuration = 0.05

    var body: some View {
        Text(currentText)
            .font(.system(.body, design: .monospaced))
            .foregroundColor(color)
            .task {
                await runAnimation()
            }
    }

    private var currentText: String {
        switch phase {
        case .typing:
            return String(text.prefix(displayedCount))
        case .glitching:
            return glitchDisplay
        case .done:
            return text
        }
    }

    private func runAnimation() async {
        // Type phase
        while displayedCount < text.count {
            try? await Task.sleep(nanoseconds: UInt64(characterDelay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            displayedCount += 1
        }

        // Glitch phase
        glitchDisplay = text
        phase = .glitching

        for step in 0..<glitchSteps {
            guard !Task.isCancelled else { return }
            if step >= glitchSteps - 2 {
                glitchDisplay = text
            } else {
                var chars = Array(text)
                if let range = text.range(of: glitchWord) {
                    let start = text.distance(from: text.startIndex, to: range.lowerBound)
                    let end = text.distance(from: text.startIndex, to: range.upperBound)
                    for i in start..<end {
                        if let c = glitchCharacters.randomElement() {
                            chars[i] = c
                        }
                    }
                }
                glitchDisplay = String(chars)
            }
            try? await Task.sleep(nanoseconds: UInt64(glitchStepDuration * 1_000_000_000))
        }

        guard !Task.isCancelled else { return }
        phase = .done
        glitchDisplay = text
        onComplete()
    }
}
