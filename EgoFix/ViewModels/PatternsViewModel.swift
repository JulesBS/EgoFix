import Foundation
import SwiftUI
import Combine

@MainActor
final class PatternsViewModel: ObservableObject {
    @Published var patterns: [DetectedPattern] = []
    @Published var isLoading = false
    @Published var selectedPattern: DetectedPattern?
    @Published var selectedPatternTrendData: [TrendDataPoint] = []
    @Published var showingPatternDetail = false

    private let patternRepository: PatternRepository
    private let userRepository: UserRepository
    private let trendAnalysisService: TrendAnalysisServiceProtocol?

    init(
        patternRepository: PatternRepository,
        userRepository: UserRepository,
        trendAnalysisService: TrendAnalysisServiceProtocol? = nil
    ) {
        self.patternRepository = patternRepository
        self.userRepository = userRepository
        self.trendAnalysisService = trendAnalysisService
    }

    func loadPatterns() async {
        isLoading = true

        do {
            guard let user = try await userRepository.get() else {
                isLoading = false
                return
            }

            let allPatterns = try await patternRepository.getForUser(user.id)

            // Sort by severity and date
            patterns = allPatterns.sorted { p1, p2 in
                if severityOrder(p1.severity) != severityOrder(p2.severity) {
                    return severityOrder(p1.severity) > severityOrder(p2.severity)
                }
                return p1.detectedAt > p2.detectedAt
            }
        } catch {
            patterns = []
        }

        isLoading = false
    }

    private func severityOrder(_ severity: PatternSeverity) -> Int {
        switch severity {
        case .alert: return 3
        case .insight: return 2
        case .observation: return 1
        }
    }

    func selectPattern(_ pattern: DetectedPattern) {
        selectedPattern = pattern
        showingPatternDetail = true

        // Load trend data for related bugs
        Task {
            await loadTrendData(for: pattern)
        }
    }

    func dismissPatternDetail() {
        showingPatternDetail = false
        selectedPattern = nil
        selectedPatternTrendData = []
    }

    private func loadTrendData(for pattern: DetectedPattern) async {
        guard let service = trendAnalysisService,
              let bugId = pattern.relatedBugIds.first,
              let user = try? await userRepository.get() else {
            return
        }

        do {
            selectedPatternTrendData = try await service.getBugIntensityTrend(
                bugId: bugId,
                userId: user.id,
                weeks: 8
            )
        } catch {
            selectedPatternTrendData = []
        }
    }
}
