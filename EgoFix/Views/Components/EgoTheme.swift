import SwiftUI

/// Centralized design tokens extracted from the Figma SYSTEM_INIT design.
/// Single source of truth for colors, fonts, and reusable view modifiers.
enum EgoTheme {

    // MARK: - Colors

    /// Primary background: #131313 (warm dark, not pure black)
    static let bg = Color(red: 0.075, green: 0.075, blue: 0.075)

    /// Primary text: #E5E2E1 (warm off-white)
    static let textPrimary = Color(red: 0.898, green: 0.886, blue: 0.882)

    /// Secondary/muted text: #84967E (sage green)
    static let textMuted = Color(red: 0.518, green: 0.588, blue: 0.494)

    /// Terminal green accent: #00FF41
    static let green = Color(red: 0, green: 1, blue: 0.255)

    /// Green at low opacity for subtle borders/backgrounds
    static let greenSubtle = Color(red: 0, green: 1, blue: 0.255).opacity(0.2)

    /// Green glow shadow color
    static let greenGlow = Color(red: 0, green: 1, blue: 0.255).opacity(0.4)

    /// Amber/pending state: #FDAF00
    static let amber = Color(red: 0.992, green: 0.686, blue: 0)

    /// Card/element border: rgba(59, 75, 55, 0.4)
    static let border = Color(red: 0.231, green: 0.294, blue: 0.216).opacity(0.4)

    /// Subtle divider: rgba(59, 75, 55, 0.2)
    static let borderSubtle = Color(red: 0.231, green: 0.294, blue: 0.216).opacity(0.2)

    /// Card/button surface: #353534
    static let surface = Color(red: 0.208, green: 0.208, blue: 0.204)

    /// Glass-morphism base: rgba(14, 14, 14, 0.5)
    static let glass = Color(red: 0.055, green: 0.055, blue: 0.055).opacity(0.5)

    // MARK: - Spacing

    /// Tight: 4pt (badge internals, minimal gaps)
    static let spacingTight: CGFloat = 4
    /// Small: 8pt (list items, inline elements)
    static let spacingSmall: CGFloat = 8
    /// Medium: 12pt (card internals, related groups)
    static let spacingMedium: CGFloat = 12
    /// Default: 16pt (section gaps, standard padding)
    static let spacing: CGFloat = 16
    /// Large: 24pt (major sections, screen padding)
    static let spacingLarge: CGFloat = 24
    /// XLarge: 32pt (hero gaps, screen-level separation)
    static let spacingXL: CGFloat = 32

    // MARK: - Fonts

    /// Terminal/monospaced output at a given text style
    static func mono(_ style: Font.TextStyle = .body) -> Font {
        .system(style, design: .monospaced)
    }

    /// Large heading: light weight monospaced
    static func heading(_ size: CGFloat) -> Font {
        .system(size: size, weight: .light, design: .monospaced)
    }

    /// Small tracked label (section headers, metadata)
    static func label() -> Font {
        .system(.caption2, design: .monospaced)
    }
}

// MARK: - View Modifiers

extension View {

    /// Green glow text shadow matching Figma's `0 0 8px #00FF41`
    func greenGlow() -> some View {
        self.shadow(color: EgoTheme.greenGlow, radius: 4, x: 0, y: 0)
    }

    /// Glass-morphism card: blurred background + border
    func glassCard() -> some View {
        self
            .background(.ultraThinMaterial.opacity(0.3))
            .background(EgoTheme.glass)
            .overlay(
                RoundedRectangle(cornerRadius: 1)
                    .stroke(EgoTheme.border, lineWidth: 1)
            )
    }

    /// Corner bracket decoration on all four corners
    func cornerBrackets(
        color: Color = EgoTheme.green.opacity(0.4),
        size: CGFloat = 16,
        lineWidth: CGFloat = 1
    ) -> some View {
        self.overlay(
            GeometryReader { _ in
                ZStack {
                    CornerBracket(corner: .topLeading, size: size, color: color, lineWidth: lineWidth)
                    CornerBracket(corner: .topTrailing, size: size, color: color, lineWidth: lineWidth)
                    CornerBracket(corner: .bottomLeading, size: size, color: color, lineWidth: lineWidth)
                    CornerBracket(corner: .bottomTrailing, size: size, color: color, lineWidth: lineWidth)
                }
            }
            .allowsHitTesting(false)
        )
    }
}
