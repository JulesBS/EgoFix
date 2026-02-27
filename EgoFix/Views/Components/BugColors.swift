import SwiftUI

/// Accent colors for each of the 7 ego bugs.
/// Extracted from the old BugASCIIArt so it can be shared across soul views, charts, etc.
enum BugColors {
    static func color(for slug: String) -> Color {
        switch slug {
        case "need-to-be-right":
            return Color(red: 1.0, green: 0.4, blue: 0.3)
        case "need-to-impress":
            return Color(red: 0.6, green: 0.4, blue: 0.8)
        case "need-to-be-liked":
            return Color(red: 0.3, green: 0.8, blue: 0.8)
        case "need-to-control":
            return Color(red: 1.0, green: 0.8, blue: 0.3)
        case "need-to-compare":
            return Color(red: 0.4, green: 0.8, blue: 0.4)
        case "need-to-deflect":
            return Color(red: 0.6, green: 0.6, blue: 0.6)
        case "need-to-narrate":
            return Color(red: 0.3, green: 0.5, blue: 0.8)
        default:
            return .gray
        }
    }
}
