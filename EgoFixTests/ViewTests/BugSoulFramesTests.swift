import XCTest
@testable import EgoFix

final class BugSoulFramesTests: XCTestCase {

    private let allSlugs = [
        "need-to-be-right",
        "need-to-impress",
        "need-to-be-liked",
        "need-to-control",
        "need-to-compare",
        "need-to-deflect",
        "need-to-narrate",
    ]

    private let allIntensities: [BugIntensity] = [.quiet, .present, .loud]

    // MARK: - All 21 sets return non-empty frames

    func test_allSlugsAndIntensities_returnNonEmptyFrames() {
        for slug in allSlugs {
            for intensity in allIntensities {
                let frames = BugSoulFrames.frames(for: slug, intensity: intensity)
                XCTAssertFalse(
                    frames.isEmpty,
                    "\(slug) \(intensity) returned empty frames"
                )
            }
        }
    }

    // MARK: - Frame count within 4-8 range

    func test_allFrameSets_haveValidFrameCount() {
        for slug in allSlugs {
            for intensity in allIntensities {
                let frames = BugSoulFrames.frames(for: slug, intensity: intensity)
                XCTAssertGreaterThanOrEqual(
                    frames.count, 4,
                    "\(slug) \(intensity) has \(frames.count) frames, expected >= 4"
                )
                XCTAssertLessThanOrEqual(
                    frames.count, 8,
                    "\(slug) \(intensity) has \(frames.count) frames, expected <= 8"
                )
            }
        }
    }

    // MARK: - Quiet = 4, Present = 6, Loud = 8

    func test_quietFrames_haveFourFrames() {
        for slug in allSlugs {
            let frames = BugSoulFrames.frames(for: slug, intensity: .quiet)
            XCTAssertEqual(frames.count, 4, "\(slug) quiet should have 4 frames")
        }
    }

    func test_presentFrames_haveSixFrames() {
        for slug in allSlugs {
            let frames = BugSoulFrames.frames(for: slug, intensity: .present)
            XCTAssertEqual(frames.count, 6, "\(slug) present should have 6 frames")
        }
    }

    func test_loudFrames_haveEightFrames() {
        for slug in allSlugs {
            let frames = BugSoulFrames.frames(for: slug, intensity: .loud)
            XCTAssertEqual(frames.count, 8, "\(slug) loud should have 8 frames")
        }
    }

    // MARK: - Consistent line count within each set

    func test_allFrameSets_haveConsistentLineCount() {
        for slug in allSlugs {
            for intensity in allIntensities {
                let frames = BugSoulFrames.frames(for: slug, intensity: intensity)
                guard let first = frames.first else { continue }
                let expectedLines = first.components(separatedBy: "\n").count
                for (i, frame) in frames.enumerated() {
                    let lineCount = frame.components(separatedBy: "\n").count
                    XCTAssertEqual(
                        lineCount, expectedLines,
                        "\(slug) \(intensity) frame \(i) has \(lineCount) lines, expected \(expectedLines)"
                    )
                }
            }
        }
    }

    // MARK: - Unknown slug returns fallback

    func test_unknownSlug_returnsFallbackFrames() {
        let frames = BugSoulFrames.frames(for: "nonexistent-bug", intensity: .present)
        XCTAssertFalse(frames.isEmpty)
        XCTAssertGreaterThanOrEqual(frames.count, 4)
    }
}
