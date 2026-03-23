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
            EgoTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    Rectangle().fill(EgoTheme.borderSubtle).frame(height: 0.5)
                    statusSection
                    Rectangle().fill(EgoTheme.borderSubtle).frame(height: 0.5)
                    descriptionSection
                    Rectangle().fill(EgoTheme.borderSubtle).frame(height: 0.5)
                    timelineSection
                    Rectangle().fill(EgoTheme.borderSubtle).frame(height: 0.5)
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
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(statusColor)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(EgoTheme.textMuted)
                }
            }

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bug.title)
                        .font(EgoTheme.mono(.title2))
                        .foregroundColor(EgoTheme.textPrimary)

                    Text("// \(bug.slug)")
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textMuted)
                }

                Spacer()

                BugSoulView(slug: bug.slug, intensity: .present, size: .medium)
            }
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("STATUS")
                .font(EgoTheme.mono(.caption))
                .foregroundColor(EgoTheme.textMuted)

            Text(bug.statusComment)
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textMuted)

            if let duration = bug.durationLabel {
                Text(duration)
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(statusColor.opacity(0.8))
            }
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PATTERN")
                .font(EgoTheme.mono(.caption))
                .foregroundColor(EgoTheme.textMuted)

            Text(bug.description)
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textPrimary)
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LIFECYCLE")
                .font(EgoTheme.mono(.caption))
                .foregroundColor(EgoTheme.textMuted)

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
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.textMuted)
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
                .font(EgoTheme.mono(.caption))
                .foregroundColor(EgoTheme.textPrimary)

            Spacer()

            Text(formatDate(date))
                .font(EgoTheme.mono(.caption))
                .foregroundColor(EgoTheme.textMuted)
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACTIONS")
                .font(EgoTheme.mono(.caption))
                .foregroundColor(EgoTheme.textMuted)

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
                    .font(EgoTheme.mono())
                    .foregroundColor(isPerformingAction ? .gray : color)

                Text(comment)
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(EgoTheme.textMuted)
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
        case .identified: return EgoTheme.textMuted
        case .active: return .red
        case .stable: return EgoTheme.amber
        case .resolved: return EgoTheme.green
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

extension BugLifecycleInfo: Identifiable {}
