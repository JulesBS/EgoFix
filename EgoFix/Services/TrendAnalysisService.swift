import Foundation

protocol TrendAnalysisServiceProtocol {
    func getBugIntensityTrend(bugId: UUID, userId: UUID, weeks: Int) async throws -> [TrendDataPoint]
    func getTrendDirection(for points: [TrendDataPoint]) -> TrendDirection
}

final class TrendAnalysisService: TrendAnalysisServiceProtocol {
    private let weeklyDiagnosticRepository: WeeklyDiagnosticRepository
    private let bugRepository: BugRepository

    init(
        weeklyDiagnosticRepository: WeeklyDiagnosticRepository,
        bugRepository: BugRepository
    ) {
        self.weeklyDiagnosticRepository = weeklyDiagnosticRepository
        self.bugRepository = bugRepository
    }

    func getBugIntensityTrend(bugId: UUID, userId: UUID, weeks: Int) async throws -> [TrendDataPoint] {
        let diagnostics = try await weeklyDiagnosticRepository.getForUser(userId)

        // Extract bug-specific data from diagnostic responses
        var dataPoints: [TrendDataPoint] = []

        let sortedDiagnostics = diagnostics.sorted { $0.weekStarting < $1.weekStarting }

        for diagnostic in sortedDiagnostics.suffix(weeks) {
            // Find the response for this specific bug
            if let response = diagnostic.responses.first(where: { $0.bugId == bugId }) {
                let value: Double
                switch response.intensity {
                case .quiet: value = 0
                case .present: value = 1
                case .loud: value = 2
                }

                dataPoints.append(TrendDataPoint(
                    id: diagnostic.weekStarting,
                    value: value,
                    label: weekLabel(for: diagnostic.weekStarting)
                ))
            }
        }

        return dataPoints
    }

    func getTrendDirection(for points: [TrendDataPoint]) -> TrendDirection {
        BugTrendData.calculateDirection(from: points)
    }

    private func weekLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}
