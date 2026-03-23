import CoreText
import CoreGraphics
import Metal
import UIKit

/// Generates a single-row font atlas texture containing the 18 ASCII characters
/// used for the ASCII art shader. Each character is rasterized via Core Text
/// into a grayscale texture that the compute shader samples.
struct FontAtlasGenerator {

    /// The 18 ASCII characters ordered by luminance (space = darkest, W = brightest).
    static let characters: [Character] = Array(" `.',-~:;!=+*%&#@MW")

    struct AtlasInfo {
        let texture: MTLTexture
        let cellWidth: Int
        let cellHeight: Int
        let charCount: Int
    }

    static func generate(device: MTLDevice,
                          fontName: String = "Menlo",
                          fontSize: CGFloat = 24) -> AtlasInfo? {
        let charCount = characters.count
        let cellWidth = Int(ceil(fontSize * 0.65))
        let cellHeight = Int(ceil(fontSize * 1.2))
        let atlasWidth = cellWidth * charCount
        let atlasHeight = cellHeight

        guard let context = CGContext(
            data: nil,
            width: atlasWidth,
            height: atlasHeight,
            bitsPerComponent: 8,
            bytesPerRow: atlasWidth,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        // Clear to black
        context.setFillColor(gray: 0, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: atlasWidth, height: atlasHeight))

        let ctFont = CTFontCreateWithName(fontName as CFString, fontSize, nil)

        for (i, char) in characters.enumerated() {
            let x = CGFloat(i * cellWidth)
            let attrString = NSAttributedString(
                string: String(char),
                attributes: [
                    .font: ctFont,
                    .foregroundColor: UIColor.white
                ]
            )
            let line = CTLineCreateWithAttributedString(attrString)
            let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)

            let xOffset = x + (CGFloat(cellWidth) - bounds.width) / 2.0 - bounds.origin.x
            let yOffset = (CGFloat(cellHeight) - bounds.height) / 2.0 - bounds.origin.y

            context.saveGState()
            context.textPosition = CGPoint(x: xOffset, y: yOffset)
            CTLineDraw(line, context)
            context.restoreGState()
        }

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .r8Unorm,
            width: atlasWidth,
            height: atlasHeight,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead]

        guard let texture = device.makeTexture(descriptor: descriptor),
              let data = context.data else { return nil }

        texture.replace(
            region: MTLRegionMake2D(0, 0, atlasWidth, atlasHeight),
            mipmapLevel: 0,
            withBytes: data,
            bytesPerRow: atlasWidth
        )

        return AtlasInfo(
            texture: texture,
            cellWidth: cellWidth,
            cellHeight: cellHeight,
            charCount: charCount
        )
    }
}
