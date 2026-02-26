import SwiftUI

struct ActivityCalendarView: View {
    let months: [CalendarMonth]
    @State private var currentMonthIndex: Int = 0
    @State private var selectedDay: CalendarDay?
    @State private var showingDayDetail = false

    var body: some View {
        VStack(spacing: 20) {
            if months.isEmpty {
                emptyState
            } else {
                // Month navigation
                monthHeader

                // Calendar grid
                MonthGridView(
                    month: months[currentMonthIndex],
                    onDayTap: { day in
                        if day.totalActivity > 0 {
                            selectedDay = day
                            showingDayDetail = true
                        }
                    }
                )

                // Legend
                legendView
            }
        }
        .padding()
        .sheet(isPresented: $showingDayDetail) {
            if let day = selectedDay {
                DayDetailView(day: day, onDismiss: { showingDayDetail = false })
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("// No activity data yet")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(Color(white: 0.35))
            Text("// Complete fixes to see your calendar")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(Color(white: 0.25))
            Spacer()
        }
    }

    private var monthHeader: some View {
        HStack {
            Button(action: previousMonth) {
                Text("[ < ]")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(currentMonthIndex > 0 ? .green : Color(white: 0.3))
            }
            .disabled(currentMonthIndex == 0)

            Spacer()

            Text(months[currentMonthIndex].shortLabel.uppercased())
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.white)

            Spacer()

            Button(action: nextMonth) {
                Text("[ > ]")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(currentMonthIndex < months.count - 1 ? .green : Color(white: 0.3))
            }
            .disabled(currentMonthIndex >= months.count - 1)
        }
    }

    private var legendView: some View {
        VStack(spacing: 12) {
            // Outcome colors
            HStack(spacing: 16) {
                Spacer()
                outcomeLegendItem(color: .green, label: "applied")
                outcomeLegendItem(color: .yellow, label: "skipped")
                outcomeLegendItem(color: .red, label: "crash")
                outcomeLegendItem(color: Color(white: 0.3), label: "opened")
                Spacer()
            }

            // Intensity explanation
            Text("// darker = more depth")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(Color(white: 0.3))
        }
    }

    private func outcomeLegendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(color)
                .frame(width: 12, height: 12)
                .cornerRadius(2)
            Text(label)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(Color(white: 0.4))
        }
    }

    private func previousMonth() {
        if currentMonthIndex > 0 {
            currentMonthIndex -= 1
        }
    }

    private func nextMonth() {
        if currentMonthIndex < months.count - 1 {
            currentMonthIndex += 1
        }
    }
}
