import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel

    init(viewModel: HistoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Tab selector
                tabSelector
                    .padding(.horizontal)
                    .padding(.top, 8)

                Divider()
                    .background(Color(white: 0.2))
                    .padding(.top, 12)

                // Content based on selected tab
                if viewModel.isLoading {
                    Spacer()
                    ProgressView().tint(.green)
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

    // Tab selector - horizontal buttons
    private var tabSelector: some View {
        HStack(spacing: 8) {
            ForEach(HistoryViewType.allCases, id: \.self) { viewType in
                Button(action: { viewModel.selectedView = viewType }) {
                    Text("[ \(viewType.rawValue) ]")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(viewModel.selectedView == viewType ? .green : Color(white: 0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(viewModel.selectedView == viewType ? Color.green.opacity(0.1) : Color.clear)
                        .cornerRadius(2)
                }
            }
            Spacer()
        }
    }

    // Stats view content
    private var statsContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                StreakCardView(streakData: viewModel.streakData)
                StatsDashboardView(stats: viewModel.userStats)
            }
            .padding()
        }
    }

    // Calendar content
    private var calendarContent: some View {
        ActivityCalendarView(months: viewModel.calendarMonths)
    }

    // Changelog content - existing version history
    private var changelogContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Current version header
                HStack {
                    Text("CURRENT VERSION")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("v\(viewModel.currentVersion)")
                        .font(.system(.title, design: .monospaced))
                        .foregroundColor(.green)
                }
                .padding(.horizontal)

                Divider()
                    .background(Color.gray.opacity(0.3))

                // Version history
                ForEach(viewModel.versionGroups) { group in
                    VersionGroupView(group: group)
                }

                if viewModel.versionGroups.isEmpty {
                    Text("// No changelog entries yet")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.6))
                        .padding()
                }
            }
            .padding(.vertical)
        }
    }
}

struct VersionGroupView: View {
    let group: VersionGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("v\(group.version)")
                .font(.system(.headline, design: .monospaced))
                .foregroundColor(.white)

            ForEach(group.entries, id: \.id) { entry in
                HStack(alignment: .top, spacing: 8) {
                    Text(changeTypeSymbol(entry.changeType))
                        .foregroundColor(changeTypeColor(entry.changeType))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.entryDescription)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.gray)

                        Text(formatDate(entry.createdAt))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
            }
        }
        .padding(.horizontal)
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
        case .majorUpdate: return .green
        case .minorUpdate: return .blue
        case .crash: return .red
        case .reboot: return .yellow
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}
