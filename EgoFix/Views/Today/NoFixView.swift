import SwiftUI

struct NoFixView: View {
    var onRetry: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NO_FIX_AVAILABLE")
                .font(EgoTheme.label())
                .tracking(1.5)
                .foregroundColor(EgoTheme.textMuted)

            Text("// Check back later or select a bug first")
                .font(EgoTheme.mono(.caption))
                .foregroundColor(EgoTheme.textMuted)

            if let onRetry {
                Button(action: onRetry) {
                    Text("[ RETRY ]")
                        .font(EgoTheme.mono(.caption))
                        .foregroundColor(EgoTheme.green)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Retry loading fix")
            }
        }
        .padding(.top, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No fix available. Check back later or select a bug first.")
    }
}
