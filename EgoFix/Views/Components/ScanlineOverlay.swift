import SwiftUI

/// A subtle scanline overlay that gives the app a CRT monitor feel.
/// Applied as a modifier to any view. Uses a pre-rendered pattern for performance.
struct ScanlineOverlay: View {
    /// Opacity of the scanlines (0.03-0.05 recommended)
    let opacity: Double

    /// Whether to include vignette effect (dark corners)
    let includeVignette: Bool

    init(opacity: Double = 0.04, includeVignette: Bool = true) {
        self.opacity = opacity
        self.includeVignette = includeVignette
    }

    var body: some View {
        ZStack {
            // Scanlines - horizontal lines repeating pattern
            Canvas { context, size in
                let lineSpacing: CGFloat = 3
                var y: CGFloat = 0
                while y < size.height {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                    context.fill(Path(rect), with: .color(.black.opacity(opacity)))
                    y += lineSpacing
                }
            }

            // Optional vignette - dark corners
            if includeVignette {
                RadialGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        .black.opacity(0.3)
                    ]),
                    center: .center,
                    startRadius: 100,
                    endRadius: 600
                )
            }
        }
        .allowsHitTesting(false)
    }
}

/// ViewModifier to easily apply scanline effect to any view
struct ScanlineModifier: ViewModifier {
    let opacity: Double
    let includeVignette: Bool

    init(opacity: Double = 0.04, includeVignette: Bool = true) {
        self.opacity = opacity
        self.includeVignette = includeVignette
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                ScanlineOverlay(opacity: opacity, includeVignette: includeVignette)
            }
    }
}

extension View {
    /// Applies a subtle CRT-style scanline overlay to the view
    func scanlines(opacity: Double = 0.04, vignette: Bool = true) -> some View {
        modifier(ScanlineModifier(opacity: opacity, includeVignette: vignette))
    }
}

#Preview {
    VStack {
        Text("EgoFix v1.0")
            .font(.system(.largeTitle, design: .monospaced))
            .foregroundColor(.green)
        Text("System ready.")
            .font(.system(.body, design: .monospaced))
            .foregroundColor(.green)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
    .scanlines()
}
