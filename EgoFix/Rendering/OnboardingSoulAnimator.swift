import SceneKit

/// Animation states for the onboarding 3D soul.
enum SoulAnimState {
    case orbit
    case splitting
    case split
    case merging
}

/// Per-cube flicker state machine (matches prototype).
enum CubeFlickerState {
    case off
    case flickeringOn
    case on
    case flickeringOff
}

/// Mutable per-cube animation state.
struct CubeAnimState {
    var angle: Float
    var flickerState: CubeFlickerState = .off
    var stateTimer: Float
    var targetColor: Int = 0          // 0=white, 1=green, 2=red
    var flickerClock: Float = 0
    var spinSpeeds: SIMD3<Float>

    // Snapshot for split transitions
    var orbitPos = SCNVector3Zero
    var orbitScale: Float = 1.0
    var orbitRot = SCNVector3Zero
    var columnPos = SCNVector3Zero
}

/// Drives the orbit, split, and flicker animations each frame.
/// Direct port of the prototype's JavaScript logic.
class OnboardingSoulAnimator {

    var state: SoulAnimState = .orbit
    var animT: Float = 0
    var splitFraction: Float = 0
    private var splitStartY: Float = 0
    private var splitFacingY: Float = 0

    var cubeStates: [CubeAnimState] = []

    // Constants matching prototype
    private let splitOffset: Float = 0.085
    private let splitDuration: Float = 2.0
    private let headWY: Float = 0.90
    private let columnYTop: Float = 0.95
    private let columnYBottom: Float = 0.72
    private let columnCubeSize: Float = 0.033
    private let columnGap: Float = 0.012

    // Cube colors: [white, green, red]
    private let cubeDiffuse: [UIColor] = [
        UIColor(white: 0.784, alpha: 1),
        UIColor.green,
        UIColor.red
    ]
    private let cubeEmissive: [UIColor] = [
        UIColor.black,
        UIColor(red: 0, green: 0.667, blue: 0, alpha: 1),
        UIColor(red: 0.667, green: 0, blue: 0, alpha: 1)
    ]
    private let cubeLightColors: [UIColor] = [.black, .green, .red]
    private let cubeLightIntensity: [CGFloat] = [0, 350, 350]

    init(cubeData: [OnboardingSoulScene.CubeData]) {
        cubeStates = cubeData.map { cube in
            CubeAnimState(
                angle: cube.angle,
                stateTimer: 1.0 + Float.random(in: 0...3),
                spinSpeeds: cube.spinSpeeds
            )
        }
    }

    // MARK: - Split / Merge triggers

    func triggerSplit(scene: OnboardingSoulScene) {
        guard state == .orbit else { return }
        state = .splitting
        animT = 0
        splitStartY = scene.figureGroup.eulerAngles.y
        splitFacingY = (splitStartY / (.pi * 2)).rounded() * .pi * 2

        for (i, cube) in scene.cubeNodes.enumerated() {
            cubeStates[i].orbitPos = cube.meshNode.position
            cubeStates[i].orbitScale = cube.meshNode.scale.x
            cubeStates[i].orbitRot = cube.meshNode.eulerAngles
        }
    }

    func triggerMerge(scene: OnboardingSoulScene) {
        guard state == .split else { return }
        state = .merging
        animT = 0

        for (i, cube) in scene.cubeNodes.enumerated() {
            cubeStates[i].columnPos = cube.meshNode.position
            cubeStates[i].spinSpeeds = SIMD3<Float>(
                0.3 + Float.random(in: 0...0.7),
                0.3 + Float.random(in: 0...0.7),
                0.2 + Float.random(in: 0...0.6)
            )
        }
    }

    // MARK: - Targeted Flicker (for scenario selections)

    /// Forces specific cubes into a flickering-on state with the given color.
    /// Used during onboarding scenarios to highlight cubes corresponding to selected bug weights.
    /// - Parameters:
    ///   - indices: Cube indices to target (0-6, matching canonical bug order)
    ///   - color: 1 = green, 2 = red
    func setCubeFlickerTarget(indices: [Int], color: Int) {
        for index in indices {
            guard index < cubeStates.count else { continue }
            cubeStates[index].targetColor = color
            cubeStates[index].flickerState = .flickeringOn
            cubeStates[index].stateTimer = 0.15
            cubeStates[index].flickerClock = 0
        }
    }

