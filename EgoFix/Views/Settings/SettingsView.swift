import SwiftUI

/// Minimal terminal-style settings screen.
struct SettingsView: View {
    @ObservedObject var progressTracker: AppProgressTracker
    let bugRepository: BugRepository?

    @AppStorage("hasSeenBoot") private var hasSeenBoot = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showResetConfirmation = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // HEADER
                    Text("SETTINGS")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.4))
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

                    // DANGER ZONE
                    sectionHeader("DANGER ZONE")

                    Button(action: { showResetConfirmation = true }) {
                        Text("[ Reset all data ]")
                            .font(.system(.body, design: .monospaced))
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
            .font(.system(.caption2, design: .monospaced))
            .foregroundColor(.green)
            .padding(.bottom, 12)
    }

    private func settingsRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(Color(white: 0.6))
            Spacer()
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.vertical, 6)
    }

    private func featureRow(_ label: String, unlocked: Bool) -> some View {
        HStack {
            Text(label)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(Color(white: 0.6))
            Spacer()
            Text(unlocked ? "unlocked" : "locked")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(unlocked ? .green : Color(white: 0.3))
        }
        .padding(.vertical, 6)
    }

    private func commentLine(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption2, design: .monospaced))
            .foregroundColor(Color(white: 0.3))
    }

    // MARK: - Reset

    private func resetAllData() {
        // Reset AppStorage flags
        hasSeenBoot = false
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
