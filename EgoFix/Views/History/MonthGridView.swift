import SwiftUI

struct MonthGridView: View {
    let month: CalendarMonth
    let onDayTap: (CalendarDay) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(spacing: 8) {
            // Weekday headers
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(Color(white: 0.4))
                        .frame(height: 20)
                }
            }

            // Day cells
            LazyVGrid(columns: columns, spacing: 4) {
                // Leading empty cells for first week offset
                ForEach(0..<firstWeekdayOffset, id: \.self) { _ in
                    Color.clear
                        .frame(height: 20)
                }

                // Day cells
                ForEach(daysInMonth, id: \.self) { dayNumber in
                    let day = dayData(for: dayNumber)
                    DayCellView(day: day, dayNumber: dayNumber)
                        .onTapGesture {
                            if let day = day, day.totalActivity > 0 {
                                onDayTap(day)
                            }
                        }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var firstWeekdayOffset: Int {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: month.id)
        return weekday - 1  // Sunday = 1, so offset is 0 for Sunday
    }

    private var daysInMonth: [Int] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: month.id)!
        return Array(range)
    }

    private func dayData(for dayNumber: Int) -> CalendarDay? {
        let calendar = Calendar.current
        guard let date = calendar.date(byAdding: .day, value: dayNumber - 1, to: month.id) else {
            return nil
        }
        let startOfDay = calendar.startOfDay(for: date)
        return month.days.first { calendar.isDate($0.id, inSameDayAs: startOfDay) }
    }
}

struct DayCellView: View {
    let day: CalendarDay?
    let dayNumber: Int

    var body: some View {
        ZStack {
            Rectangle()
                .fill(backgroundColor)
                .frame(height: 20)
                .cornerRadius(2)

            if isToday {
                Rectangle()
                    .stroke(Color.green, lineWidth: 1)
                    .frame(height: 20)
                    .cornerRadius(2)
            }
        }
    }

    private var backgroundColor: Color {
        guard let day = day else {
            return Color(white: 0.1)
        }
        return colorForOutcome(day.outcomeColor, intensity: day.intensity)
    }

    private var isToday: Bool {
        let calendar = Calendar.current
        guard let day = day else { return false }
        return calendar.isDateInToday(day.id)
    }

    /// Map outcome + intensity to a color.
    /// Color = outcome (green/yellow/red), Opacity = depth (intensity).
    private func colorForOutcome(_ outcome: OutcomeColor, intensity: ActivityIntensity) -> Color {
        let baseColor: Color
        switch outcome {
        case .applied: baseColor = .green
        case .skipped: baseColor = .yellow
        case .crash: baseColor = .red
        case .opened: baseColor = Color(white: 0.3)
        case .empty: return Color(white: 0.1)
        }

        switch intensity {
        case .none: return Color(white: 0.1)
        case .low: return baseColor.opacity(0.3)
        case .medium: return baseColor.opacity(0.6)
        case .high: return baseColor
        }
    }
}