    /// Pulses all cubes green simultaneously for a brief acknowledgment flash.
    /// Used after reframe text completes during onboarding scenarios.
    func triggerAllGreenPulse() {
        for i in 0..<cubeStates.count {
            cubeStates[i].targetColor = 1 // green
            cubeStates[i].flickerState = .flickeringOn
            cubeStates[i].stateTimer = 0.3
            cubeStates[i].flickerClock = 0
        }
    }

    // MARK: - Frame update

    func update(dt: Float, scene: OnboardingSoulScene) {
        // --- State progression ---
        switch state {
        case .splitting:
            animT = min(animT + dt / splitDuration, 1)
            splitFraction = smoothstep(animT)
            if animT >= 1 { state = .split }
        case .split:
            splitFraction = 1
        case .merging:
            animT = min(animT + dt / splitDuration, 1)
            splitFraction = smoothstep(1 - animT)
            if animT >= 1 { state = .orbit; splitFraction = 0 }
        case .orbit:
            splitFraction = 0
        }

        // --- Figure rotation ---
        switch state {
        case .orbit:
            scene.figureGroup.eulerAngles.y += dt * 0.25
        case .splitting:
            scene.figureGroup.eulerAngles.y = splitStartY * (1 - splitFraction) + splitFacingY * splitFraction
        case .split:
            scene.figureGroup.eulerAngles.y = splitFacingY
        case .merging:
            scene.figureGroup.eulerAngles.y = splitFacingY
            scene.figureGroup.eulerAngles.y += dt * 0.25 * (1 - splitFraction)
            splitStartY = scene.figureGroup.eulerAngles.y
        }

        // --- Split offset ---
        scene.meshLeft.position.x = -splitFraction * splitOffset
        scene.meshRight.position.x = splitFraction * splitOffset

        // --- Update cubes ---
        for i in 0..<scene.cubeNodes.count {
            let cube = scene.cubeNodes[i]
            updateCubePosition(i: i, cube: cube, dt: dt, scene: scene)
            updateCubeFlicker(i: i, cube: cube, dt: dt)
            cube.lightNode.position = cube.meshNode.position
        }
    }

    // MARK: - Cube positioning

    private func updateCubePosition(i: Int, cube: OnboardingSoulScene.CubeData, dt: Float, scene: OnboardingSoulScene) {
        let cs = cubeStates[i]

        if splitFraction < 0.001 {
            // ORBIT
            cubeStates[i].angle += cube.orbitSpeed * dt
            let ang = cubeStates[i].angle + scene.figureGroup.eulerAngles.y
            cube.meshNode.position = SCNVector3(
                cos(ang) * cube.radius,
                headWY + cube.yOffset,
                sin(ang) * cube.radius
            )
            cube.meshNode.eulerAngles.x += cs.spinSpeeds.x * dt
            cube.meshNode.eulerAngles.y += cs.spinSpeeds.y * dt
            cube.meshNode.eulerAngles.z += cs.spinSpeeds.z * dt
        } else if state == .splitting || state == .split {
            // Lerp position from orbit snapshot to column target
            let ty = columnTargetY(i)
            let target = SCNVector3(0, ty, 0)
            cube.meshNode.position = lerpVec(cs.orbitPos, target, splitFraction)

            // Scale: lerp to uniform column size
            let targetScale = columnCubeSize / cube.geometrySize
            let s = cs.orbitScale * (1 - splitFraction) + targetScale * splitFraction
            cube.meshNode.scale = SCNVector3(s, s, s)

            // Lerp rotation toward zero
            cube.meshNode.eulerAngles = SCNVector3(
                cs.orbitRot.x * (1 - splitFraction),
                cs.orbitRot.y * (1 - splitFraction),
                cs.orbitRot.z * (1 - splitFraction)
            )
        } else if state == .merging {
            // Lerp from column back to live orbit
            cubeStates[i].angle += cube.orbitSpeed * dt
            let ang = cubeStates[i].angle + scene.figureGroup.eulerAngles.y
            let orbitTarget = SCNVector3(
                cos(ang) * cube.radius,
                headWY + cube.yOffset,
                sin(ang) * cube.radius
            )
            cube.meshNode.position = lerpVec(orbitTarget, cs.columnPos, splitFraction)

            // Scale back to original
            let targetScale = columnCubeSize / cube.geometrySize
            let s = targetScale * splitFraction + 1.0 * (1 - splitFraction)
            cube.meshNode.scale = SCNVector3(s, s, s)

            // Resume spin gradually
            let mf = 1 - splitFraction
            cube.meshNode.eulerAngles.x += cs.spinSpeeds.x * dt * mf
            cube.meshNode.eulerAngles.y += cs.spinSpeeds.y * dt * mf
            cube.meshNode.eulerAngles.z += cs.spinSpeeds.z * dt * mf
        }
    }

