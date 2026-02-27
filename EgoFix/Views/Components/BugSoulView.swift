import SwiftUI

/// Reaction the soul plays when the user marks a fix outcome.
enum SoulReaction: Equatable {
    case applied    // brief quiet shift + brightness pulse
    case failed     // glitch flicker + loud shift
}

/// Animated ASCII soul for a bug. Uses `TimelineView` to drive frame advancement
/// so timers are managed by SwiftUI and never leak.
struct BugSoulView: View {
    let slug: String
    let intensity: BugIntensity
    var size: SoulSize = .large
    var reaction: SoulReaction? = nil

    enum SoulSize {
        case small   // 11pt, for lists
        case medium  // 13pt, for sheets
        case large   // 16pt, for Today screen hero
    }

    @State private var reactionActive = false
    @State private var brightnessPulse = false
    @State private var glitchOffset: CGFloat = 0

    private var effectiveIntensity: BugIntensity {
        guard reactionActive, let reaction else { return intensity }
        switch reaction {
        case .applied: return intensity.quieter
        case .failed: return intensity.louder
        }
    }

    var body: some View {
        let frames = BugSoulFrames.frames(for: slug, intensity: effectiveIntensity)
        let count = max(frames.count, 1)

        TimelineView(.periodic(from: .now, by: frameRate)) { timeline in
            let index = frameIndex(for: timeline.date, frameCount: count)
            Text(frames.isEmpty ? "" : frames[index])
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundColor(BugColors.color(for: slug).opacity(effectiveColorOpacity))
                .multilineTextAlignment(.center)
                .lineSpacing(1)
                .offset(x: glitchOffset)
        }
        .onChange(of: reaction) { _, newValue in
            if let newValue {
                triggerReaction(newValue)
            }
        }
    }

    // MARK: - Reaction

    private func triggerReaction(_ reaction: SoulReaction) {
        reactionActive = true

        switch reaction {
        case .applied:
            // Brightness pulse
            withAnimation(.easeOut(duration: 0.15)) {
                brightnessPulse = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.3)) {
                    brightnessPulse = false
                }
            }
            // Return to normal intensity after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    reactionActive = false
                }
            }

        case .failed:
            // Glitch flicker (rapid horizontal jitter)
            performGlitch(steps: 6, step: 0)
            // Return to normal intensity after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    reactionActive = false
                }
            }
        }
    }

    private func performGlitch(steps: Int, step: Int) {
        guard step < steps else {
            glitchOffset = 0
            return
        }
        glitchOffset = CGFloat.random(in: -4...4)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            performGlitch(steps: steps, step: step + 1)
        }
    }

    // MARK: - Frame timing

    private var frameRate: Double {
        switch effectiveIntensity {
        case .quiet: return 1.2
        case .present: return 0.5
        case .loud: return 0.2
        }
    }

    /// Derives a deterministic frame index from the current date so that
    /// every timeline tick produces the next frame in sequence.
    private func frameIndex(for date: Date, frameCount: Int) -> Int {
        let elapsed = date.timeIntervalSinceReferenceDate
        let tick = Int(elapsed / frameRate)
        return tick % frameCount
    }

    // MARK: - Sizing

    private var fontSize: CGFloat {
        switch size {
        case .small: return 11
        case .medium: return 13
        case .large: return 16
        }
    }

    // MARK: - Color intensity

    private var effectiveColorOpacity: Double {
        if brightnessPulse { return 1.0 }
        return colorOpacity
    }

    private var colorOpacity: Double {
        switch effectiveIntensity {
        case .quiet: return 0.5
        case .present: return 0.75
        case .loud: return 1.0
        }
    }
}

// MARK: - Preview

#Preview("All Souls") {
    ScrollView {
        VStack(spacing: 40) {
            ForEach([
                "need-to-be-right",
                "need-to-impress",
                "need-to-be-liked",
                "need-to-control",
                "need-to-compare",
                "need-to-deflect",
                "need-to-narrate",
            ], id: \.self) { slug in
                VStack(spacing: 4) {
                    Text(slug)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white)

                    HStack(alignment: .top, spacing: 24) {
                        VStack(spacing: 2) {
                            Text("quiet")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.gray)
                            BugSoulView(slug: slug, intensity: .quiet, size: .small)
                        }
                        VStack(spacing: 2) {
                            Text("present")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.gray)
                            BugSoulView(slug: slug, intensity: .present, size: .small)
                        }
                        VStack(spacing: 2) {
                            Text("loud")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.gray)
                            BugSoulView(slug: slug, intensity: .loud, size: .small)
                        }
                    }
                }
            }
        }
        .padding()
    }
    .background(Color.black)
}
