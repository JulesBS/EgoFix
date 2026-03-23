import SwiftUI

/// Figma SYSTEM_INIT style CTA button.
/// Uppercase tracked text, surface background, border, optional arrow.
struct FigmaCTAButton: View {
    let label: String
    var showArrow: Bool = true
    var color: Color = Color(red: 0.922, green: 1.0, blue: 0.886) // #EBFFE2
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text(label)
                    .font(EgoTheme.mono(.callout))
                    .tracking(2.8)
                    .foregroundColor(color)
                if showArrow {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(color)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 17)
            .background(EgoTheme.surface)
            .overlay(
                Rectangle()
                    .stroke(EgoTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Secondary action button — no background, just tracked text.
struct FigmaSecondaryButton: View {
    let label: String
    var color: Color = EgoTheme.textMuted
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(EgoTheme.mono(.callout))
                .tracking(1.4)
                .foregroundColor(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

/// Tracked status badge — uppercase pill with color.
struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(EgoTheme.label())
            .tracking(1.5)
            .foregroundColor(color)
    }
}
