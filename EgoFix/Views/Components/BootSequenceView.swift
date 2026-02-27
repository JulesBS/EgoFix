import SwiftUI

/// Narrative boot sequence that sets the app's tone on first launch.
/// First launch: ~8 second typewriter narrative with "ego" glitch + [ Begin scan ] button.
/// Subsequent launches: abbreviated 2-second version.
struct BootSequenceView: View {
    let isFirstLaunch: Bool
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isFirstLaunch {
                FirstLaunchBootView(onComplete: onComplete)
            } else {
                ReturningBootView(onComplete: onComplete)
            }
        }
    }
}

// MARK: - First Launch Boot

private struct FirstLaunchBootView: View {
    let onComplete: () -> Void

    @State private var currentLine = 0
    @State private var showButton = false

    // Lines with their delays and speeds
    private struct BootLine {
        let text: String
        let characterDelay: Double
        let postDelay: Double  // delay after this line completes before next starts
        let isTerminal: Bool   // green > prefix style
        let glitchWord: String? // word to glitch in this line
    }

    private let lines: [BootLine] = [
        BootLine(text: "> scanning user...", characterDelay: 0.025, postDelay: 0.3, isTerminal: true, glitchWord: nil),
        BootLine(text: "> ego detected.", characterDelay: 0.025, postDelay: 0.4, isTerminal: true, glitchWord: "ego"),
        BootLine(text: "> multiple patterns found.", characterDelay: 0.025, postDelay: 0.3, isTerminal: true, glitchWord: nil),
        BootLine(text: "> status: unexamined.", characterDelay: 0.025, postDelay: 0.8, isTerminal: true, glitchWord: nil),
        BootLine(text: "This is not a self-help app.", characterDelay: 0.035, postDelay: 0.3, isTerminal: false, glitchWord: nil),
        BootLine(text: "This is a debugger.", characterDelay: 0.035, postDelay: 0.8, isTerminal: false, glitchWord: nil),
        BootLine(text: "Your ego is legacy code —", characterDelay: 0.035, postDelay: 0.2, isTerminal: false, glitchWord: nil),
        BootLine(text: "poorly documented functions", characterDelay: 0.035, postDelay: 0.2, isTerminal: false, glitchWord: nil),
        BootLine(text: "that fire when they shouldn't.", characterDelay: 0.035, postDelay: 0.8, isTerminal: false, glitchWord: nil),
        BootLine(text: "Let's see what we're working with.", characterDelay: 0.035, postDelay: 0.0, isTerminal: false, glitchWord: nil),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 6) {
                ForEach(0..<min(currentLine + 1, lines.count), id: \.self) { index in
                    let line = lines[index]

                    if index < currentLine {
                        // Already completed — static text
                        completedLineView(line)
                    } else if index == currentLine {
                        // Currently animating
                        activeLineView(line, index: index)
                    }
                }
            }

            Spacer()
                .frame(height: 60)

            if showButton {
                Button(action: onComplete) {
                    Text("[ Begin scan ]")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.green)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(2)
                }
                .frame(maxWidth: .infinity)
                .transition(.opacity)
            }

            Spacer()
                .frame(height: 80)
        }
        .padding(.horizontal, 24)
        .onAppear {
            animateLine(0)
        }
    }

    private func completedLineView(_ line: BootLine) -> some View {
        Group {
            if line.isTerminal && !line.text.hasPrefix(">") {
                Text(line.text)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.green)
            } else if !line.isTerminal {
                Text(line.text)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.top, line.text == "This is not a self-help app." ? 16 : 0)
                    .padding(.top, line.text == "Your ego is legacy code —" ? 12 : 0)
                    .padding(.top, line.text == "Let's see what we're working with." ? 12 : 0)
            } else {
                Text(line.text)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.green)
            }
        }
    }

    @ViewBuilder
    private func activeLineView(_ line: BootLine, index: Int) -> some View {
        if let glitchWord = line.glitchWord {
            // Line with glitch effect — type it out, then glitch
            GlitchTypewriterLine(
                text: line.text,
                glitchWord: glitchWord,
                characterDelay: line.characterDelay,
                color: line.isTerminal ? .green : .white,
                onComplete: {
                    advanceToNext(index)
                }
            )
        } else {
            TypewriterText(
                text: line.text,
                characterDelay: line.characterDelay,
                color: line.isTerminal ? .green : .white,
                onComplete: {
                    advanceToNext(index)
                }
            )
            .padding(.top, line.text == "This is not a self-help app." ? 16 : 0)
            .padding(.top, line.text == "Your ego is legacy code —" ? 12 : 0)
            .padding(.top, line.text == "Let's see what we're working with." ? 12 : 0)
        }
    }

    private func advanceToNext(_ index: Int) {
        let postDelay = lines[index].postDelay
        DispatchQueue.main.asyncAfter(deadline: .now() + postDelay) {
            if index + 1 < lines.count {
                animateLine(index + 1)
            } else {
                withAnimation(.easeIn(duration: 0.5)) {
                    showButton = true
                }
            }
        }
    }

    private func animateLine(_ index: Int) {
        currentLine = index
    }
}

// MARK: - Glitch + Typewriter combo

/// Types out text character by character, then glitches a specific word after typing completes.
private struct GlitchTypewriterLine: View {
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
            .onAppear {
                startTyping()
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

    private func startTyping() {
        typeNext()
    }

    private func typeNext() {
        guard displayedCount < text.count else {
            // Done typing, start glitch
            glitchDisplay = text
            phase = .glitching
            performGlitch(step: 0)
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + characterDelay) {
            displayedCount += 1
            typeNext()
        }
    }

    private func performGlitch(step: Int) {
        guard step < glitchSteps else {
            phase = .done
            glitchDisplay = text
            onComplete()
            return
        }

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

        DispatchQueue.main.asyncAfter(deadline: .now() + glitchStepDuration) {
            performGlitch(step: step + 1)
        }
    }
}

// MARK: - Returning Boot (abbreviated)

private struct ReturningBootView: View {
    let onComplete: () -> Void

    @State private var showLine = false
    @State private var glitchDone = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Spacer()

            if showLine {
                GlitchText(
                    text: "> ego detected.",
                    glitchWord: "ego",
                    glitchDuration: 0.3,
                    color: .green,
                    onComplete: {
                        glitchDone = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            onComplete()
                        }
                    }
                )

                if glitchDone {
                    Text("> resuming...")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.green)
                        .transition(.opacity)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showLine = true
            }
        }
    }
}

#Preview("First Launch") {
    BootSequenceView(isFirstLaunch: true, onComplete: {})
}

#Preview("Returning") {
    BootSequenceView(isFirstLaunch: false, onComplete: {})
}
