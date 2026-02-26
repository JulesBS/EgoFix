import XCTest
@testable import EgoFix

final class AvoidanceDetectorTests: XCTestCase {

    let detector = AvoidanceDetector()

    func test_AvoidanceDetector_triggersAt50Percent() {
        let userId = UUID()
        let bugId = UUID()

        // Create events with >50% skip rate, minimum 4 skips
        var events: [AnalyticsEvent] = []

        // 5 skips, 3 applied = 62.5% skip rate
        for _ in 0..<5 {
            events.append(AnalyticsEvent(
                userId: userId,
                eventType: .fixSkipped,
                bugId: bugId,
                dayOfWeek: 1,
                hourOfDay: 10
            ))
        }
        for _ in 0..<3 {
            events.append(AnalyticsEvent(
                userId: userId,
                eventType: .fixApplied,
                bugId: bugId,
                dayOfWeek: 1,
                hourOfDay: 10
            ))
        }

        let pattern = detector.analyze(events: events, diagnostics: [], userId: userId)

        XCTAssertNotNil(pattern)
        XCTAssertEqual(pattern?.patternType, .avoidance)
    }

    func test_AvoidanceDetector_ignoresBelowThreshold() {
        let userId = UUID()
        let bugId = UUID()

        // Create events with <50% skip rate
        var events: [AnalyticsEvent] = []

        // 2 skips, 6 applied = 25% skip rate
        for _ in 0..<2 {
            events.append(AnalyticsEvent(
                userId: userId,
                eventType: .fixSkipped,
                bugId: bugId,
                dayOfWeek: 1,
                hourOfDay: 10
            ))
        }
        for _ in 0..<6 {
            events.append(AnalyticsEvent(
                userId: userId,
                eventType: .fixApplied,
                bugId: bugId,
                dayOfWeek: 1,
                hourOfDay: 10
            ))
        }

        let pattern = detector.analyze(events: events, diagnostics: [], userId: userId)

        XCTAssertNil(pattern)
    }

    func test_AvoidanceDetector_requiresMinimumSkips() {
        let userId = UUID()
        let bugId = UUID()

        // Create events with high skip rate but below minimum count
        var events: [AnalyticsEvent] = []

        // 3 skips, 1 applied = 75% skip rate but only 3 skips
        for _ in 0..<3 {
            events.append(AnalyticsEvent(
                userId: userId,
                eventType: .fixSkipped,
                bugId: bugId,
                dayOfWeek: 1,
                hourOfDay: 10
            ))
        }
        events.append(AnalyticsEvent(
            userId: userId,
            eventType: .fixApplied,
            bugId: bugId,
            dayOfWeek: 1,
            hourOfDay: 10
        ))

        let pattern = detector.analyze(events: events, diagnostics: [], userId: userId)

        XCTAssertNil(pattern)
    }
}
