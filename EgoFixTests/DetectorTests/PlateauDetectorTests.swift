import XCTest
@testable import EgoFix

final class PlateauDetectorTests: XCTestCase {

    let detector = PlateauDetector()

    func test_PlateauDetector_requiresFixesApplied() {
        let userId = UUID()
        let bugId = UUID()

        // Create events with enough fixes applied
        var events: [AnalyticsEvent] = []
        for _ in 0..<7 {
            events.append(AnalyticsEvent(
                userId: userId,
                eventType: .fixApplied,
                bugId: bugId,
                dayOfWeek: 1,
                hourOfDay: 10
            ))
        }

        // Create diagnostics showing bug is still present/loud
        var diagnostics: [WeeklyDiagnostic] = []
        for i in 0..<4 {
            let weekStart = Calendar.current.date(byAdding: .weekOfYear, value: -i, to: Date())!
            diagnostics.append(WeeklyDiagnostic(
                userId: userId,
                weekStarting: weekStart,
                responses: [
                    BugDiagnosticResponse(
                        bugId: bugId,
                        intensity: .loud,
                        primaryContext: .work
                    )
                ]
            ))
        }

        let pattern = detector.analyze(events: events, diagnostics: diagnostics, userId: userId)

        XCTAssertNotNil(pattern)
        XCTAssertEqual(pattern?.patternType, .plateau)
    }

    func test_PlateauDetector_noPatternIfQuiet() {
        let userId = UUID()
        let bugId = UUID()

        // Create events with enough fixes applied
        var events: [AnalyticsEvent] = []
        for _ in 0..<7 {
            events.append(AnalyticsEvent(
                userId: userId,
                eventType: .fixApplied,
                bugId: bugId,
                dayOfWeek: 1,
                hourOfDay: 10
            ))
        }

        // Create diagnostics showing bug is quiet
        var diagnostics: [WeeklyDiagnostic] = []
        for i in 0..<4 {
            let weekStart = Calendar.current.date(byAdding: .weekOfYear, value: -i, to: Date())!
            diagnostics.append(WeeklyDiagnostic(
                userId: userId,
                weekStarting: weekStart,
                responses: [
                    BugDiagnosticResponse(
                        bugId: bugId,
                        intensity: .quiet,
                        primaryContext: nil
                    )
                ]
            ))
        }

        let pattern = detector.analyze(events: events, diagnostics: diagnostics, userId: userId)

        XCTAssertNil(pattern)
    }
}
