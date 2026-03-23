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
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            if showCursor {
                Text("_")
                    .font(font)
                    .foregroundColor(color)
                    .opacity(cursorVisible ? 1 : 0)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                            cursorVisible = false
                        }
                    }
            }

            Spacer(minLength: 0)
        }
        .task {
            await typeText()
        }
    }

    private func typeText() async {
        guard displayedCount < text.count else {
            finish()
            return
        }
        while displayedCount < text.count {
            try? await Task.sleep(nanoseconds: UInt64(characterDelay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            displayedCount += 1
        }
        finish()
    }

    private func finish() {
        guard !completed else { return }
        completed = true
        onComplete?()
    }
}
