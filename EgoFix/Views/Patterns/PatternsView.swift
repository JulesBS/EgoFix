import SwiftUI

struct PatternsView: View {
    @StateObject private var viewModel: PatternsViewModel

    init(viewModel: PatternsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .tint(.green)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("DETECTED PATTERNS")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        if viewModel.patterns.isEmpty {
                            VStack(spacing: 8) {
                                Text("// No patterns detected yet")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.gray.opacity(0.6))

                                Text("// Keep logging data")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.gray.opacity(0.4))
                            }
                            .padding()
                        } else {
                            ForEach(viewModel.patterns, id: \.id) { pattern in
                                PatternCardView(pattern: pattern)
                                    .onTapGesture {
                                        viewModel.selectPattern(pattern)
                                    }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .task {
            await viewModel.loadPatterns()
        }
        .sheet(isPresented: $viewModel.showingPatternDetail) {
            if let pattern = viewModel.selectedPattern {
                PatternDetailView(
                    pattern: pattern,
                    trendDataPoints: viewModel.selectedPatternTrendData,
                    onDismiss: { viewModel.dismissPatternDetail() }
                )
            }
        }
    }
}

struct PatternCardView: View {
    let pattern: DetectedPattern

    private var recommendationCount: Int {
        RecommendationEngine.generateRecommendations(for: pattern).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                    .foregroundColor(.gray.opacity(0.5))
            }

            Text(pattern.title)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white)

            Text(pattern.body)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.gray)
                .lineLimit(2)

            HStack {
                if pattern.viewedAt != nil {
                    Text("// Viewed")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.4))
                }

                Spacer()

                Text("→ \(recommendationCount) recommendations")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.green.opacity(0.7))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(4)
        .padding(.horizontal)
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
        case .observation: return .gray
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}
