import SwiftUI

struct NoFixView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NO_FIX_AVAILABLE")
                .font(EgoTheme.label())
                .tracking(1.5)
                .foregroundColor(EgoTheme.textMuted)

            Text("// Check back later or select a bug first")
                .font(EgoTheme.mono(.caption))
                .foregroundColor(EgoTheme.textMuted)
        }
        .padding(.top, 16)
    }
}
