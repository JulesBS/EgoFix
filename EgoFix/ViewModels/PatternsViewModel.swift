import Foundation
import SwiftUI
import Combine

enum PatternSeverityFilter: String, CaseIterable {
    case all = "ALL"
    case alert = "ALERTS"
    case insight = "INSIGHTS"
    case observation = "OBSERVATIONS"
}

struct PatternBugSummary: Identifiable {
    let id: UUID
    let bugId: UUID
    let bugTitle: String
    let patternCount: Int
}

@MainActor
final class PatternsViewModel: ObservableObject {
    @Published var patterns: [DetectedPattern] = []
    @Published var allPatterns: [DetectedPattern] = []
    @Published var isLoading = false
    @Published var selectedPattern: DetectedPattern?
    @Published var selectedPatternTrendData: [TrendDataPoint] = []
    @Published var showingPatternDetail = false

    @Published var severityFilter: PatternSeverityFilter = .all
    @Published var selectedBugId: UUID?
    @Published var bugSummaries: [PatternBugSummary] = []
    @Published var bugNames: [UUID: String] = [:]

    private let patternRepository: PatternRepository
    private let userRepository: UserRepository
    private let bugRepository: BugRepository?
    private let trendAnalysisService: TrendAnalysisServiceProtocol?

    init(
        patternRepository: PatternRepository,
        userRepository: UserRepository,
        bugRepository: BugRepository? = nil,
        trendAnalysisService: TrendAnalysisServiceProtocol? = nil
    ) {
        self.patternRepository = patternRepository
        self.userRepository = userRepository
        self.bugRepository = bugRepository
        self.trendAnalysisService = trendAnalysisService
    }

    func loadPatterns() async {
        isLoading = true

        do {
            guard let user = try await userRepository.get() else {
                isLoading = false
                return
            }

            // Load bug names for display
            if let bugRepo = bugRepository {
                let bugs = try await bugRepo.getAll()
                bugNames = Dictionary(uniqueKeysWithValues: bugs.map { ($0.id, $0.title) })
            }

            let loadedPatterns = try await patternRepository.getForUser(user.id)

            // Sort by severity and date
            allPatterns = loadedPatterns.sorted { p1, p2 in
                if severityOrder(p1.severity) != severityOrder(p2.severity) {
                    return severityOrder(p1.severity) > severityOrder(p2.severity)
                }
                return p1.detectedAt > p2.detectedAt
            }

            // Build bug summaries
            buildBugSummaries()

            // Apply filters
            applyFilters()
        } catch {
            allPatterns = []
            patterns = []
        }

        isLoading = false
    }

    func setSeverityFilter(_ filter: PatternSeverityFilter) {
        severityFilter = filter
        applyFilters()
    }

    func setBugFilter(_ bugId: UUID?) {
        selectedBugId = bugId
        applyFilters()
    }

    private func applyFilters() {
        var filtered = allPatterns

        // Apply severity filter
        switch severityFilter {
        case .all:
            break
        case .alert:
            filtered = filtered.filter { $0.severity == .alert }
        case .insight:
            filtered = filtered.filter { $0.severity == .insight }
        case .observation:
            filtered = filtered.filter { $0.severity == .observation }
        }

        // Apply bug filter
        if let bugId = selectedBugId {
            filtered = filtered.filter { $0.relatedBugIds.contains(bugId) }
        }

        patterns = filtered
    }

    private func buildBugSummaries() {
        var bugPatternCounts: [UUID: Int] = [:]

        for pattern in allPatterns {
            for bugId in pattern.relatedBugIds {
                bugPatternCounts[bugId, default: 0] += 1
            }
        }

        bugSummaries = bugPatternCounts.compactMap { (bugId, count) in
            guard let title = bugNames[bugId] else { return nil }
            return PatternBugSummary(id: bugId, bugId: bugId, bugTitle: title, patternCount: count)
        }.sorted { $0.patternCount > $1.patternCount }
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
