import Foundation

/// A single data point in a trend
struct TrendDataPoint: Identifiable {
    let id: Date
    let value: Double  // 0 = quiet, 1 = present, 2 = loud (for intensity) or percentage for rates
    let label: String?

    init(id: Date = Date(), value: Double, label: String? = nil) {
        self.id = id
        self.value = value
        self.label = label
    }
}

/// Direction of a trend
enum TrendDirection {
    case improving
    case worsening
    case stable

    var label: String {
        switch self {
        case .improving: return "IMPROVING"
        case .worsening: return "WORSENING"
        case .stable: return "STABLE"
        }
    }

    var comment: String {
        switch self {
        case .improving: return "// Keep it up"
        case .worsening: return "// Worth attention"
        case .stable: return "// Holding steady"
        }
    }
}

/// Trend data for a specific bug
struct BugTrendData: Identifiable {
    let id: UUID  // bugId
    let bugName: String
    let dataPoints: [TrendDataPoint]
    let trendDirection: TrendDirection

    /// Calculate trend direction from data points
    static func calculateDirection(from points: [TrendDataPoint]) -> TrendDirection {
        guard points.count >= 2 else { return .stable }

        let recentCount = min(4, points.count)
        let recentPoints = points.suffix(recentCount)
        let olderPoints = points.prefix(recentCount)

        let recentAvg = recentPoints.map(\.value).reduce(0, +) / Double(recentPoints.count)
        let olderAvg = olderPoints.map(\.value).reduce(0, +) / Double(olderPoints.count)

        let diff = recentAvg - olderAvg

        if diff < -0.3 {
            return .improving  // Lower intensity = improvement
        } else if diff > 0.3 {
            return .worsening
        }
        return .stable
    }
}

/// Intensity level for weekly diagnostics (matches WeeklyDiagnostic model)
enum IntensityLevel: Double {
    case quiet = 0
    case present = 1
    case loud = 2

    var label: String {
        switch self {
        case .quiet: return "quiet"
        case .present: return "present"
        case .loud: return "loud"
        }
    }
}
