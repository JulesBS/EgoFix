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
            EgoTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with close button
                    HStack {
                        Spacer()
                        Button(action: onDismiss) {
                            Text("[ x ]")
                                .font(EgoTheme.mono(.caption))
                                .foregroundColor(EgoTheme.textMuted)
                        }
                        .accessibilityLabel("Close")
                        .accessibilityHint("Dismiss pattern detail")
                    }

                    // Severity badge and date
                    HStack {
                        Text(severityLabel)
                            .font(EgoTheme.mono(.caption))
                            .foregroundColor(severityColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(severityColor.opacity(0.1))
                            .cornerRadius(2)

                        Spacer()

                        Text(formatDate(pattern.detectedAt))
                            .font(EgoTheme.mono(.caption))
                            .foregroundColor(EgoTheme.textMuted)
                    }

                    // Title
                    Text(pattern.title)
                        .font(EgoTheme.mono(.title3))
                        .foregroundColor(EgoTheme.textPrimary)

                    // Body
                    Text(pattern.body)
                        .font(EgoTheme.mono())
                        .foregroundColor(EgoTheme.textPrimary)
                        .lineSpacing(4)

                    // Data points info
                    Text("// Based on \(pattern.dataPoints) data points")
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textMuted)

                    // Trend chart (if data available)
                    if !trendDataPoints.isEmpty {
                        Divider()
                            .background(EgoTheme.borderSubtle)
                            .padding(.vertical, 8)
                            .accessibilityHidden(true)

                        TrendChartView(
                            title: "Bug Intensity",
                            dataPoints: trendDataPoints,
                            trendDirection: trendDirection
                        )
                    }

                    TerminalDivider()
                        .padding(.vertical, 8)
                        .accessibilityHidden(true)

                    // Recommendations section
                    Text("RECOMMENDATIONS")
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textMuted)

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
        case .insight: return EgoTheme.amber
        case .observation: return EgoTheme.textMuted
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
