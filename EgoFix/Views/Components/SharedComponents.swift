import SwiftUI
import Combine

// MARK: - Tab Selector

/// Shared horizontal tab selector used in History, Patterns, and similar views.
/// Tracked uppercase labels, green selected state with border.
struct TerminalTabSelector<T: Hashable & RawRepresentable>: View where T.RawValue == String {
    let tabs: [T]
    @Binding var selected: T

    var body: some View {
        HStack(spacing: EgoTheme.spacingSmall) {
            ForEach(tabs, id: \.self) { tab in
                let isSelected = selected == tab
                Button(action: { selected = tab }) {
                    Text(tab.rawValue.uppercased())
                        .font(EgoTheme.label())
                        .tracking(1.5)
                        .foregroundColor(isSelected ? EgoTheme.green : EgoTheme.textMuted)
                        .padding(.horizontal, EgoTheme.spacingMedium)
                        .padding(.vertical, EgoTheme.spacingSmall)
                        .background(isSelected ? EgoTheme.green.opacity(0.1) : Color.clear)
                        .overlay(
                            Rectangle()
                                .stroke(isSelected ? EgoTheme.green.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                }
            }
            Spacer()
        }
    }
}

// MARK: - Empty State

/// Shared empty state with terminal comment style.
struct TerminalEmptyState: View {
    let message: String
    var secondary: String? = nil

    var body: some View {
        VStack(spacing: EgoTheme.spacingSmall) {
            Spacer()
            Text("// \(message)")
                .font(EgoTheme.mono())
                .foregroundColor(EgoTheme.textMuted)
                .multilineTextAlignment(.center)

            if let secondary {
                Text("// \(secondary)")
                    .font(EgoTheme.mono(.caption))
                    .foregroundColor(EgoTheme.textMuted)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(EgoTheme.spacingLarge)
    }
}

// MARK: - Loading Indicator

/// Shared loading state with terminal cursor animation.
struct TerminalLoading: View {
    @State private var dotCount = 0
    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            Spacer()
            Text("> loading" + String(repeating: ".", count: dotCount))
                .font(EgoTheme.mono(.caption))
                .foregroundColor(EgoTheme.textMuted)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 4
        }
    }
}

// MARK: - Section Header

/// Tracked uppercase section header label.
struct TerminalSectionHeader: View {
    let title: String
    var color: Color = EgoTheme.textMuted

    var body: some View {
        Text(title)
            .font(EgoTheme.label())
            .tracking(1.5)
            .foregroundColor(color)
    }
}

// MARK: - Divider

/// Themed 0.5pt divider using EgoTheme.borderSubtle.
struct TerminalDivider: View {
    var body: some View {
        Rectangle()
            .fill(EgoTheme.borderSubtle)
            .frame(height: 0.5)
    }
}

// MARK: - Interaction Components

/// Header row for interaction views: type label (left) + status (right).
struct InteractionHeader: View {
    let type: String
    let status: String
    var typeColor: Color = EgoTheme.green

    var body: some View {
        HStack {
            Text(type)
                .font(EgoTheme.label())
                .foregroundColor(typeColor)
            Spacer()
            Text(status)
                .font(EgoTheme.label())
                .foregroundColor(EgoTheme.textMuted)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(type) interaction, status: \(status)")
    }
}

/// Inline comment display for fixes.
struct InlineCommentView: View {
    let comment: String?

    var body: some View {
        if let comment {
            Text("// \(comment)")
                .font(EgoTheme.mono(.caption))
                .foregroundColor(EgoTheme.textMuted)
                .italic()
        }
    }
}

/// Card shell modifier for interaction views.
extension View {
    func interactionCard(borderColor: Color = EgoTheme.border) -> some View {
        self
            .padding(16)
            .background(EgoTheme.surface.opacity(0.3))
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(borderColor, lineWidth: 1)
                    .accessibilityHidden(true)
            )
    }
}
