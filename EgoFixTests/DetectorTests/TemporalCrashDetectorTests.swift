import XCTest
@testable import EgoFix

final class TemporalCrashDetectorTests: XCTestCase {

    let detector = TemporalCrashDetector()
    let bugNames: [UUID: String] = [:]

    func test_TemporalDetector_findsDayClusters() {
        let userId = UUID()

        // Create crashes mostly on Monday (weekday 2)
        var events: [AnalyticsEvent] = []

        // 4 crashes on Monday out of 8 total = 50%
        for _ in 0..<4 {
            events.append(AnalyticsEvent(
                userId: userId,
                eventType: .crashLogged,
                dayOfWeek: 2, // Monday
                hourOfDay: 14
            ))
        }
        // 4 crashes on other days
        for i in 0..<4 {
            events.append(AnalyticsEvent(
                userId: userId,
                eventType: .crashLogged,
                dayOfWeek: 3 + i, // Tue-Fri
                hourOfDay: 14
            ))
        }

        let pattern = detector.analyze(events: events, diagnostics: [], userId: userId, bugNames: bugNames)

        XCTAssertNotNil(pattern)
        XCTAssertEqual(pattern?.patternType, .temporalCrash)
        XCTAssertEqual(pattern?.title, "Mondays are rough")
    }

    func test_TemporalDetector_findsTimeClusters() {
        let userId = UUID()

        // Create crashes mostly in morning (6-12). Spread the morning crashes
        // across different weekdays so the day-pattern detector (which runs
        // first and uses a lower 40% threshold) does not trigger — isolating
        // the time pattern under test.
        var events: [AnalyticsEvent] = []

        // 4 crashes in morning out of 6 total = 66%, one per weekday Mon-Thu
        for day in 2..<6 {
            events.append(AnalyticsEvent(
                userId: userId,
                eventType: .crashLogged,
                dayOfWeek: day,
                hourOfDay: 9 // Morning
            ))
        }
        // 2 crashes at other times, on distinct days so no day clusters
        events.append(AnalyticsEvent(
            userId: userId,
            eventType: .crashLogged,
            dayOfWeek: 6,
            hourOfDay: 15 // Afternoon
        ))
        events.append(AnalyticsEvent(
            userId: userId,
            eventType: .crashLogged,
            dayOfWeek: 7,
            hourOfDay: 20 // Evening
        ))

        let pattern = detector.analyze(events: events, diagnostics: [], userId: userId, bugNames: bugNames)

        XCTAssertNotNil(pattern)
        XCTAssertEqual(pattern?.patternType, .temporalCrash)
        XCTAssertEqual(pattern?.title, "Morning slips")
    }

    func test_TemporalDetector_requiresMinimumCrashes() {
        let userId = UUID()

        // Only 2 crashes - below minimum
        let events = [
            AnalyticsEvent(
                userId: userId,
                eventType: .crashLogged,
                dayOfWeek: 2,
                hourOfDay: 9
            ),
            AnalyticsEvent(
                userId: userId,
                eventType: .crashLogged,
                dayOfWeek: 2,
                hourOfDay: 10
            )
        ]

        let pattern = detector.analyze(events: events, diagnostics: [], userId: userId, bugNames: bugNames)

        XCTAssertNil(pattern)
    }
}
