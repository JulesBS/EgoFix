import SwiftUI

struct PatternAlertView: View {
    let pattern: DetectedPattern
    let onAcknowledge: () -> Void
    let onDismiss: () -> Void

    @State private var appeared = false
    @State private var shake = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Text("PATTERN DETECTED")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(severityColor)
                    .shadow(color: severityColor.opacity(0.6), radius: 4, x: 0, y: 0)

                Text(pattern.title)
                    .font(.system(.title3, design: .monospaced))
                    .foregroundColor(.white)

                Text(pattern.body)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .offset(y: appeared ? 0 : -50)
            .opacity(appeared ? 1 : 0)
            .modifier(ShakeEffect(shakes: shake ? 2 : 0))

            Spacer()

            HStack(spacing: 24) {
                Button(action: onAcknowledge) {
                    Text("[ Noted ]")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.gray)
                        .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 0)
                }

                Button(action: onDismiss) {
                    Text("[ Dismiss ]")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
            .opacity(appeared ? 1 : 0)

            Spacer()
        }
        .padding()
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                appeared = true
            }
            // Brief shake after slide-in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    shake = true
                }
            }
        }
    }

    private var severityColor: Color {
        switch pattern.severity {
        case .alert: return .red
        case .insight: return .yellow
        case .observation: return .gray
        }
    }
}

// MARK: - Shake Effect

private struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = sin(shakes * .pi * 2) * 5
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}
