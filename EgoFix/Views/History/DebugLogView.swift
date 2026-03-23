import SwiftUI
import SwiftData

/// Debug Log: collectible education entries from completed fixes.
/// Each fix completion saves its education teaser + deep dive.
/// Grouped by bug, newest first.
struct DebugLogView: View {
    @Query(
        filter: #Predicate<FixCompletion> {
            $0.educationTeaser != nil && $0.deletedAt == nil
        },
        sort: \FixCompletion.completedAt,
        order: .reverse
    ) private var completions: [FixCompletion]

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            EgoTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack {
                        Text("DEBUG LOG")
                            .font(EgoTheme.label())
                            .tracking(2)
                            .foregroundColor(EgoTheme.textMuted)

                        Spacer()

                        Text("\(completions.count) entries")
                            .font(EgoTheme.mono(.caption2))
                            .foregroundColor(EgoTheme.textMuted)
                    }
                    .padding(.bottom, 16)

                    if completions.isEmpty {
                        emptyState
                    } else {
                        // Group by bug
                        ForEach(groupedByBug, id: \.slug) { group in
                            bugSection(group)
                        }
                    }
                }
                .padding(24)
            }
        }
        .terminalBackButton()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("// No entries yet.")
                .font(EgoTheme.mono(.caption))
                .foregroundColor(EgoTheme.textMuted)
                .italic()

            Text("// Complete a fix to start logging.")
                .font(EgoTheme.mono(.caption))
                .foregroundColor(EgoTheme.textMuted)
                .italic()
        }
        .padding(.top, 32)
    }

    // MARK: - Bug Section

    @ViewBuilder
    private func bugSection(_ group: BugGroup) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Bug header
            HStack {
                Text(group.slug)
                    .font(EgoTheme.mono(.callout))
                    .foregroundColor(EgoTheme.textPrimary)

                Spacer()

                Text("\(group.entries.count) logs")
                    .font(EgoTheme.mono(.caption2))
                    .foregroundColor(EgoTheme.textMuted)
            }
            .padding(.bottom, 12)

            // Entries
            ForEach(group.entries, id: \.id) { completion in
                DebugLogEntryView(completion: completion)
                    .padding(.bottom, 12)
            }
        }
        .padding(.bottom, 16)
    }

    // MARK: - Grouping

    private struct BugGroup {
        let slug: String
        let entries: [FixCompletion]
    }

    private var groupedByBug: [BugGroup] {
        // Build fixId → bugSlug lookup
        let fixDescriptor = FetchDescriptor<Fix>()
        let fixes = (try? modelContext.fetch(fixDescriptor)) ?? []

        let bugDescriptor = FetchDescriptor<Bug>()
        let bugs = (try? modelContext.fetch(bugDescriptor)) ?? []
        let bugIdToSlug = Dictionary(uniqueKeysWithValues: bugs.map { ($0.id, $0.slug) })

        var fixToBug: [UUID: String] = [:]
        for fix in fixes {
            fixToBug[fix.id] = bugIdToSlug[fix.bugId] ?? "unknown"
        }

        // Group completions by bug slug
        var groups: [String: [FixCompletion]] = [:]
        for completion in completions {
            let slug = fixToBug[completion.fixId] ?? "unknown"
            groups[slug, default: []].append(completion)
        }

        return groups
            .map { BugGroup(slug: $0.key, entries: $0.value) }
            .sorted { $0.entries.count > $1.entries.count }
    }
}

// MARK: - Entry View

struct DebugLogEntryView: View {
    let completion: FixCompletion
    @State private var showDeepDive = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Meta line: fix number + outcome + date
            HStack(spacing: 8) {
                Text("#\(stableFixNumber(completion.fixId))")
                    .font(EgoTheme.mono(.caption2))
                    .foregroundColor(EgoTheme.textMuted)

                Text(outcomeSymbol)
                    .font(EgoTheme.mono(.caption2))
                    .foregroundColor(outcomeColor)

                Text(outcomeLabel)
                    .font(EgoTheme.mono(.caption2))
                    .foregroundColor(outcomeColor)

                Spacer()

                if let date = completion.completedAt {
                    Text(formatDate(date))
                        .font(EgoTheme.mono(.caption2))
                        .foregroundColor(EgoTheme.textMuted)
                }
            }

            // Teaser
            if let teaser = completion.educationTeaser {
                Text(teaser)
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(EgoTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
            }

            // Deep dive toggle
            if let deepDive = completion.educationDeepDive, !deepDive.isEmpty {
                Button(action: {
                    withAnimation(.easeOut(duration: 0.25)) {
                        showDeepDive.toggle()
                    }
                }) {
                    Text(showDeepDive ? "[ collapse ]" : "[ read more ]")
                        .font(EgoTheme.mono(.caption2))
                        .foregroundColor(EgoTheme.green.opacity(0.7))
                }
                .buttonStyle(.plain)

                if showDeepDive {
                    Text(deepDive)
                        .font(EgoTheme.mono(.caption2))
                        .foregroundColor(EgoTheme.textMuted.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(12)
        .glassCard()
    }

    private var outcomeSymbol: String {
        switch completion.outcome {
        case .applied: return "+"
        case .skipped: return "~"
        case .failed: return "x"
        case .pending: return "·"
        }
    }

    private var outcomeColor: Color {
        switch completion.outcome {
        case .applied: return EgoTheme.green
        case .skipped: return EgoTheme.amber
        case .failed: return .red
        case .pending: return EgoTheme.textMuted
        }
    }

    private var outcomeLabel: String {
        switch completion.outcome {
        case .applied: return "applied"
        case .skipped: return "didn't try"
        case .failed: return "tried, couldn't"
        case .pending: return "pending"
        }
    }

    private func stableFixNumber(_ uuid: UUID) -> String {
        let hex = uuid.uuidString.replacingOccurrences(of: "-", with: "").prefix(4)
        let value = UInt32(hex, radix: 16) ?? 0
        return String(format: "%04d", value % 10000)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
