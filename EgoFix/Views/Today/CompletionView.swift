import SwiftUI

struct CompletionView: View {
    let outcome: FixOutcome
    var educationTidbit: String?

    @State private var appeared = false
    @State private var showMessage = false
    @State private var showEducation = false
    @State private var flashOpacity: Double = 0
    @State private var typedMessage = ""

    var body: some View {
        ZStack {
            // Outcome color flash overlay
            titleColor.opacity(flashOpacity)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Status symbol
                Text(symbol)
                    .font(.system(size: 48, design: .monospaced))
                    .foregroundColor(titleColor)
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)
                    .shadow(color: titleColor.opacity(0.5), radius: 8, x: 0, y: 0)

                Text(title)
                    .font(.system(.title2, design: .monospaced))
                    .foregroundColor(titleColor)
                    .padding(.top, 16)
                    .opacity(appeared ? 1 : 0)

                // Typing animation for message
                Text(typedMessage + (showMessage && typedMessage.count < message.count ? "_" : ""))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
                    .opacity(showMessage ? 1 : 0)

                // Micro-education tidbit
                if let tidbit = educationTidbit {
                    Text(tidbit)
                        .font(.system(.callout, design: .monospaced))
                        .foregroundColor(Color(white: 0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .opacity(showEducation ? 1 : 0)
                        .offset(y: showEducation ? 0 : 10)
                }

                Spacer()

                // Subtle hint
                Text("// Tomorrow brings another fix")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Color(white: 0.3))
                    .padding(.bottom, 48)
                    .opacity(showEducation ? 1 : 0)
            }
            .padding()
        }
        .onAppear {
            // Initial flash of outcome color
            flashOpacity = 0.3
            withAnimation(.easeOut(duration: 0.4)) {
                flashOpacity = 0
            }

            withAnimation(.easeOut(duration: 0.3)) {
                appeared = true
            }

            // Start typing animation after symbol appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showMessage = true
                typeMessage()
            }

            withAnimation(.easeOut(duration: 0.4).delay(1.5)) {
                showEducation = true
            }
        }
    }

    private func typeMessage() {
        let characters = Array(message)
        var currentIndex = 0

        func typeNextCharacter() {
            guard currentIndex < characters.count else { return }

            typedMessage.append(characters[currentIndex])
            currentIndex += 1

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                typeNextCharacter()
            }
        }

        typeNextCharacter()
    }

    private var symbol: String {
        switch outcome {
        case .applied: return "+"
        case .skipped: return "~"
        case .failed: return "x"
        case .pending: return "..."
        }
    }

    private var title: String {
        switch outcome {
        case .applied: return "FIX APPLIED"
        case .skipped: return "FIX SKIPPED"
        case .failed: return "FIX FAILED"
        case .pending: return "PENDING"
        }
    }

    private var titleColor: Color {
        switch outcome {
        case .applied: return .green
        case .skipped: return .yellow
        case .failed: return .red
        case .pending: return .gray
        }
    }

    private var message: String {
        switch outcome {
        case .applied: return "No fanfare. You did the thing."
        case .skipped: return "Noted. No judgment."
        case .failed: return "It happens. The bug won this round."
        case .pending: return ""
        }
    }
}
