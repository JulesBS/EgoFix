import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel

    init(viewModel: HistoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            EgoTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                tabSelector
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                Rectangle()
                    .fill(EgoTheme.borderSubtle)
                    .frame(height: 0.5)
                    .padding(.top, 12)

                if viewModel.isLoading {
                    Spacer()
                    TerminalLoading()
                    Spacer()
                } else {
                    switch viewModel.selectedView {
                    case .stats:
                        statsContent
                    case .calendar:
                        calendarContent
                    case .changelog:
                        changelogContent
                    }
                }
            }
        }
        .task {
            await viewModel.loadHistory()
        }
    }

    private var tabSelector: some View {
        TerminalTabSelector(tabs: HistoryViewType.allCases, selected: $viewModel.selectedView)
    }

    private var statsContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                StreakCardView(streakData: viewModel.streakData)
                StatsDashboardView(stats: viewModel.userStats)
            }
            .padding(24)
        }
    }

    private var calendarContent: some View {
        ActivityCalendarView(months: viewModel.calendarMonths)
    }

    private var changelogContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("CHANGELOG")
                            .font(EgoTheme.label())
                            .tracking(2)
                            .foregroundColor(EgoTheme.textPrimary)
                        Spacer()
                        Text("v\(viewModel.currentVersion)")
                            .font(.system(size: 28, weight: .light, design: .monospaced))
                            .foregroundColor(EgoTheme.green)
                            .greenGlow()
                    }
                    Text("// v1.0 \u{2192} v\(viewModel.currentVersion)")
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textMuted)
                }

                Rectangle()
                    .fill(EgoTheme.borderSubtle)
                    .frame(height: 0.5)

                ForEach(viewModel.versionGroups) { group in
                    VersionGroupView(group: group)
                }

                if viewModel.versionGroups.isEmpty {
                    Text("// Nothing here yet. That changes tomorrow.")
                        .font(EgoTheme.mono())
                        .foregroundColor(EgoTheme.textMuted)
                        .padding(.vertical, 24)
                }
            }
            .padding(24)
        }
    }
}

struct VersionGroupView: View {
    let group: VersionGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("v\(group.version)")
                .font(EgoTheme.mono(.headline))
                .foregroundColor(EgoTheme.textPrimary)

            ForEach(group.entries, id: \.id) { entry in
                HStack(alignment: .top, spacing: 8) {
                    Text(changeTypeSymbol(entry.changeType))
                        .foregroundColor(changeTypeColor(entry.changeType))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.entryDescription)
                            .font(EgoTheme.mono())
                            .foregroundColor(EgoTheme.textMuted)

                        Text(formatDate(entry.createdAt))
                            .font(EgoTheme.label())
                            .foregroundColor(EgoTheme.textMuted)
                    }
                }
            }
        }
    }

    private func changeTypeSymbol(_ type: VersionChangeType) -> String {
        switch type {
        case .majorUpdate: return "+"
        case .minorUpdate: return "·"
        case .crash: return "!"
        case .reboot: return "↻"
        }
    }

    private func changeTypeColor(_ type: VersionChangeType) -> Color {
        switch type {
        case .majorUpdate: return EgoTheme.green
        case .minorUpdate: return .blue
        case .crash: return .red
        case .reboot: return EgoTheme.amber
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}
