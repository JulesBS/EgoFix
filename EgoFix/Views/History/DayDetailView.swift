import SwiftUI

struct DayDetailView: View {
    let day: CalendarDay
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Text(formattedDate)
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: onDismiss) {
                        Text("[ Close ]")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(Color(white: 0.5))
                    }
                }

                Divider()
                    .background(Color(white: 0.2))

                // Activity breakdown
                VStack(alignment: .leading, spacing: 16) {
                    Text("ACTIVITY")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.4))

                    activityRow(label: "Applied", count: day.fixesApplied, color: .green)
                    activityRow(label: "Skipped", count: day.fixesSkipped, color: .yellow)
                    activityRow(label: "Failed", count: day.fixesFailed, color: .red)

                    if day.crashes > 0 {
                        Divider()
                            .background(Color(white: 0.2))
                        activityRow(label: "Crashes", count: day.crashes, color: .red)
                    }
                }

                Spacer()

                // Summary
                Text("// Total: \(day.totalActivity) events")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Color(white: 0.35))
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
                .font(.system(.body, design: .monospaced))
                .foregroundColor(Color(white: 0.6))

            Spacer()

            Text("\(count)")
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
                .foregroundColor(count > 0 ? color : Color(white: 0.3))
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
