import SwiftUI

/// Animates a string character-by-character like a terminal typewriter.
struct TypewriterText: View {
    let text: String
    let characterDelay: Double
    var color: Color = .green
    var font: Font = .system(.body, design: .monospaced)
    var showCursor: Bool = false
    var onComplete: (() -> Void)?

    @State private var displayedCount: Int = 0
    @State private var cursorVisible = true
    @State private var completed = false

    var body: some View {
        HStack(spacing: 0) {
            Text(String(text.prefix(displayedCount)))
                .font(font)
                .foregroundColor(color)

            if showCursor {
                Text("_")
                    .font(font)
                    .foregroundColor(color)
                    .opacity(cursorVisible ? 1 : 0)
            }
        }
        .onAppear {
            startTyping()
            if showCursor {
                startCursorBlink()
            }
        }
    }

    private func startTyping() {
        guard displayedCount < text.count else {
            finish()
            return
        }

        typeNextCharacter()
    }

    private func typeNextCharacter() {
        guard displayedCount < text.count else {
            finish()
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + characterDelay) {
            displayedCount += 1
            typeNextCharacter()
        }
    }

    private func finish() {
        completed = true
        onComplete?()
    }

    private func startCursorBlink() {
        func blink() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                cursorVisible.toggle()
                blink()
            }
        }
        blink()
    }
}
