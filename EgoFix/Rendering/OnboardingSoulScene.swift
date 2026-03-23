import SceneKit

/// Manages the SceneKit scene for the onboarding 3D ASCII animation.
/// Loads the GLB model halves, configures camera, lights, and 7 orbiting cubes
/// to match the HTML/Three.js prototype.
class OnboardingSoulScene {

    let scene: SCNScene
    let cameraNode: SCNNode
    let figureGroup: SCNNode
    let meshLeft: SCNNode
    let meshRight: SCNNode
    let cubeNodes: [CubeData]

    // GLB model is ~20.68 units tall; scale to ~1 unit for scene
    private let modelScale: Float = 1.0 / 20.68

    struct CubeData {
        let meshNode: SCNNode
        let lightNode: SCNNode
        let geometrySize: Float
        var angle: Float
        let radius: Float
        let yOffset: Float
        let orbitSpeed: Float
        let spinSpeeds: SIMD3<Float>
        let columnIndex: Int
    }

    init() throws {
        scene = SCNScene()
        scene.background.contents = UIColor.black

        // --- Camera (matches prototype) ---
        let camera = SCNCamera()
        camera.fieldOfView = 22
        camera.zNear = 0.001
        camera.zFar = 50
        cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0.88, 1.1)
        cameraNode.look(at: SCNVector3(0, 0.84, 0))
        scene.rootNode.addChildNode(cameraNode)

        // --- Directional Light ---
        let dirLight = SCNLight()
        dirLight.type = .directional
        dirLight.color = UIColor.white
        dirLight.intensity = 1000
        dirLight.castsShadow = true
        dirLight.shadowMapSize = CGSize(width: 2048, height: 2048)
        dirLight.shadowMode = .forward
        dirLight.shadowSampleCount = 8
        dirLight.shadowBias = 1
        dirLight.shadowRadius = 3.0
        let dirLightNode = SCNNode()
        dirLightNode.light = dirLight
        dirLightNode.position = SCNVector3(-4.05, 5.95, -1.60)
        dirLightNode.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(dirLightNode)

        // --- Ambient Light ---
        let ambLight = SCNLight()
        ambLight.type = .ambient
        ambLight.color = UIColor.white
        ambLight.intensity = 50
        let ambNode = SCNNode()
        ambNode.light = ambLight
        scene.rootNode.addChildNode(ambNode)

        // --- Load Model Halves ---
        figureGroup = SCNNode()
        scene.rootNode.addChildNode(figureGroup)

        meshLeft = try Self.loadModelHalf(named: "FinalBaseMesh_left", scale: modelScale)
        meshRight = try Self.loadModelHalf(named: "FinalBaseMesh_right", scale: modelScale)
        figureGroup.addChildNode(meshLeft)
        figureGroup.addChildNode(meshRight)

        NSLog("[OnboardingSoulScene] Left children: %d, Right children: %d",
              meshLeft.childNodes.count, meshRight.childNodes.count)
        // Log bounding box of the entire figure
        let (minBound, maxBound) = figureGroup.boundingBox
        NSLog("[OnboardingSoulScene] Figure bounds: min(%f,%f,%f) max(%f,%f,%f)",
              minBound.x, minBound.y, minBound.z, maxBound.x, maxBound.y, maxBound.z)

        // --- 7 Orbiting Cubes ---
        var cubes: [CubeData] = []
        for i in 0..<7 {
            let size: Float = 0.028 + Float(i % 3) * 0.010
            let geometry = SCNBox(
                width: CGFloat(size), height: CGFloat(size),
                length: CGFloat(size), chamferRadius: 0
            )
            let material = SCNMaterial()
            material.lightingModel = .phong
            material.diffuse.contents = UIColor(white: 0.784, alpha: 1)
            material.specular.contents = UIColor.white
            material.shininess = 26
            material.isDoubleSided = true
            geometry.materials = [material]

            let meshNode = SCNNode(geometry: geometry)
            meshNode.castsShadow = true
            scene.rootNode.addChildNode(meshNode)

            let pointLight = SCNLight()
            pointLight.type = .omni
            pointLight.color = UIColor.black
            pointLight.intensity = 0
            pointLight.attenuationEndDistance = 0.3
            pointLight.attenuationFalloffExponent = 2
            let lightNode = SCNNode()
            lightNode.light = pointLight
            scene.rootNode.addChildNode(lightNode)

            let cube = CubeData(
                meshNode: meshNode,
                lightNode: lightNode,
                geometrySize: size,
                angle: Float(i) / 7.0 * .pi * 2,
                radius: 0.22 + Float(i % 3) * 0.06,
                yOffset: (Float(i % 4) - 1.5) * 0.09,
                orbitSpeed: Float(i % 2 == 0 ? 1 : -1) * (0.35 + Float(i % 5) * 0.08),
                spinSpeeds: SIMD3<Float>(
                    fmod(0.4 + Float(i) * 0.17, 1.0),
                    fmod(0.3 + Float(i) * 0.23, 1.0),
                    fmod(0.2 + Float(i) * 0.31, 0.8)
                ),
                columnIndex: i
            )
            cubes.append(cube)
        }
        cubeNodes = cubes
    }

    private static func loadModelHalf(named name: String, scale: Float) throws -> SCNNode {
        guard let url = Bundle.main.url(forResource: name, withExtension: "obj") else {
            let msg = "Missing \(name).obj in bundle"
            print("[OnboardingSoulScene] ERROR: \(msg)")
            throw NSError(domain: "OnboardingSoulScene", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: msg])
        }

        let scnScene = try SCNScene(url: url)

        let container = SCNNode()
        for child in scnScene.rootNode.childNodes {
            let clone = child.clone()
            Self.applyMaterial(to: clone, scale: scale)
            container.addChildNode(clone)
        }

        return container
    }

    private static func applyMaterial(to node: SCNNode, scale: Float) {
        if let geometry = node.geometry {
            let material = SCNMaterial()
            material.lightingModel = .phong
            material.diffuse.contents = UIColor(white: 0.784, alpha: 1)
            material.specular.contents = UIColor.white
            material.shininess = 26
            material.isDoubleSided = true
            geometry.materials = [material]
            node.castsShadow = true
            node.scale = SCNVector3(scale, scale, scale)
        }
        for child in node.childNodes {
            applyMaterial(to: child, scale: scale)
        }
    }
}
