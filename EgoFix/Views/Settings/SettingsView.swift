import SwiftUI

/// Minimal terminal-style settings screen.
struct SettingsView: View {
    @ObservedObject var progressTracker: AppProgressTracker

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showResetConfirmation = false
    @State private var showReplayConfirmation = false

    var body: some View {
        ZStack {
            EgoTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // HEADER
                    Text("SETTINGS")
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textMuted)
                        .padding(.bottom, 24)

                    // ABOUT
                    sectionHeader("ABOUT")

                    settingsRow("version", value: "EgoFix v1.0")
                    settingsRow("fixes completed", value: "\(progressTracker.totalFixesCompleted)")
                    settingsRow("days active", value: "\(progressTracker.daysActive)")

                    commentLine("// This is a debugger, not a self-help app.")
                        .padding(.top, 12)
                        .padding(.bottom, 24)

                    // UNLOCKED FEATURES
                    sectionHeader("FEATURES")

                    featureRow("history", unlocked: progressTracker.isHistoryUnlocked)
                    featureRow("patterns", unlocked: progressTracker.isPatternsUnlocked)
                    featureRow("bug library", unlocked: progressTracker.isBugLibraryUnlocked)
                    featureRow("full nav", unlocked: progressTracker.isFullNavUnlocked)

                    commentLine("// Features unlock as you generate data.")
                        .padding(.top, 12)
                        .padding(.bottom, 24)

                    // DEBUG
                    sectionHeader("DEBUG")

                    NavigationLink(destination: SoulDebugView().terminalBackButton()) {
                        Text("SOUL RENDERER")
                            .font(EgoTheme.mono())
                            .foregroundColor(EgoTheme.green)
                            .padding(.vertical, 12)
                    }

                    commentLine("// 3D ASCII animation preview.")
                        .padding(.top, 4)
                        .padding(.bottom, 16)

                    Button(action: { showReplayConfirmation = true }) {
                        Text("REPLAY ONBOARDING")
                            .font(EgoTheme.mono())
                            .foregroundColor(EgoTheme.green)
                            .padding(.vertical, 12)
                    }

                    commentLine("// Resets onboarding flag.")
                        .padding(.top, 4)
                        .padding(.bottom, 24)

                    // DANGER ZONE
                    sectionHeader("DANGER ZONE")

                    Button(action: { showResetConfirmation = true }) {
                        Text("RESET ALL DATA")
                            .font(EgoTheme.mono())
                            .foregroundColor(.red)
                            .padding(.vertical, 12)
                    }

                    commentLine("// This cannot be undone.")
                        .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Replay onboarding?", isPresented: $showReplayConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                replayOnboarding()
            }
        } message: {
            Text("This resets the onboarding flag. Close and reopen the app to replay the full onboarding.")
        }
        .alert("Reset all data?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will clear all progress, fixes, and patterns. You'll start from scratch.")
        }
    }

    // MARK: - Components

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(EgoTheme.label())
            .foregroundColor(EgoTheme.green)
            .padding(.bottom, 12)
    }

    private func settingsRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(EgoTheme.mono(.caption))
                .foregroundColor(EgoTheme.textPrimary)
            Spacer()
            Text(value)
                .font(EgoTheme.mono(.caption))
                .foregroundColor(EgoTheme.textPrimary)
        }
        .padding(.vertical, 6)
    }

    private func featureRow(_ label: String, unlocked: Bool) -> some View {
        HStack {
            Text(label)
                .font(EgoTheme.mono(.caption))
                .foregroundColor(EgoTheme.textPrimary)
            Spacer()
            Text(unlocked ? "unlocked" : "locked")
                .font(EgoTheme.mono(.caption))
                .foregroundColor(unlocked ? EgoTheme.green : EgoTheme.textMuted)
        }
        .padding(.vertical, 6)
    }

    private func commentLine(_ text: String) -> some View {
        Text(text)
            .font(EgoTheme.label())
            .foregroundColor(EgoTheme.textMuted)
    }

    // MARK: - Replay Onboarding

    private func replayOnboarding() {
        hasCompletedOnboarding = false
    }

    // MARK: - Reset

    private func resetAllData() {
        // Reset AppStorage flags
        hasCompletedOnboarding = false

        // Reset progress tracker
        progressTracker.totalFixesCompleted = 0
        progressTracker.firstDiagnosticCompleted = false
        progressTracker.firstPatternDetected = false
        progressTracker.daysActive = 0
        progressTracker.lastActiveDate = ""
        progressTracker.hasSeenHistoryUnlock = false
        progressTracker.hasSeenPatternsUnlock = false
        progressTracker.hasSeenBugLibraryUnlock = false
    }
}
