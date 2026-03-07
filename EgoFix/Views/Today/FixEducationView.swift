import SwiftUI

/// Shown after fix acceptance, before going into the day.
/// Surfaces the WHY behind the pattern — primes the user to notice it.
struct FixEducationView: View {
    let fix: Fix
    let bugTitle: String?
    let educationBody: String
    let onContinue: () -> Void

    @State private var showBody = false
    @State private var showButton = false

    var body: some View {
        VStack(spacing: 24) {
            Text("FIX ACCEPTED")
                .font(.system(.headline, design: .monospaced))
                .foregroundColor(.green)

            Text("// Before you go:")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(Color(white: 0.4))

            Text(educationBody)
                .font(.system(.callout, design: .monospaced))
                .foregroundColor(Color(white: 0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .opacity(showBody ? 1 : 0)
                .offset(y: showBody ? 0 : 8)

            Button(action: onContinue) {
                Text("[ Ready \u{2192} ]")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.green)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(2)
            }
            .opacity(showButton ? 1 : 0)
        }
        .padding(.top, 8)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showBody = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(1.0)) {
                showButton = true
            }
        }
    }
}
