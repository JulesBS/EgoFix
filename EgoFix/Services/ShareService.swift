import Foundation

final class ShareService {
    private let analyticsEventRepository: AnalyticsEventRepository

    init(analyticsEventRepository: AnalyticsEventRepository) {
        self.analyticsEventRepository = analyticsEventRepository
    }

    /// Generate shareable content for a fix.
    /// Includes only the prompt and inline comment — never personal data, stats, or streaks.
    func generateShareContent(for fix: Fix) -> ShareContent {
        var text = fix.prompt

        if let comment = fix.inlineComment {
            text += "\n\n// \(comment)"
        }

        text += "\n\n— EgoFix"

        return ShareContent(text: text, fixId: fix.id)
    }

    /// Log that a fix was shared.
    func logShare(userId: UUID, fixId: UUID, bugId: UUID?) async throws {
        let now = Date()
        let calendar = Calendar.current

        let event = AnalyticsEvent(
            userId: userId,
            eventType: .fixShared,
            bugId: bugId,
            fixId: fixId,
            dayOfWeek: calendar.component(.weekday, from: now),
            hourOfDay: calendar.component(.hour, from: now),
            timestamp: now
        )

        try await analyticsEventRepository.save(event)
    }
}

struct ShareContent {
    let text: String
    let fixId: UUID
}
