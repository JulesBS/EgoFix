import SwiftUI

/// Shown when the user reopens the app while a fix is active.
/// Feels like a running process — pulsing label, elapsed time.
struct FixActiveView: View {
    let fix: Fix
    let bugTitle: String?
    var acceptedAt: Date?
    let onCheckIn: () -> Void
    let onCrash: () -> Void

    @State private var pulseOpacity: Double = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Glass card: active process
            VStack(alignment: .leading, spacing: 0) {
                // Pulsing "PROCESS / RUNNING" label
                HStack(spacing: 8) {
                    Circle()
                        .fill(EgoTheme.green)
                        .frame(width: 6, height: 6)
                        .opacity(pulseOpacity)
                        .accessibilityHidden(true)

                    Text("PROCESS / RUNNING")
                        .font(EgoTheme.label())
                        .tracking(1.5)
                        .foregroundColor(EgoTheme.green)
                        .opacity(pulseOpacity)
                }
                .greenGlow()
                .padding(.bottom, 16)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Fix active, running")
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true)
                    ) {
                        pulseOpacity = 0.4
                    }
                }

                Text(fix.prompt)
                    .font(.system(size: 18, weight: .light, design: .monospaced))
                    .foregroundColor(EgoTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if let comment = fix.inlineComment {
                    Rectangle()
                        .fill(EgoTheme.borderSubtle)
                        .frame(height: 0.5)
                        .padding(.vertical, 12)
                        .accessibilityHidden(true)

                    Text("// \(comment)")
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Elapsed time
                if let acceptedAt {
                    Rectangle()
                        .fill(EgoTheme.borderSubtle)
                        .frame(height: 0.5)
                        .padding(.vertical, 12)
                        .accessibilityHidden(true)

                    HStack {
                        Text("ELAPSED")
                            .font(EgoTheme.label())
                            .tracking(1)
                            .foregroundColor(EgoTheme.textMuted)
                        Spacer()
                        TimelineView(.periodic(from: .now, by: 60)) { _ in
                            Text(formatElapsed(since: acceptedAt))
                                .font(EgoTheme.mono(.caption))
                                .foregroundColor(EgoTheme.green)
                                .monospacedDigit()
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Elapsed time: \(formatElapsed(since: acceptedAt))")
                }
            }
            .padding(24)
            .glassCard()

            // CTA: Check in
            FigmaCTAButton(label: "CHECK IN", action: onCheckIn)
                .accessibilityHint("Report how the fix went today")
        }
    }

    private func formatElapsed(since date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
