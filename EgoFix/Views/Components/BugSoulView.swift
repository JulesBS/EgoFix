import SwiftUI

/// Animated ASCII soul for a bug. Uses `TimelineView` to drive frame advancement
/// so timers are managed by SwiftUI and never leak.
struct BugSoulView: View {
    let slug: String
    let intensity: BugIntensity
    var size: SoulSize = .large

    enum SoulSize {
        case small   // 11pt, for lists
        case medium  // 13pt, for sheets
        case large   // 16pt, for Today screen hero
    }

    var body: some View {
        let frames = BugSoulFrames.frames(for: slug, intensity: intensity)
        let count = max(frames.count, 1)

        TimelineView(.periodic(from: .now, by: frameRate)) { timeline in
            let index = frameIndex(for: timeline.date, frameCount: count)
            Text(frames.isEmpty ? "" : frames[index])
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundColor(BugColors.color(for: slug).opacity(colorOpacity))
                .multilineTextAlignment(.center)
                .lineSpacing(1)
        }
    }

    // MARK: - Frame timing

    private var frameRate: Double {
        switch intensity {
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

    private var colorOpacity: Double {
        switch intensity {
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
