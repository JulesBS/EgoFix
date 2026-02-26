import XCTest
@testable import EgoFix

final class PlateauDetectorTests: XCTestCase {

    let detector = PlateauDetector()

    func test_PlateauDetector_requiresFixesApplied() {
        let userId = UUID()
        let bugId = UUID()
        let bugNames: [UUID: String] = [bugId: "Need to control"]

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

        let pattern = detector.analyze(events: events, diagnostics: diagnostics, userId: userId, bugNames: bugNames)

        XCTAssertNotNil(pattern)
        XCTAssertEqual(pattern?.patternType, .plateau)
        XCTAssertEqual(pattern?.title, "Stuck")
        XCTAssertTrue(pattern?.body.contains("Need to control") ?? false)
    }

    func test_PlateauDetector_noPatternIfQuiet() {
        let userId = UUID()
        let bugId = UUID()
        let bugNames: [UUID: String] = [bugId: "Need to control"]

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

        let pattern = detector.analyze(events: events, diagnostics: diagnostics, userId: userId, bugNames: bugNames)

        XCTAssertNil(pattern)
    }
}
