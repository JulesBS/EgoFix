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
                    VStack(alignment: .leading, spacing: 16) {
                        headerSection

                        if !viewModel.bugSummaries.isEmpty {
                            bugSummarySection
                        }

                        filterSection

                        if viewModel.patterns.isEmpty {
                            emptyState
                        } else {
                            patternsListSection
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

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DETECTED PATTERNS")
                .font(.system(.headline, design: .monospaced))
                .foregroundColor(.white)

            Text("// \(viewModel.allPatterns.count) total")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(.horizontal)
    }

    private var bugSummarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("BY BUG")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.gray.opacity(0.6))
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // "All" option
                    bugFilterButton(title: "All", count: viewModel.allPatterns.count, isSelected: viewModel.selectedBugId == nil) {
                        viewModel.setBugFilter(nil)
                    }

                    ForEach(viewModel.bugSummaries) { summary in
                        bugFilterButton(title: summary.bugTitle, count: summary.patternCount, isSelected: viewModel.selectedBugId == summary.bugId) {
                            viewModel.setBugFilter(summary.bugId)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func bugFilterButton(title: String, count: Int, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .lineLimit(1)
                Text("(\(count))")
                    .foregroundColor(.gray)
            }
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(isSelected ? .green : .white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.green.opacity(0.15) : Color.gray.opacity(0.1))
            .cornerRadius(2)
        }
    }

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PatternSeverityFilter.allCases, id: \.self) { filter in
                    Button(action: { viewModel.setSeverityFilter(filter) }) {
                        Text(filter.rawValue)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(viewModel.severityFilter == filter ? .green : .white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(viewModel.severityFilter == filter ? Color.green.opacity(0.15) : Color.gray.opacity(0.1))
                            .cornerRadius(2)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("// No patterns yet")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.gray.opacity(0.6))

            Text("// They emerge from data")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.gray.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var patternsListSection: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.patterns, id: \.id) { pattern in
                PatternCardView(pattern: pattern)
                    .onTapGesture {
                        viewModel.selectPattern(pattern)
                    }
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

                statusBadge

                Spacer()

                Text(relativeTime(pattern.detectedAt))
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
                Spacer()

                Text("-> \(recommendationCount) recommendations")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.green.opacity(0.7))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(4)
        .padding(.horizontal)
    }

    @ViewBuilder
    private var statusBadge: some View {
        if pattern.dismissedAt != nil {
            Text("DISMISSED")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.gray.opacity(0.5))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(2)
        } else if pattern.viewedAt != nil {
            Text("NOTED")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.green.opacity(0.6))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.1))
                .cornerRadius(2)
        } else {
            Text("UNREAD")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.yellow.opacity(0.7))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(2)
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
        case .observation: return .gray
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
