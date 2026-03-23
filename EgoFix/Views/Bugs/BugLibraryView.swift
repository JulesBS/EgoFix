import SwiftUI

struct BugLibraryView: View {
    @StateObject private var viewModel: BugLibraryViewModel
    @State private var selectedBug: BugLifecycleInfo?

    init(viewModel: BugLibraryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                EgoTheme.bg.ignoresSafeArea()

                if viewModel.isLoading {
                    TerminalLoading()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            headerSection
                            statusSummary
                            Rectangle().fill(EgoTheme.borderSubtle).frame(height: 0.5)
                            bugList
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("BUG_LIBRARY")
                        .font(EgoTheme.label())
                        .tracking(2)
                        .foregroundColor(EgoTheme.green)
                        .greenGlow()
                }
            }
            .sheet(item: $selectedBug) { bug in
                BugDetailView(
                    bug: bug,
                    onActivate: { await viewModel.activateBug(bug.id) },
                    onDeactivate: { await viewModel.deactivateBug(bug.id) },
                    onResolve: { await viewModel.resolveBug(bug.id) },
                    onReactivate: { await viewModel.reactivateBug(bug.id) }
                )
            }
        }
        .task {
            await viewModel.loadBugs()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("// \(viewModel.activeBugCount) active, \(viewModel.bugs.count) identified")
                .font(EgoTheme.mono(.caption))
                .foregroundColor(EgoTheme.textMuted)
        }
    }

    private var statusSummary: some View {
        HStack(spacing: 16) {
            statusBadge(count: viewModel.activeBugCount, label: "ACTIVE", color: .red)
            statusBadge(count: viewModel.stableBugCount, label: "STABLE", color: .yellow)
            statusBadge(count: viewModel.resolvedBugCount, label: "RESOLVED", color: .green)
            Spacer()
        }
    }

    private func statusBadge(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(EgoTheme.mono(.title2))
                .foregroundColor(color)
            Text(label)
                .font(EgoTheme.label())
                .foregroundColor(EgoTheme.textMuted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(2)
    }

    private var bugList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.bugs, id: \.id) { bug in
                BugLibraryRowView(bug: bug)
                    .onTapGesture {
                        selectedBug = bug
                    }
            }
        }
    }
}

struct BugLibraryRowView: View {
    let bug: BugLifecycleInfo

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // ASCII art (compact)
            BugSoulView(slug: bug.slug, intensity: .present, size: .small)
                .frame(width: 70)

            // Bug info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    statusIndicator
                    Text(bug.title)
                        .font(EgoTheme.mono())
                        .foregroundColor(EgoTheme.textPrimary)
                }

                Text(bug.description)
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(EgoTheme.textMuted)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(bug.statusLabel)
                        .font(EgoTheme.label())
                        .foregroundColor(statusColor)

                    if let duration = bug.durationLabel {
                        Text(duration)
                            .font(EgoTheme.label())
                            .foregroundColor(EgoTheme.textMuted)
                    }
                }
            }

            Spacer()

            // Chevron
            Text(">")
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textMuted)
        }
        .padding()
        .background(EgoTheme.surface)
        .cornerRadius(2)
    }

    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
            .padding(.top, 6)
    }

    private var statusColor: Color {
        switch bug.status {
        case .identified: return EgoTheme.textMuted
        case .active: return .red
        case .stable: return EgoTheme.amber
        case .resolved: return EgoTheme.green
        }
    }
}
