#include <metal_stdlib>
using namespace metal;

// ─── Constants matching the HTML prototype ───────────────────────────────────

constant int CW = 12;          // character cell width (scene pixels)
constant int CH = 20;          // character cell height (scene pixels)
constant int COLS = 56;        // 680 / 12
constant int ROWS = 34;        // 680 / 20
constant int CHAR_COUNT = 18;
constant int SCENE_W = 680;
constant int SCENE_H = 680;
constant float GAMMA_EXP = 0.27;
constant float BRIGHTNESS = 1.5;
constant float SAT_THRESHOLD = 0.2;

// ─── ASCII Conversion ────────────────────────────────────────────────────────

struct ASCIIParams {
    int atlasCellWidth;
    int atlasCellHeight;
    int outputWidth;
    int outputHeight;
};

kernel void asciiConvert(
    texture2d<float, access::read>  sceneTexture  [[texture(0)]],
    texture2d<float, access::read>  fontAtlas      [[texture(1)]],
    texture2d<float, access::write> asciiOutput    [[texture(2)]],
    texture2d<float, access::write> bloomOutput    [[texture(3)]],
    constant ASCIIParams& params                    [[buffer(0)]],
    uint2 gid                                       [[thread_position_in_grid]])
{
    int px = gid.x;
    int py = gid.y;
    if (px >= params.outputWidth || py >= params.outputHeight) return;

    // Which character cell?
    int col = px / CW;
    int row = py / CH;
    if (col >= COLS || row >= ROWS) {
        asciiOutput.write(float4(0, 0, 0, 1), gid);
        bloomOutput.write(float4(0, 0, 0, 0), gid);
        return;
    }

    // Sample center pixel of this cell from the scene render
    int sx = col * CW + CW / 2;
    int sy = row * CH + CH / 2;
    float4 s = sceneTexture.read(uint2(sx, sy));

    float a = s.a;
    float lum = a * (0.299 * s.r + 0.587 * s.g + 0.114 * s.b);

    if (lum < 0.005) {
        asciiOutput.write(float4(0, 0, 0, 1), gid);
        bloomOutput.write(float4(0, 0, 0, 0), gid);
        return;
    }

    // Character index from luminance
    int charIdx = int(min(0.9999, lum) * float(CHAR_COUNT));
    if (charIdx == 0) {
        asciiOutput.write(float4(0, 0, 0, 1), gid);
        bloomOutput.write(float4(0, 0, 0, 0), gid);
        return;
    }

    // Gamma-correct color
    float cr = min(1.0, pow(s.r * a, GAMMA_EXP) * BRIGHTNESS);
    float cg = min(1.0, pow(s.g * a, GAMMA_EXP) * BRIGHTNESS);
    float cb = min(1.0, pow(s.b * a, GAMMA_EXP) * BRIGHTNESS);

    // Sample font atlas for glyph shape
    int localX = px - col * CW;
    int localY = py - row * CH;

    int atlasX = charIdx * params.atlasCellWidth + localX * params.atlasCellWidth / CW;
    int atlasY = localY * params.atlasCellHeight / CH;

    atlasX = clamp(atlasX, 0, CHAR_COUNT * params.atlasCellWidth - 1);
    atlasY = clamp(atlasY, 0, params.atlasCellHeight - 1);

    float glyphAlpha = fontAtlas.read(uint2(atlasX, atlasY)).r;

    float4 asciiColor = float4(cr * glyphAlpha, cg * glyphAlpha, cb * glyphAlpha, 1.0);
    asciiOutput.write(asciiColor, gid);

    // Bloom: only saturated (non-gray) cells
    float maxC = max(cr, max(cg, cb));
    float minC = min(cr, min(cg, cb));
    bool isSaturated = (maxC > 0) && ((maxC - minC) / maxC > SAT_THRESHOLD);

    if (isSaturated) {
        bloomOutput.write(float4(cr * glyphAlpha, cg * glyphAlpha, cb * glyphAlpha, glyphAlpha), gid);
    } else {
        bloomOutput.write(float4(0, 0, 0, 0), gid);
    }
}

