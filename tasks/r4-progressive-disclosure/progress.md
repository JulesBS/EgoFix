# Progress

## Status: Complete

## Completed
1. Created `AppProgressTracker.swift` — @AppStorage-backed service tracking totalFixesCompleted, firstDiagnosticCompleted, firstPatternDetected, daysActive, lastActiveDate; computed unlock states for history (3 fixes), patterns (first detection), bug library (7 fixes), full nav (14 days + 10 fixes); one-time unlock prompt flags
2. Wired unlock triggers into `TodayViewModel` — recordFixCompletion on outcome, recordDayActive on loadHeaderData, recordPatternDetected on pattern surfacing, recordDiagnosticCompleted on diagnostic complete
3. Created `AppNavigation.swift` — AppDestination enum, AppNavBar (monospaced text: today/history/patterns/···), OverflowMenu (bug library/docs/settings), FooterLinks (progressive unlock prompts + persistent compact links), UnlockPromptView (animated slide-up + fade-in)
4. Updated `TodayView.swift` — accepts progressTracker + factory closures for History/Patterns/BugLibrary; footer links in done-for-today state; nav bar at bottom when full nav unlocked; navigationDestination for all AppDestination cases
5. Updated `ContentView.swift` — @StateObject AppProgressTracker; passes tracker to TodayView; factory methods for HistoryViewModel, PatternsViewModel, BugLibraryViewModel (with all required services: StatsService, TrendAnalysisService, BugLifecycleService)
6. Created `SettingsView.swift` — terminal-style settings: about section (version/fixes/days), feature unlock status, danger zone with reset-all-data confirmation dialog
7. Created `AppProgressTrackerTests.swift` — 12 tests covering all unlock thresholds, recording actions (fix/pattern/diagnostic/day), one-time prompt visibility, edge cases
8. Build: 0 errors, 358/359 tests pass (1 pre-existing flaky TemporalCrashDetectorTests)

## What Changed
- `TodayView` init now requires `progressTracker: AppProgressTracker` and optional factory closures for `makeHistoryViewModel`, `makePatternsViewModel`, `makeBugLibraryViewModel` (breaking change for callers)
- `TodayViewModel` init accepts optional `progressTracker: AppProgressTracker?`
- `ContentView` creates `@StateObject AppProgressTracker` and wires it through
- New files: `AppProgressTracker.swift`, `AppNavigation.swift`, `SettingsView.swift`, `AppProgressTrackerTests.swift`

## Decisions
- Used @AppStorage (UserDefaults) for all progress tracking — avoids SwiftData queries on every launch
- Nav bar uses pure text labels (today/history/patterns/···) per plan — no SF Symbols
- Overflow menu uses popover presentation for compact display
- SettingsView reset clears UserDefaults flags but does NOT delete SwiftData records (that would require repository access; kept minimal per plan)
- Footer links and nav bar coexist — footer links are always in done-for-today, nav bar is a separate bottom bar for quick switching

## Issues
- Pre-existing: `TemporalCrashDetectorTests` is flaky (not R4-related)
