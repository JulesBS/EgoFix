import SwiftUI

struct PatternDetailView: View {
    let pattern: DetectedPattern
    let trendDataPoints: [TrendDataPoint]
    let onDismiss: () -> Void

    init(pattern: DetectedPattern, trendDataPoints: [TrendDataPoint] = [], onDismiss: @escaping () -> Void) {
        self.pattern = pattern
        self.trendDataPoints = trendDataPoints
        self.onDismiss = onDismiss
    }

    private var recommendations: [PatternRecommendation] {
        RecommendationEngine.generateRecommendations(for: pattern)
    }

    private var trendDirection: TrendDirection {
        BugTrendData.calculateDirection(from: trendDataPoints)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with close button
                    HStack {
                        Spacer()
                        Button(action: onDismiss) {
                            Text("[ Close ]")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(Color(white: 0.5))
                        }
                    }

                    // Severity badge and date
                    HStack {
                        Text(severityLabel)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(severityColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(severityColor.opacity(0.1))
                            .cornerRadius(2)

                        Spacer()

                        Text(formatDate(pattern.detectedAt))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(Color(white: 0.4))
                    }

                    // Title
                    Text(pattern.title)
                        .font(.system(.title3, design: .monospaced))
                        .foregroundColor(.white)

                    // Body
                    Text(pattern.body)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(Color(white: 0.7))
                        .lineSpacing(4)

                    // Data points info
                    Text("// Based on \(pattern.dataPoints) data points")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.35))

                    // Trend chart (if data available)
                    if !trendDataPoints.isEmpty {
                        Divider()
                            .background(Color(white: 0.2))
                            .padding(.vertical, 8)

                        TrendChartView(
                            title: "Bug Intensity",
                            dataPoints: trendDataPoints,
                            trendDirection: trendDirection
                        )
                    }

                    Divider()
                        .background(Color(white: 0.2))
                        .padding(.vertical, 8)

                    // Recommendations section
                    Text("RECOMMENDATIONS")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(Color(white: 0.4))

                    ForEach(recommendations) { recommendation in
                        RecommendationCardView(recommendation: recommendation)
                    }

                    Spacer(minLength: 40)
                }
                .padding(24)
            }
        }
    }

    private var severityLabel: String {
        switch pattern.severity {
        case .alert: return "ALERT"
        case .insight: return "INSIGHT"
        case .observation: return "OBSERVATION"
        }
    }

    private var severityColor: Color {
        switch pattern.severity {
        case .alert: return .red
        case .insight: return .yellow
        case .observation: return Color(white: 0.5)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
