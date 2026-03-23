import SwiftUI

struct DayDetailView: View {
    let day: CalendarDay
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            EgoTheme.bg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Text(formattedDate)
                        .font(EgoTheme.mono(.headline))
                        .foregroundColor(EgoTheme.textPrimary)

                    Spacer()

                    Button(action: onDismiss) {
                        Text("[ x ]")
                            .font(EgoTheme.mono(.caption))
                            .foregroundColor(EgoTheme.textMuted)
                    }
                }

                TerminalDivider()

                // Activity breakdown
                VStack(alignment: .leading, spacing: 16) {
                    Text("ACTIVITY")
                        .font(EgoTheme.label())
                        .tracking(1.5)
                        .foregroundColor(EgoTheme.textMuted)

                    activityRow(label: "Applied", count: day.fixesApplied, color: EgoTheme.green)
                    activityRow(label: "Skipped", count: day.fixesSkipped, color: EgoTheme.amber)
                    activityRow(label: "Failed", count: day.fixesFailed, color: .red)

                    if day.crashes > 0 {
                        Divider()
                            .background(EgoTheme.borderSubtle)
                        activityRow(label: "Crashes", count: day.crashes, color: .red)
                    }
                }

                Spacer()

                // Summary
                Text("// Total: \(day.totalActivity) events")
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(EgoTheme.textMuted)
            }
            .padding(24)
        }
        .presentationDetents([.medium])
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter.string(from: day.id)
    }

    private func activityRow(label: String, count: Int, color: Color) -> some View {
        HStack {
            Text(label)
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textPrimary)

            Spacer()

            Text("\(count)")
                .font(EgoTheme.mono())
                .fontWeight(.medium)
                .foregroundColor(count > 0 ? color : EgoTheme.textMuted)
        }
    }
}

#Preview {
    DayDetailView(
        day: CalendarDay(
            id: Date(),
            fixesApplied: 3,
            fixesSkipped: 1,
            fixesFailed: 0,
            crashes: 1
        ),
        onDismiss: {}
    )
}
