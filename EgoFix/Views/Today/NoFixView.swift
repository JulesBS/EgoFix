import SwiftUI

struct NoFixView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("NO FIX AVAILABLE")
                .font(.system(.title2, design: .monospaced))
                .foregroundColor(.gray)

            Text("// Check back later or select a bug first")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.gray.opacity(0.6))
        }
        .padding()
    }
}
