import Foundation

final class TemporalCrashDetector: PatternDetector {
    let patternType: PatternType = .temporalCrash
    let minimumDataPoints: Int = 3

    // Day pattern: >40% crashes on same weekday, minimum 3
    private let dayThreshold: Double = 0.4
    // Time pattern: >50% crashes in same time bucket, minimum 3
    private let timeThreshold: Double = 0.5
    private let minimumCrashes: Int = 3

    func analyze(events: [AnalyticsEvent], diagnostics: [WeeklyDiagnostic], userId: UUID, bugNames: [UUID: String]) -> DetectedPattern? {
        let crashEvents = events.filter { $0.eventType == .crashLogged }

        guard crashEvents.count >= minimumCrashes else { return nil }

        // Check for day patterns
        if let dayPattern = detectDayPattern(crashEvents, userId: userId, bugNames: bugNames) {
            return dayPattern
        }

        // Check for time patterns
        if let timePattern = detectTimePattern(crashEvents, userId: userId, bugNames: bugNames) {
            return timePattern
        }

        return nil
    }

    private func detectDayPattern(_ events: [AnalyticsEvent], userId: UUID, bugNames: [UUID: String]) -> DetectedPattern? {
        var dayCounts: [Int: Int] = [:]

        for event in events {
            dayCounts[event.dayOfWeek, default: 0] += 1
        }

        let totalCrashes = events.count

        for (day, count) in dayCounts {
            guard count >= minimumCrashes else { continue }

            let rate = Double(count) / Double(totalCrashes)

            if rate > dayThreshold {
                let dayName = dayOfWeekName(day)
                let relatedBugIds = events.compactMap { $0.bugId }
                let bugNamesList = relatedBugIds.compactMap { bugNames[$0] }.joined(separator: ", ")
                let bugContext = bugNamesList.isEmpty ? "" : " Related: \(bugNamesList)."
                return DetectedPattern(
                    userId: userId,
                    patternType: .temporalCrash,
                    severity: .alert,
                    title: "\(dayName)s are rough",
                    body: "\(count) of \(totalCrashes) crashes happened on \(dayName)s. Something about that day gets you.\(bugContext)",
                    relatedBugIds: relatedBugIds,
                    dataPoints: totalCrashes
                )
            }
        }

        return nil
    }

    private func detectTimePattern(_ events: [AnalyticsEvent], userId: UUID, bugNames: [UUID: String]) -> DetectedPattern? {
        // Group hours into buckets: morning (6-12), afternoon (12-18), evening (18-24), night (0-6)
        var bucketCounts: [String: Int] = [:]

        for event in events {
            let bucket = timeBucket(for: event.hourOfDay)
            bucketCounts[bucket, default: 0] += 1
        }

        let totalCrashes = events.count

        for (bucket, count) in bucketCounts {
            guard count >= minimumCrashes else { continue }

            let rate = Double(count) / Double(totalCrashes)

            if rate > timeThreshold {
                let relatedBugIds = events.compactMap { $0.bugId }
                return DetectedPattern(
                    userId: userId,
                    patternType: .temporalCrash,
                    severity: .insight,
                    title: "\(bucket.capitalized) slips",
                    body: "\(count) of \(totalCrashes) crashes in the \(bucket). Your defenses drop then.",
                    relatedBugIds: relatedBugIds,
                    dataPoints: totalCrashes
                )
            }
        }

        return nil
    }

    private func dayOfWeekName(_ day: Int) -> String {
        switch day {
        case 1: return "Sunday"
        case 2: return "Monday"
        case 3: return "Tuesday"
        case 4: return "Wednesday"
        case 5: return "Thursday"
        case 6: return "Friday"
        case 7: return "Saturday"
        default: return "Unknown"
        }
    }

    private func timeBucket(for hour: Int) -> String {
        switch hour {
        case 6..<12: return "morning"
        case 12..<18: return "afternoon"
        case 18..<24: return "evening"
        default: return "night"
        }
    }
}
