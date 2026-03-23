import SwiftUI

// MARK: - Terminal Back Button

/// Replaces the default iOS back chevron with a themed back button.
private struct TerminalBackButton: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 10, weight: .medium))
                            Text("TODAY")
                                .tracking(1.5)
                        }
                        .font(EgoTheme.label())
                        .foregroundColor(EgoTheme.textMuted)
                    }
                    .accessibilityLabel("Back to Today")
                    .accessibilityHint("Returns to the Today view")
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
    case soulDebug
}

/// Bottom nav bar shown after full nav unlocks (day 14+, 10+ fixes).
struct AppNavBar: View {
    let activeDestination: AppDestination?
    let isHistoryUnlocked: Bool
    let isPatternsUnlocked: Bool
    let onSelect: (AppDestination?) -> Void
    @State private var showOverflow = false

    var body: some View {
        HStack(spacing: 0) {
            navButton(label: "TODAY", destination: nil, isActive: activeDestination == nil)

            if isHistoryUnlocked {
                navButton(label: "HISTORY", destination: .history, isActive: activeDestination == .history)
            }

            if isPatternsUnlocked {
                navButton(label: "PATTERNS", destination: .patterns, isActive: activeDestination == .patterns)
            }

            Button(action: { showOverflow.toggle() }) {
                Text("···")
                    .font(EgoTheme.label())
                    .foregroundColor(EgoTheme.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .accessibilityLabel("More options")
            .accessibilityHint("Shows Bug Library, Docs, and Settings")
            .popover(isPresented: $showOverflow, attachmentAnchor: .point(.top)) {
                OverflowMenu(onSelect: { dest in
                    showOverflow = false
                    onSelect(dest)
                })
                .presentationCompactAdaptation(.popover)
            }
        }
        .background(EgoTheme.bg)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(EgoTheme.borderSubtle)
                .frame(height: 0.5)
                .accessibilityHidden(true)
        }
    }

    private func navButton(label: String, destination: AppDestination?, isActive: Bool) -> some View {
        Button(action: { onSelect(destination) }) {
            VStack(spacing: 0) {
                // Active indicator bar
                Rectangle()
                    .fill(isActive ? EgoTheme.green : Color.clear)
                    .frame(height: 1)
                    .shadow(color: isActive ? EgoTheme.greenGlow : .clear, radius: 4)
                    .accessibilityHidden(true)

                Text(label)
                    .font(EgoTheme.label())
                    .tracking(1.5)
                    .foregroundColor(isActive ? EgoTheme.green : EgoTheme.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
        }
        .accessibilityLabel(label)
        .accessibilityHint(isActive ? "Currently selected" : "Switch to \(label)")
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

/// Overflow menu for ··· button: Bug Library, Docs, Settings.
private struct OverflowMenu: View {
    let onSelect: (AppDestination) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            overflowButton("BUG LIBRARY", destination: .bugLibrary)
            overflowButton("DOCS", destination: .docs)
            overflowButton("SETTINGS", destination: .settings)
        }
        .padding(.vertical, 4)
        .frame(width: 180)
        .background(EgoTheme.surface)
    }

    private func overflowButton(_ label: String, destination: AppDestination) -> some View {
        Button(action: { onSelect(destination) }) {
            Text(label)
                .font(EgoTheme.label())
                .tracking(1)
                .foregroundColor(EgoTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
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
            if tracker.isHistoryUnlocked {
                if tracker.shouldShowHistoryUnlockPrompt {
                    UnlockPromptView(
                        comment: "// 3 fixes logged.\n// Your history is building.",
                        linkLabel: "VIEW CHANGELOG",
                        onTap: {
                            tracker.markHistoryUnlockSeen()
                            onNavigate(.history)
                        }
                    )
                } else {
                    footerLink("CHANGELOG", destination: .history)
                }
            }

            if tracker.isPatternsUnlocked {
                if tracker.shouldShowPatternsUnlockPrompt {
                    UnlockPromptView(
                        comment: "// First pattern detected.\n// The app noticed something.",
                        linkLabel: "VIEW PATTERN",
                        onTap: {
                            tracker.markPatternsUnlockSeen()
                            onNavigate(.patterns)
                        }
                    )
                } else {
                    footerLink("PATTERNS", destination: .patterns)
                }
            }

            if tracker.isBugLibraryUnlocked {
                if tracker.shouldShowBugLibraryUnlockPrompt {
                    UnlockPromptView(
                        comment: "// v1.1 — your first update.\n// You can explore your bugs anytime.",
                        linkLabel: "BUG LIBRARY",
                        onTap: {
                            tracker.markBugLibraryUnlockSeen()
                            onNavigate(.bugLibrary)
                        }
                    )
                } else {
                    footerLink("BUG LIBRARY", destination: .bugLibrary)
                }
            }
        }
    }

    private func footerLink(_ label: String, destination: AppDestination) -> some View {
        Button(action: { onNavigate(destination) }) {
            HStack(spacing: 6) {
                Text(label)
                    .font(EgoTheme.label())
                    .tracking(1.5)
                    .foregroundColor(EgoTheme.textMuted)
                Image(systemName: "arrow.right")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(EgoTheme.textMuted)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityLabel("Go to \(label)")
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
                color: EgoTheme.textMuted,
                font: EgoTheme.mono(.caption),
                onComplete: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showLink = true
                        }
                    }
                }
            )

            if showLink {
                Button(action: onTap) {
                    HStack(spacing: 6) {
                        Text(linkLabel)
                            .font(EgoTheme.label())
                            .tracking(1.5)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 8, weight: .medium))
                            .accessibilityHidden(true)
                    }
                    .foregroundColor(EgoTheme.green)
                    .greenGlow()
                }
                .accessibilityLabel(linkLabel)
                .accessibilityHint("Opens newly unlocked feature")
                .transition(.opacity)
            }
        }
    }
}
