import SwiftUI
import MetalKit

/// Standalone debug view for the 3D ASCII soul animation.
/// Renders the Metal soul at 340x340 (scaled up by SwiftUI) with
/// tap-to-split/merge interaction and a live state overlay.
struct SoulDebugView: View {
    @State private var renderer: OnboardingSoulRenderer?
    @State private var animState: String = "orbit"
    @State private var rendererFailed = false

    var body: some View {
        ZStack {
            EgoTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // HEADER
                    Text("SOUL DEBUG")
                        .font(EgoTheme.label())
                        .foregroundColor(EgoTheme.green)
                        .padding(.bottom, 4)

                    Text("// 3D ASCII renderer — Metal + SceneKit pipeline")
                        .font(EgoTheme.label())
                        .foregroundColor(EgoTheme.textMuted)
                        .padding(.bottom, 24)

                    // RENDER TARGET
                    if rendererFailed {
                        rendererErrorView
                    } else {
                        GeometryReader { geo in
                            SoulDebugMetalView(
                                onRendererReady: { r in renderer = r },
                                onRendererFailed: { rendererFailed = true }
                            )
                            .frame(width: geo.size.width, height: geo.size.width)
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .onTapGesture { toggleSplit() }
                    }

                    // STATE OVERLAY
                    stateOverlay
                        .padding(.top, 16)

                    // INTERACTION HINT
                    Text("// Tap to split. Tap again to merge.")
                        .font(EgoTheme.label())
                        .foregroundColor(EgoTheme.textMuted)
                        .padding(.top, 16)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - State Overlay

    private var stateOverlay: some View {
        VStack(alignment: .leading, spacing: 6) {
            stateRow("state", value: animState)
            stateRow("pipeline", value: renderer != nil ? "active" : "nil")
            stateRow("resolution", value: "680 x 680")
        }
    }

    private func stateRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(EgoTheme.mono(.caption))
                .foregroundColor(EgoTheme.textMuted)
            Spacer()
            Text(value)
                .font(EgoTheme.mono(.caption))
                .foregroundColor(EgoTheme.green)
        }
    }

    // MARK: - Error State

    private var rendererErrorView: some View {
        VStack(spacing: 12) {
            Text("RENDERER INIT FAILED")
                .font(EgoTheme.mono(.caption))
                .foregroundColor(.red)

            Text("// Metal device or OBJ bundle resource missing.\n// Check console for [OnboardingSoulView] logs.")
                .font(EgoTheme.label())
                .foregroundColor(EgoTheme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(width: 340, height: 340)
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(EgoTheme.border, lineWidth: 1)
        )
    }

    // MARK: - Split / Merge

    private func toggleSplit() {
        guard let renderer = renderer else { return }
        let animator = renderer.animator
        let scene = renderer.soulScene

        switch animator.state {
        case .orbit:
            animator.triggerSplit(scene: scene)
            animState = "splitting"
        case .split:
            animator.triggerMerge(scene: scene)
            animState = "merging"
        default:
            break
        }

        // Poll the animator state briefly to update the label
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            updateStateLabel()
        }
    }

    private func updateStateLabel() {
        guard let renderer = renderer else { return }
        switch renderer.animator.state {
        case .orbit:     animState = "orbit"
        case .splitting: animState = "splitting"
        case .split:     animState = "split"
        case .merging:   animState = "merging"
        }
    }
}

// MARK: - Metal View (UIViewRepresentable)

/// Wraps MTKView with the OnboardingSoulRenderer, exposing the renderer
/// reference via a callback so the parent view can trigger split/merge.
private struct SoulDebugMetalView: UIViewRepresentable {
    let onRendererReady: (OnboardingSoulRenderer) -> Void
    let onRendererFailed: () -> Void

    func makeUIView(context: Context) -> MTKView {
        let metalView = MTKView()
        metalView.device = MTLCreateSystemDefaultDevice()
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        metalView.preferredFramesPerSecond = 30
        metalView.isPaused = false
        metalView.enableSetNeedsDisplay = false
        metalView.isOpaque = true
        metalView.backgroundColor = .black

        // Lock internal resolution to 680x680
        metalView.autoResizeDrawable = false
        metalView.drawableSize = CGSize(width: 680, height: 680)

        if let renderer = OnboardingSoulRenderer(metalView: metalView) {
            context.coordinator.renderer = renderer
            metalView.delegate = renderer
            onRendererReady(renderer)
        } else {
            #if DEBUG
            NSLog("[SoulDebugMetalView] ERROR: Renderer init returned nil")
            #endif
            onRendererFailed()
        }

        return metalView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator {
        var renderer: OnboardingSoulRenderer?
    }
}

#Preview {
    NavigationStack {
        SoulDebugView()
    }
}