    // MARK: - Cube flicker

    private func updateCubeFlicker(i: Int, cube: OnboardingSoulScene.CubeData, dt: Float) {
        cubeStates[i].stateTimer -= dt
        cubeStates[i].flickerClock += dt

        let mat = cube.meshNode.geometry?.firstMaterial
        let light = cube.lightNode.light

        switch cubeStates[i].flickerState {
        case .off:
            if cubeStates[i].stateTimer <= 0 {
                cubeStates[i].targetColor = 1 + Int.random(in: 0...1) // green or red
                cubeStates[i].flickerState = .flickeringOn
                cubeStates[i].stateTimer = 0.15 + Float.random(in: 0...0.2)
                cubeStates[i].flickerClock = 0
            }

        case .flickeringOn:
            let on = sin(cubeStates[i].flickerClock * 55) > 0
            let ci = on ? cubeStates[i].targetColor : 0
            applyCubeColor(ci, material: mat, light: light)
            if cubeStates[i].stateTimer <= 0 {
                cubeStates[i].flickerState = .on
                cubeStates[i].stateTimer = 2.0 + Float.random(in: 0...4)
                applyCubeColor(cubeStates[i].targetColor, material: mat, light: light)
            }

        case .on:
            if cubeStates[i].stateTimer <= 0 {
                cubeStates[i].flickerState = .flickeringOff
                cubeStates[i].stateTimer = 0.15 + Float.random(in: 0...0.2)
                cubeStates[i].flickerClock = 0
            }

        case .flickeringOff:
            let on = sin(cubeStates[i].flickerClock * 55) > 0
            let ci = on ? cubeStates[i].targetColor : 0
            applyCubeColor(ci, material: mat, light: light)
            if cubeStates[i].stateTimer <= 0 {
                cubeStates[i].flickerState = .off
                cubeStates[i].stateTimer = 1.5 + Float.random(in: 0...4)
                applyCubeColor(0, material: mat, light: light)
            }
        }
    }

    private func applyCubeColor(_ colorIndex: Int, material: SCNMaterial?, light: SCNLight?) {
        material?.diffuse.contents = cubeDiffuse[colorIndex]
        material?.specular.contents = UIColor.white
        material?.emission.contents = cubeEmissive[colorIndex]
        light?.color = cubeLightColors[colorIndex]
        light?.intensity = cubeLightIntensity[colorIndex]
    }

    // MARK: - Helpers

    private func smoothstep(_ x: Float) -> Float {
        let t = max(0, min(1, x))
        return t * t * (3 - 2 * t)
    }

    private func columnTargetY(_ i: Int) -> Float {
        let total = 7 * columnCubeSize + 6 * columnGap
        let startY = columnYBottom + (columnYTop - columnYBottom - total) / 2
        return startY + Float(i) * (columnCubeSize + columnGap) + columnCubeSize / 2
    }

    private func lerpVec(_ a: SCNVector3, _ b: SCNVector3, _ t: Float) -> SCNVector3 {
        SCNVector3(
            a.x + (b.x - a.x) * t,
            a.y + (b.y - a.y) * t,
            a.z + (b.z - a.z) * t
        )
    }
}
