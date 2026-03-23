import SwiftUI

struct PatternAlertView: View {
    let pattern: DetectedPattern
    let onAcknowledge: () -> Void
    let onDismiss: () -> Void

    @State private var appeared = false
    @State private var shake = false
    @State private var borderPulse = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Pattern card
            VStack(alignment: .leading, spacing: 0) {
                Text("PATTERN_DETECTED")
                    .font(EgoTheme.label())
                    .tracking(2)
                    .foregroundColor(severityColor)
                    .shadow(color: severityColor.opacity(0.6), radius: 4)
                    .padding(.bottom, 16)

                Text(pattern.title)
                    .font(.system(size: 20, weight: .light, design: .monospaced))
                    .foregroundColor(EgoTheme.textPrimary)
                    .padding(.bottom, 12)

                Text(pattern.body)
                    .font(EgoTheme.mono())
                    .foregroundColor(EgoTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
            }
            .padding(24)
            .glassCard()
            .overlay(
                Rectangle()
                    .stroke(severityColor.opacity(borderPulse ? 0.6 : 0), lineWidth: 1)
            )
            .offset(y: appeared ? 0 : 40)
            .opacity(appeared ? 1 : 0)
            .modifier(ShakeEffect(shakes: shake ? 2 : 0))

            Spacer()

            // Action buttons
            VStack(spacing: 10) {
                FigmaCTAButton(label: "NOTED", showArrow: false, action: onAcknowledge)

                FigmaSecondaryButton(label: "DISMISS", action: onDismiss)
            }
            .opacity(appeared ? 1 : 0)

            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    shake = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeOut(duration: 0.3)) {
                    borderPulse = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        borderPulse = false
                    }
                }
            }
        }
    }

    private var severityColor: Color {
        switch pattern.severity {
        case .alert: return .red
        case .insight: return EgoTheme.amber
        case .observation: return EgoTheme.textMuted
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
