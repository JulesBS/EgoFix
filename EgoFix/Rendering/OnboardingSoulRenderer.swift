import MetalKit
import SceneKit

/// Orchestrates the per-frame rendering pipeline:
/// SceneKit offscreen → ASCII compute shader → bloom blur → composite.
class OnboardingSoulRenderer: NSObject, MTKViewDelegate {

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let scnRenderer: SCNRenderer
    let soulScene: OnboardingSoulScene
    let animator: OnboardingSoulAnimator

    // Font atlas
    private let fontAtlas: FontAtlasGenerator.AtlasInfo

    // Compute pipelines
    private let asciiPipeline: MTLComputePipelineState
    private let blurHPipeline: MTLComputePipelineState
    private let blurVPipeline: MTLComputePipelineState

    // Render pipeline (composite)
    private let compositePipeline: MTLRenderPipelineState
    private let compositeSampler: MTLSamplerState

    // Textures (all 340×340)
    private let sceneTexture: MTLTexture
    private let depthTexture: MTLTexture
    private let asciiTexture: MTLTexture
    private let bloomMaskTexture: MTLTexture
    private let bloomTemp: MTLTexture
    private let bloom1Texture: MTLTexture
    private let bloom2Texture: MTLTexture
    private let bloom3Texture: MTLTexture

    private let sceneSize = 680
    private var lastTime: CFTimeInterval = 0

    init?(metalView: MTKView) {
        guard let device = metalView.device,
              let commandQueue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary() else { return nil }

        self.device = device
        self.commandQueue = commandQueue

        // --- Scene ---
        do {
            soulScene = try OnboardingSoulScene()
        } catch {
            #if DEBUG
            NSLog("[OnboardingSoulRenderer] Scene init failed: %@", "\(error)")
            #endif
            return nil
        }

        // --- SCNRenderer ---
        scnRenderer = SCNRenderer(device: device, options: nil)
        scnRenderer.scene = soulScene.scene
        scnRenderer.pointOfView = soulScene.cameraNode
        scnRenderer.isJitteringEnabled = false

        // --- Font Atlas ---
        guard let atlas = FontAtlasGenerator.generate(device: device) else { return nil }
        fontAtlas = atlas

        // --- Animator ---
        animator = OnboardingSoulAnimator(cubeData: soulScene.cubeNodes)

        // --- Compute Pipelines ---
        guard let asciiFunc = library.makeFunction(name: "asciiConvert"),
              let blurHFunc = library.makeFunction(name: "gaussianBlurH"),
              let blurVFunc = library.makeFunction(name: "gaussianBlurV") else { return nil }

        do {
            asciiPipeline = try device.makeComputePipelineState(function: asciiFunc)
            blurHPipeline = try device.makeComputePipelineState(function: blurHFunc)
            blurVPipeline = try device.makeComputePipelineState(function: blurVFunc)
        } catch { return nil }

        // --- Composite Render Pipeline ---
        guard let vertFunc = library.makeFunction(name: "compositeVertex"),
              let fragFunc = library.makeFunction(name: "compositeFragment") else { return nil }

        let pipeDesc = MTLRenderPipelineDescriptor()
        pipeDesc.vertexFunction = vertFunc
        pipeDesc.fragmentFunction = fragFunc
        pipeDesc.colorAttachments[0].pixelFormat = metalView.colorPixelFormat

        do {
            compositePipeline = try device.makeRenderPipelineState(descriptor: pipeDesc)
        } catch { return nil }

        let sampDesc = MTLSamplerDescriptor()
        sampDesc.minFilter = .linear
        sampDesc.magFilter = .linear
        guard let sampler = device.makeSamplerState(descriptor: sampDesc) else { return nil }
        compositeSampler = sampler

        // --- Allocate Textures ---
        let sz = sceneSize

        func makeRGBA(_ usage: MTLTextureUsage) -> MTLTexture? {
            let d = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .rgba8Unorm, width: sz, height: sz, mipmapped: false)
            d.usage = usage
            return device.makeTexture(descriptor: d)
        }

        guard let st = makeRGBA([.renderTarget, .shaderRead]),
              let at = makeRGBA([.shaderRead, .shaderWrite]),
              let bm = makeRGBA([.shaderRead, .shaderWrite]),
              let bt = makeRGBA([.shaderRead, .shaderWrite]),
              let b1 = makeRGBA([.shaderRead, .shaderWrite]),
              let b2 = makeRGBA([.shaderRead, .shaderWrite]),
              let b3 = makeRGBA([.shaderRead, .shaderWrite]) else { return nil }

