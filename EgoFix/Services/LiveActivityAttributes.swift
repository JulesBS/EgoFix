//
//  LiveActivityAttributes.swift
//  EgoFix
//
//  Shared between main app and widget extension.
//  This file MUST be added to BOTH targets in Xcode.
//

import ActivityKit
import Foundation

/// Attributes for the EgoFix timer Live Activity
/// Used by both the main app (to start/update activities) and the widget extension (to display them)
public struct EgoFixWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var timerEndDate: Date
        public var isPaused: Bool
        public var remainingSeconds: Int
        public var progress: Double

        public init(timerEndDate: Date, isPaused: Bool, remainingSeconds: Int, progress: Double) {
            self.timerEndDate = timerEndDate
            self.isPaused = isPaused
            self.remainingSeconds = remainingSeconds
            self.progress = progress
        }
    }

    // Static attributes that don't change during the activity
    public var fixNumber: String
    public var fixPrompt: String
    public var totalDurationSeconds: Int

    public init(fixNumber: String, fixPrompt: String, totalDurationSeconds: Int) {
        self.fixNumber = fixNumber
        self.fixPrompt = fixPrompt
        self.totalDurationSeconds = totalDurationSeconds
    }
}