// ─── Gaussian Blur (separable) ───────────────────────────────────────────────

struct BlurParams {
    int radius;
    float sigma;
    int textureWidth;
    int textureHeight;
};

kernel void gaussianBlurH(
    texture2d<float, access::read>  input   [[texture(0)]],
    texture2d<float, access::write> output  [[texture(1)]],
    constant BlurParams& params             [[buffer(0)]],
    uint2 gid                               [[thread_position_in_grid]])
{
    if (int(gid.x) >= params.textureWidth || int(gid.y) >= params.textureHeight) return;

    float4 sum = float4(0);
    float wSum = 0;
    float invTwoSigmaSq = 1.0 / (2.0 * params.sigma * params.sigma);

    for (int dx = -params.radius; dx <= params.radius; dx++) {
        int sx = clamp(int(gid.x) + dx, 0, params.textureWidth - 1);
        float w = exp(-float(dx * dx) * invTwoSigmaSq);
        sum += input.read(uint2(sx, gid.y)) * w;
        wSum += w;
    }

    output.write(sum / wSum, gid);
}

kernel void gaussianBlurV(
    texture2d<float, access::read>  input   [[texture(0)]],
    texture2d<float, access::write> output  [[texture(1)]],
    constant BlurParams& params             [[buffer(0)]],
    uint2 gid                               [[thread_position_in_grid]])
{
    if (int(gid.x) >= params.textureWidth || int(gid.y) >= params.textureHeight) return;

    float4 sum = float4(0);
    float wSum = 0;
    float invTwoSigmaSq = 1.0 / (2.0 * params.sigma * params.sigma);

    for (int dy = -params.radius; dy <= params.radius; dy++) {
        int sy = clamp(int(gid.y) + dy, 0, params.textureHeight - 1);
        float w = exp(-float(dy * dy) * invTwoSigmaSq);
        sum += input.read(uint2(gid.x, sy)) * w;
        wSum += w;
    }

    output.write(sum / wSum, gid);
}

// ─── Fullscreen Composite ────────────────────────────────────────────────────

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut compositeVertex(uint vid [[vertex_id]]) {
    // Fullscreen triangle (3 vertices cover the entire screen)
    float2 positions[3] = {
        float2(-1, -1),
        float2( 3, -1),
        float2(-1,  3)
    };
    float2 texCoords[3] = {
        float2(0, 1),
        float2(2, 1),
        float2(0, -1)
    };

    VertexOut out;
    out.position = float4(positions[vid], 0, 1);
    out.texCoord = texCoords[vid];
    return out;
}

struct CompositeParams {
    float bloom1Alpha;   // 0.6
    float bloom2Alpha;   // 0.35
    float bloom3Alpha;   // 0.18
};

fragment float4 compositeFragment(
    VertexOut in                              [[stage_in]],
    texture2d<float> asciiTexture             [[texture(0)]],
    texture2d<float> bloom1                   [[texture(1)]],
    texture2d<float> bloom2                   [[texture(2)]],
    texture2d<float> bloom3                   [[texture(3)]],
    constant CompositeParams& params          [[buffer(0)]],
    sampler texSampler                        [[sampler(0)]])
{
    float4 base = asciiTexture.sample(texSampler, in.texCoord);
    float4 b1 = bloom1.sample(texSampler, in.texCoord);
    float4 b2 = bloom2.sample(texSampler, in.texCoord);
    float4 b3 = bloom3.sample(texSampler, in.texCoord);

    // Additive blending (matching 'lighter' composite operation)
    float4 result = base;
    result.rgb += b1.rgb * params.bloom1Alpha;
    result.rgb += b2.rgb * params.bloom2Alpha;
    result.rgb += b3.rgb * params.bloom3Alpha;
    result.a = 1.0;

    return saturate(result);
}
