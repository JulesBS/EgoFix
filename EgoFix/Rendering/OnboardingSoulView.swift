import SwiftUI
import MetalKit

/// SwiftUI wrapper for the 3D ASCII onboarding animation.
/// Renders a human figure with orbiting cubes as ASCII art using Metal.
///
/// Usage:
/// ```
/// OnboardingSoulView()
///     .frame(width: 170, height: 170)
/// ```
struct OnboardingSoulView: UIViewRepresentable {
    /// Optional callback exposing the renderer for external split/merge control.
    var onRendererReady: ((OnboardingSoulRenderer) -> Void)? = nil
    /// Optional callback when renderer fails to initialize (e.g., no Metal support).
    var onRendererFailed: (() -> Void)? = nil
    /// When true, pauses the Metal render loop to save GPU/battery.
    var isPaused: Bool = false

    func makeUIView(context: Context) -> MTKView {
        let metalView = MTKView()
        metalView.device = MTLCreateSystemDefaultDevice()
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        metalView.preferredFramesPerSecond = 30
        metalView.isPaused = isPaused
        metalView.enableSetNeedsDisplay = false
        metalView.isOpaque = true
        metalView.backgroundColor = .black

        // Lock internal resolution to 680×680 regardless of SwiftUI frame
        metalView.autoResizeDrawable = false
        metalView.drawableSize = CGSize(width: 680, height: 680)

        if let renderer = OnboardingSoulRenderer(metalView: metalView) {
            context.coordinator.renderer = renderer
            metalView.delegate = renderer
            onRendererReady?(renderer)
            NSLog("[OnboardingSoulView] Renderer created OK, cubes: %d", renderer.soulScene.cubeNodes.count)
        } else {
            NSLog("[OnboardingSoulView] ERROR: Renderer init returned nil")
            onRendererFailed?()
        }

        return metalView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        uiView.isPaused = isPaused
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator {
        var renderer: OnboardingSoulRenderer?
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        OnboardingSoulView()
            .frame(width: 170, height: 170)
    }
}
