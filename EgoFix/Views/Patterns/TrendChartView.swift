import SwiftUI

struct TrendChartView: View {
    let title: String
    let dataPoints: [TrendDataPoint]
    let trendDirection: TrendDirection

    private let chartHeight: CGFloat = 100
    private let yAxisLabels = ["loud", "present", "quiet"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(title.uppercased())
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(Color(white: 0.4))

            HStack(alignment: .top, spacing: 8) {
                // Y-axis labels
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(yAxisLabels, id: \.self) { label in
                        Text(label)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(Color(white: 0.35))
                            .frame(height: chartHeight / 3)
                    }
                }
                .frame(width: 50)

                // Chart area
                GeometryReader { geometry in
                    ZStack(alignment: .bottomLeading) {
                        // Grid lines
                        VStack(spacing: 0) {
                            ForEach(0..<3, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color(white: 0.15))
                                    .frame(height: 1)
                                Spacer()
                            }
                        }

                        // Data points and lines
                        if !dataPoints.isEmpty {
                            chartContent(in: geometry)
                        }
                    }
                }
                .frame(height: chartHeight)
            }

            // X-axis labels (week numbers)
            HStack(spacing: 0) {
                Spacer()
                    .frame(width: 58)
                ForEach(Array(dataPoints.enumerated()), id: \.offset) { index, _ in
                    Text("W\(index + 1)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(Color(white: 0.3))
                        .frame(maxWidth: .infinity)
                }
            }

            // Trend direction
            HStack {
                Text("// Trending:")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Color(white: 0.35))
                Text(trendDirection.label)
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundColor(trendDirectionColor)
            }
        }
        .padding()
        .background(Color(white: 0.04))
        .cornerRadius(4)
    }

    @ViewBuilder
    private func chartContent(in geometry: GeometryProxy) -> some View {
        let width = geometry.size.width
        let height = geometry.size.height
        let pointSpacing = width / CGFloat(max(dataPoints.count - 1, 1))

        // Draw connecting lines
        Path { path in
            for (index, point) in dataPoints.enumerated() {
                let x = CGFloat(index) * pointSpacing
                let y = height - (CGFloat(point.value) / 2.0 * height)

                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
        .stroke(Color.green.opacity(0.5), lineWidth: 1)

        // Draw data points
        ForEach(Array(dataPoints.enumerated()), id: \.offset) { index, point in
            let x = CGFloat(index) * pointSpacing
            let y = height - (CGFloat(point.value) / 2.0 * height)

            Circle()
                .fill(Color.green)
                .frame(width: 6, height: 6)
                .position(x: x, y: y)
        }
    }

    private var trendDirectionColor: Color {
        switch trendDirection {
        case .improving: return .green
        case .worsening: return .red
        case .stable: return .yellow
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        TrendChartView(
            title: "need-to-be-right",
            dataPoints: [
                TrendDataPoint(value: 2, label: "W1"),
                TrendDataPoint(value: 2, label: "W2"),
                TrendDataPoint(value: 1, label: "W3"),
                TrendDataPoint(value: 1, label: "W4"),
                TrendDataPoint(value: 1, label: "W5"),
                TrendDataPoint(value: 0, label: "W6"),
            ],
            trendDirection: .improving
        )
        .padding()
    }
}
