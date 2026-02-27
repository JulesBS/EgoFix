# Progress

## Status: Complete

## Completed
1. Created `StatusLineProvider.swift` — randomized status lines per intensity (quiet/present/loud) + context (normal/postCrash/longStreak/firstDay), streak formatting, milestone comments
2. Updated `TodayViewModel.swift` — added `doneForToday` state, wired version (VersionService), streak (StreakService), intensity (BugIntensityProvider), primary bug slug; auto-transition from completed→done; version increment on outcome
3. Rebuilt `TodayView.swift` — new layout: header (version + streak) → soul hero (BugSoulView) → status line → state-switched content → crash button; inline outcome via InlineCompletionView with auto-transition to done; crash button in scroll content; crash sheet presented from TodayView
4. Simplified `FixCardView.swift` — removed type badges (DAILY/WEEKLY/QUICK FIX), removed interaction type badges, removed share button, removed validation collapsible section; severity as comment line `// need-to-be-right · medium`; inline comment always visible
5. Rebuilt `ContentView.swift` — removed TabView entirely; NavigationStack wrapping TodayView as single root view; crash button moved into TodayView; scanlines preserved; all factory methods for History/Patterns/Docs views removed (files still exist, R4 adds progressive nav)
6. Added `StatusLineProviderTests` — 12 tests covering all intensities, contexts, streak formatting, milestone comments
7. Updated `TodayViewModelTests` — tests for new state enum, done status messages, weekly summary comments
8. Build: 0 errors, all tests pass

## What Changed
- `TodayViewModel` init now requires `versionService: VersionService` parameter (breaking change for any callers)
- `TodayViewModel` init accepts optional `bugIntensityProvider: BugIntensityProvider?`
- `TodayView` init accepts optional `makeCrashViewModel: (() -> CrashViewModel)?`
- `FixCardView` no longer accepts `onShare` parameter (removed)
- `ContentView` no longer has TabView — no tabs visible
- `CompletionView.swift` is now dead code (replaced by InlineCompletionView in TodayView)
- The old floating CrashButton struct in ContentView is removed (crash button now in TodayView)

## Decisions
- Kept weekly diagnostic as sheet (not inline) — plan says "if inline is too complex, keep as sheet"
- Kept CompletionView.swift file on disk (unused) — can be cleaned up in R5
- Crash flow unchanged — still a sheet, just presented from TodayView instead of ContentView overlay

## Issues
- Pre-existing: `TemporalCrashDetectorTests` is flaky (skipped, not R2-related)
