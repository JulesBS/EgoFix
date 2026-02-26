import SwiftUI

struct StreakCardView: View {
    let streakData: StreakData

    private let barCharCount = 16

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("STREAK")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.white)

            // Progress bars
            VStack(alignment: .leading, spacing: 8) {
                // Current streak bar
                HStack(spacing: 8) {
                    Text(currentStreakBar)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.green)

                    Text("\(streakData.currentStreak) days current")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white)
                }

                // Longest streak bar
                HStack(spacing: 8) {
                    Text(longestStreakBar)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(Color.green.opacity(0.5))

                    Text("\(streakData.longestStreak) days longest")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white)
                }
            }

            // Comment
            Text(commentText)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(Color(white: 0.35))
        }
        .padding(16)
        .background(Color.black)
        .cornerRadius(2)
    }

    // MARK: - Private

    private var currentStreakBar: String {
        let filledCount: Int
        if streakData.longestStreak > 0 {
            let ratio = Double(streakData.currentStreak) / Double(streakData.longestStreak)
            filledCount = Int(round(ratio * Double(barCharCount)))
        } else {
            filledCount = 0
        }
        let emptyCount = barCharCount - filledCount
        let filled = String(repeating: "\u{2588}", count: filledCount)
        let empty = String(repeating: "\u{2591}", count: emptyCount)
        return filled + empty
    }

    private var longestStreakBar: String {
        // Longest bar is always full
        return String(repeating: "\u{2593}", count: barCharCount)
    }

    private var commentText: String {
        // This metric is meaningless. But you looked anyway.
        if streakData.isStreakAtRisk {
            return "// This metric is meaningless. But you looked anyway."
        } else if streakData.currentStreak > 0 {
            return "// This metric is meaningless. But you looked anyway."
        } else {
            return "// Start whenever."
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StreakCardView(streakData: StreakData(
            currentStreak: 12,
            longestStreak: 24,
            lastActiveDate: Date(),
            streakStartDate: Calendar.current.date(byAdding: .day, value: -12, to: Date())
        ))

        StreakCardView(streakData: StreakData(
            currentStreak: 0,
            longestStreak: 10,
            lastActiveDate: nil,
            streakStartDate: nil
        ))

        StreakCardView(streakData: StreakData(
            currentStreak: 5,
            longestStreak: 20,
            lastActiveDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            streakStartDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())
        ))
    }
    .padding()
    .background(Color.black)
}
