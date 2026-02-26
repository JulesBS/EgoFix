import Foundation
import SwiftUI
import Combine

struct VersionGroup: Identifiable {
    let id = UUID()
    let version: String
    let entries: [VersionEntry]
}

enum HistoryViewType: String, CaseIterable {
    case stats = "Stats"
    case calendar = "Calendar"
    case changelog = "Log"
}

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var versionGroups: [VersionGroup] = []
    @Published var currentVersion: String = "1.0"
    @Published var isLoading = false
    @Published var selectedView: HistoryViewType = .stats
    @Published var streakData: StreakData = .empty
    @Published var userStats: UserStats = .empty
    @Published var calendarMonths: [CalendarMonth] = []

    private let versionService: VersionService
    private let versionEntryRepository: VersionEntryRepository
    private let userRepository: UserRepository
    private let statsService: StatsServiceProtocol

    init(
        versionService: VersionService,
        versionEntryRepository: VersionEntryRepository,
        userRepository: UserRepository,
        statsService: StatsServiceProtocol
    ) {
        self.versionService = versionService
        self.versionEntryRepository = versionEntryRepository
        self.userRepository = userRepository
        self.statsService = statsService
    }

    func loadHistory() async {
        isLoading = true

        await loadStats()

        do {
            currentVersion = try await versionService.getCurrentVersion()

            guard let user = try await userRepository.get() else {
                isLoading = false
                return
            }

            let entries = try await versionEntryRepository.getForUser(user.id)

            // Group by version
            let grouped = Dictionary(grouping: entries) { $0.version }
            let sortedVersions = grouped.keys.sorted { v1, v2 in
                compareVersions(v1, v2) > 0
            }

            versionGroups = sortedVersions.map { version in
                VersionGroup(
                    version: version,
                    entries: grouped[version] ?? []
                )
            }

        } catch {
            // Handle error silently
        }

        isLoading = false
    }

    func loadStats() async {
        guard let user = try? await userRepository.get() else { return }

        do {
            streakData = try await statsService.calculateStreak(for: user.id)
            userStats = try await statsService.calculateStats(for: user.id)
            calendarMonths = try await statsService.getCalendarActivity(for: user.id, months: 3)
        } catch {
            // Handle silently
        }
    }

    private func compareVersions(_ v1: String, _ v2: String) -> Int {
        let parsed1 = versionService.parseVersion(v1)
        let parsed2 = versionService.parseVersion(v2)

        if parsed1.major != parsed2.major {
            return parsed1.major - parsed2.major
        }
        return parsed1.minor - parsed2.minor
    }
}
