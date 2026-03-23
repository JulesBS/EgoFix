import SwiftUI

struct StatsDashboardView: View {
    let stats: UserStats

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("STATS")
                .font(EgoTheme.label())
                .tracking(1.5)
                .foregroundColor(EgoTheme.textMuted)

            // Stats grid
            VStack(spacing: 8) {
                // Row 1: Applied | Success
                HStack(spacing: 0) {
                    statCell(
                        label: "Applied:",
                        value: stats.totalFixesApplied,
                        valueColor: .green
                    )
                    divider
                    statCell(
                        label: "Success:",
                        value: stats.successRateFormatted,
                        valueColor: .white
                    )
                }

                // Row 2: Skipped | Active
                HStack(spacing: 0) {
                    statCell(
                        label: "Skipped:",
                        value: stats.totalFixesSkipped,
                        valueColor: .yellow
                    )
                    divider
                    statCell(
                        label: "Active:",
                        value: "\(stats.daysActive) days",
                        valueColor: .white
                    )
                }

                // Row 3: Failed | Time
                HStack(spacing: 0) {
                    statCell(
                        label: "Failed:",
                        value: stats.totalFixesFailed,
                        valueColor: .red
                    )
                    divider
                    statCell(
                        label: "Time:",
                        value: stats.totalTimerFormatted,
                        valueColor: .white
                    )
                }
            }

            // Peak time (if available)
            if let peakTime = stats.peakTimeFormatted {
                Text("Peak: \(peakTime)")
                    .font(EgoTheme.mono())
                    .foregroundColor(EgoTheme.textMuted)
            }
        }
        .padding(20)
        .glassCard()
    }

    // MARK: - Private Views

    private var divider: some View {
        Text("|")
            .font(EgoTheme.mono())
            .foregroundColor(EgoTheme.textMuted)
            .frame(width: 24)
            .accessibilityHidden(true)
    }

    private func statCell(label: String, value: Int, valueColor: Color) -> some View {
        statCell(label: label, value: "\(value)", valueColor: valueColor)
    }

    private func statCell(label: String, value: String, valueColor: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textMuted)

            Spacer()

            Text(value)
                .font(.system(.body, design: .monospaced).monospacedDigit())
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(value)")
    }
}

#Preview {
    StatsDashboardView(
        stats: UserStats(
            totalFixesAssigned: 64,
            totalFixesApplied: 47,
            totalFixesSkipped: 11,
            totalFixesFailed: 6,
            totalTimerMinutes: 252,
            daysActive: 32,
            peakHour: 8,
            peakDayOfWeek: 3
        )
    )
}

#Preview("Empty Stats") {
    StatsDashboardView(stats: .empty)
}