        let depthDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .depth32Float, width: sz, height: sz, mipmapped: false)
        depthDesc.usage = [.renderTarget]
        depthDesc.storageMode = .private
        guard let dt = device.makeTexture(descriptor: depthDesc) else { return nil }

        sceneTexture = st
        depthTexture = dt
        asciiTexture = at
        bloomMaskTexture = bm
        bloomTemp = bt
        bloom1Texture = b1
        bloom2Texture = b2
        bloom3Texture = b3

        lastTime = CACurrentMediaTime()

        super.init()
    }

    // MARK: - MTKViewDelegate

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        let now = CACurrentMediaTime()
        let dt = Float(min(now - lastTime, 0.05))
        lastTime = now

        // 1. Update animation
        animator.update(dt: dt, scene: soulScene)

        // 2. Command buffer
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let drawable = view.currentDrawable else { return }

        // 3. Pass 1: SceneKit offscreen render
        let scenePass = MTLRenderPassDescriptor()
        scenePass.colorAttachments[0].texture = sceneTexture
        scenePass.colorAttachments[0].loadAction = .clear
        scenePass.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        scenePass.colorAttachments[0].storeAction = .store
        scenePass.depthAttachment.texture = depthTexture
        scenePass.depthAttachment.loadAction = .clear
        scenePass.depthAttachment.clearDepth = 1.0
        scenePass.depthAttachment.storeAction = .dontCare

        scnRenderer.render(
            atTime: now,
            viewport: CGRect(x: 0, y: 0, width: sceneSize, height: sceneSize),
            commandBuffer: commandBuffer,
            passDescriptor: scenePass
        )

        // 4. Pass 2: ASCII conversion
        if let encoder = commandBuffer.makeComputeCommandEncoder() {
            encoder.setComputePipelineState(asciiPipeline)
            encoder.setTexture(sceneTexture, index: 0)
            encoder.setTexture(fontAtlas.texture, index: 1)
            encoder.setTexture(asciiTexture, index: 2)
            encoder.setTexture(bloomMaskTexture, index: 3)

            var params = ASCIIParamsSwift(
                atlasCellWidth: Int32(fontAtlas.cellWidth),
                atlasCellHeight: Int32(fontAtlas.cellHeight),
                outputWidth: Int32(sceneSize),
                outputHeight: Int32(sceneSize)
            )
            encoder.setBytes(&params, length: MemoryLayout<ASCIIParamsSwift>.size, index: 0)

            let tg = MTLSize(width: 16, height: 16, depth: 1)
            let threadgroups = MTLSize(
                width: (sceneSize + tg.width - 1) / tg.width,
                height: (sceneSize + tg.height - 1) / tg.height,
                depth: 1
            )
            encoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: tg)
            encoder.endEncoding()
        }

        // 5. Pass 3a: Bloom blur (3 layers)
        applyBlur(commandBuffer: commandBuffer, input: bloomMaskTexture, output: bloom1Texture, radius: 4, sigma: 2.0)
        applyBlur(commandBuffer: commandBuffer, input: bloomMaskTexture, output: bloom2Texture, radius: 12, sigma: 6.0)
        applyBlur(commandBuffer: commandBuffer, input: bloomMaskTexture, output: bloom3Texture, radius: 28, sigma: 14.0)

        // 6. Pass 3b: Composite to drawable
        guard let renderPass = view.currentRenderPassDescriptor else { return }
        if let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass) {
            encoder.setRenderPipelineState(compositePipeline)
            encoder.setFragmentTexture(asciiTexture, index: 0)
            encoder.setFragmentTexture(bloom1Texture, index: 1)
            encoder.setFragmentTexture(bloom2Texture, index: 2)
            encoder.setFragmentTexture(bloom3Texture, index: 3)

            var compositeParams = CompositeParamsSwift(
                bloom1Alpha: 0.6,
                bloom2Alpha: 0.35,
                bloom3Alpha: 0.18
            )
            encoder.setFragmentBytes(&compositeParams, length: MemoryLayout<CompositeParamsSwift>.size, index: 0)
            encoder.setFragmentSamplerState(compositeSampler, index: 0)

            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            encoder.endEncoding()
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    // MARK: - Blur helper

    private func applyBlur(commandBuffer: MTLCommandBuffer,
                            input: MTLTexture, output: MTLTexture,
                            radius: Int, sigma: Float) {
        let tg = MTLSize(width: 16, height: 16, depth: 1)
        let threadgroups = MTLSize(
            width: (sceneSize + tg.width - 1) / tg.width,
            height: (sceneSize + tg.height - 1) / tg.height,
            depth: 1
        )

        // Horizontal: input → temp
        if let enc = commandBuffer.makeComputeCommandEncoder() {
            enc.setComputePipelineState(blurHPipeline)
            enc.setTexture(input, index: 0)
            enc.setTexture(bloomTemp, index: 1)
            var params = BlurParamsSwift(
                radius: Int32(radius), sigma: sigma,
                textureWidth: Int32(sceneSize), textureHeight: Int32(sceneSize)
            )
            enc.setBytes(&params, length: MemoryLayout<BlurParamsSwift>.size, index: 0)
            enc.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: tg)
            enc.endEncoding()
        }

        // Vertical: temp → output
        if let enc = commandBuffer.makeComputeCommandEncoder() {
            enc.setComputePipelineState(blurVPipeline)
            enc.setTexture(bloomTemp, index: 0)
            enc.setTexture(output, index: 1)
            var params = BlurParamsSwift(
                radius: Int32(radius), sigma: sigma,
                textureWidth: Int32(sceneSize), textureHeight: Int32(sceneSize)
            )
            enc.setBytes(&params, length: MemoryLayout<BlurParamsSwift>.size, index: 0)
            enc.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: tg)
            enc.endEncoding()
        }
    }
}

// MARK: - Swift-side structs matching Metal shader structs

private struct ASCIIParamsSwift {
    var atlasCellWidth: Int32
    var atlasCellHeight: Int32
    var outputWidth: Int32
    var outputHeight: Int32
}

private struct BlurParamsSwift {
    var radius: Int32
    var sigma: Float
    var textureWidth: Int32
    var textureHeight: Int32
}

private struct CompositeParamsSwift {
    var bloom1Alpha: Float
    var bloom2Alpha: Float
    var bloom3Alpha: Float
}
