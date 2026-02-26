import SwiftUI

struct BugDetailView: View {
    let bug: BugLifecycleInfo
    let onActivate: () async -> Void
    let onDeactivate: () async -> Void
    let onResolve: () async -> Void
    let onReactivate: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isPerformingAction = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    Divider().background(Color(white: 0.2))
                    statusSection
                    Divider().background(Color(white: 0.2))
                    descriptionSection
                    Divider().background(Color(white: 0.2))
                    timelineSection
                    Divider().background(Color(white: 0.2))
                    actionsSection
                }
                .padding()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                statusIndicator
                Text(bug.statusLabel)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(statusColor)
                Spacer()
                Button(action: { dismiss() }) {
                    Text("[ x ]")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)
                }
            }

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bug.title)
                        .font(.system(.title2, design: .monospaced))
                        .foregroundColor(.white)

                    Text("// \(bug.slug)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.6))
                }

                Spacer()

                BugASCIIArtView(slug: bug.slug)
            }
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("STATUS")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.gray)

            Text(bug.statusComment)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.gray.opacity(0.8))

            if let duration = bug.durationLabel {
                Text(duration)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(statusColor.opacity(0.8))
            }
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PATTERN")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.gray)

            Text(bug.description)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LIFECYCLE")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.gray)

            VStack(alignment: .leading, spacing: 8) {
                if let activatedAt = bug.activatedAt {
                    timelineEntry(label: "Activated", date: activatedAt, color: .red)
                }

                if let stableAt = bug.stableAt {
                    timelineEntry(label: "Marked stable", date: stableAt, color: .yellow)
                }

                if let resolvedAt = bug.resolvedAt {
                    timelineEntry(label: "Resolved", date: resolvedAt, color: .green)
                }

                if bug.activatedAt == nil && bug.stableAt == nil && bug.resolvedAt == nil {
                    Text("// No lifecycle events yet")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
        }
    }

    private func timelineEntry(label: String, date: Date, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text(label)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            Text(formatDate(date))
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.gray)
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACTIONS")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                switch bug.status {
                case .identified:
                    actionButton(
                        label: "[ ACTIVATE ]",
                        comment: "// Start tracking this bug",
                        color: .red,
                        action: onActivate
                    )

                case .active:
                    actionButton(
                        label: "[ DEACTIVATE ]",
                        comment: "// Stop tracking (returns to identified)",
                        color: .gray,
                        action: onDeactivate
                    )
                    // Note: Active -> Stable is automatic via lifecycle checks

                case .stable:
                    actionButton(
                        label: "[ RESOLVE ]",
                        comment: "// Mark as resolved",
                        color: .green,
                        action: onResolve
                    )
                    actionButton(
                        label: "[ DEACTIVATE ]",
                        comment: "// Return to identified",
                        color: .gray,
                        action: onDeactivate
                    )

                case .resolved:
                    actionButton(
                        label: "[ REACTIVATE ]",
                        comment: "// Return to active tracking",
                        color: .red,
                        action: onReactivate
                    )
                }
            }
        }
    }

    private func actionButton(
        label: String,
        comment: String,
        color: Color,
        action: @escaping () async -> Void
    ) -> some View {
        Button(action: {
            Task {
                isPerformingAction = true
                await action()
                isPerformingAction = false
                dismiss()
            }
        }) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(isPerformingAction ? .gray : color)

                Text(comment)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(2)
        }
        .disabled(isPerformingAction)
    }

    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 10, height: 10)
    }

    private var statusColor: Color {
        switch bug.status {
        case .identified: return .gray
        case .active: return .red
        case .stable: return .yellow
        case .resolved: return .green
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

extension BugLifecycleInfo: Identifiable {}
