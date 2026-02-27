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
                Color.black.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView().tint(.green)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            headerSection
                            statusSummary
                            Divider().background(Color(white: 0.2))
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
                    Text("BUG LIBRARY")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(.white)
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
            Text("// All known ego patterns")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.gray.opacity(0.6))
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
                .font(.system(.title2, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.gray)
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
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white)
                }

                Text(bug.description)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.gray)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(bug.statusLabel)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(statusColor)

                    if let duration = bug.durationLabel {
                        Text(duration)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
            }

            Spacer()

            // Chevron
            Text(">")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.gray.opacity(0.4))
        }
        .padding()
        .background(Color(white: 0.08))
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
        case .identified: return .gray
        case .active: return .red
        case .stable: return .yellow
        case .resolved: return .green
        }
    }
}
