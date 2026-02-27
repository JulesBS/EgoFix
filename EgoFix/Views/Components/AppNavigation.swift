import SwiftUI

// MARK: - Terminal Back Button

/// Replaces the default iOS back chevron with a monospaced `[ ← today ]` button.
private struct TerminalBackButton: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("[ \u{2190} today ]")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }
            }
    }
}

extension View {
    func terminalBackButton() -> some View {
        modifier(TerminalBackButton())
    }
}

/// Navigation destinations for the progressive disclosure system.
enum AppDestination: Hashable {
    case history
    case patterns
    case bugLibrary
    case docs
    case settings
}

/// Monospaced text nav bar shown after full nav unlocks (day 14+, 10+ fixes).
struct AppNavBar: View {
    let activeDestination: AppDestination?
    let isHistoryUnlocked: Bool
    let isPatternsUnlocked: Bool
    let onSelect: (AppDestination?) -> Void
    @State private var showOverflow = false

    var body: some View {
        HStack(spacing: 0) {
            navButton(label: "today", destination: nil, isActive: activeDestination == nil)

            if isHistoryUnlocked {
                navButton(label: "history", destination: .history, isActive: activeDestination == .history)
            }

            if isPatternsUnlocked {
                navButton(label: "patterns", destination: .patterns, isActive: activeDestination == .patterns)
            }

            Button(action: { showOverflow.toggle() }) {
                Text("···")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Color(white: 0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .popover(isPresented: $showOverflow, attachmentAnchor: .point(.top)) {
                OverflowMenu(onSelect: { dest in
                    showOverflow = false
                    onSelect(dest)
                })
                .presentationCompactAdaptation(.popover)
            }
        }
        .background(Color(white: 0.04))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(white: 0.12))
                .frame(height: 1)
        }
    }

    private func navButton(label: String, destination: AppDestination?, isActive: Bool) -> some View {
        Button(action: { onSelect(destination) }) {
            Text(label)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(isActive ? .green : Color(white: 0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
    }
}

/// Overflow menu for ··· button: Bug Library, Docs, Settings.
private struct OverflowMenu: View {
    let onSelect: (AppDestination) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            overflowButton("bug library", destination: .bugLibrary)
            overflowButton("docs", destination: .docs)
            overflowButton("settings", destination: .settings)
        }
        .padding(.vertical, 4)
        .frame(width: 160)
        .background(Color(white: 0.08))
    }

    private func overflowButton(_ label: String, destination: AppDestination) -> some View {
        Button(action: { onSelect(destination) }) {
            Text(label)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(Color(white: 0.6))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
    }
}

/// Footer links shown in the done-for-today state. Progressively reveals
/// navigation links as the user unlocks features.
struct FooterLinks: View {
    let tracker: AppProgressTracker
    let onNavigate: (AppDestination) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // History unlock
            if tracker.isHistoryUnlocked {
                if tracker.shouldShowHistoryUnlockPrompt {
                    UnlockPromptView(
                        comment: "// 3 fixes logged.\n// Your history is building.",
                        linkLabel: "[ View changelog → ]",
                        onTap: {
                            tracker.markHistoryUnlockSeen()
                            onNavigate(.history)
                        }
                    )
                } else {
                    footerLink("[ changelog → ]", destination: .history)
                }
            }

            // Patterns unlock
            if tracker.isPatternsUnlocked {
                if tracker.shouldShowPatternsUnlockPrompt {
                    UnlockPromptView(
                        comment: "// First pattern detected.\n// The app noticed something.",
                        linkLabel: "[ View pattern → ]",
                        onTap: {
                            tracker.markPatternsUnlockSeen()
                            onNavigate(.patterns)
                        }
                    )
                } else {
                    footerLink("[ patterns → ]", destination: .patterns)
                }
            }

            // Bug library unlock
            if tracker.isBugLibraryUnlocked {
                if tracker.shouldShowBugLibraryUnlockPrompt {
                    UnlockPromptView(
                        comment: "// v1.1 — your first update.\n// You can explore your bugs anytime.",
                        linkLabel: "[ bug library → ]",
                        onTap: {
                            tracker.markBugLibraryUnlockSeen()
                            onNavigate(.bugLibrary)
                        }
                    )
                } else {
                    footerLink("[ bug library → ]", destination: .bugLibrary)
                }
            }
        }
    }

    private func footerLink(_ label: String, destination: AppDestination) -> some View {
        Button(action: { onNavigate(destination) }) {
            Text(label)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(Color(white: 0.4))
        }
    }
}

/// One-time unlock prompt with typing comment + delayed link fade-in.
struct UnlockPromptView: View {
    let comment: String
    let linkLabel: String
    let onTap: () -> Void

    @State private var showLink = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TypewriterText(
                text: comment,
                characterDelay: 0.025,
                color: Color(white: 0.35),
                font: .system(.caption, design: .monospaced),
                onComplete: {
                    // Link fades in 0.5s after comment finishes typing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showLink = true
                        }
                    }
                }
            )

            if showLink {
                Button(action: onTap) {
                    Text(linkLabel)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.green)
                }
                .transition(.opacity)
            }
        }
    }
}
