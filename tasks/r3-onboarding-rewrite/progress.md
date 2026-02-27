# Progress

## Status: Complete

## Completed
1. Created `TypewriterText.swift` — character-by-character text animation with configurable speed, color, font, optional cursor, and completion callback
2. Created `GlitchText.swift` — briefly corrupts a specific word with random characters before resolving to correct text
3. Rewrote `BootSequenceView.swift` — first launch: ~8-second narrative typewriter sequence with "ego" glitch + `[ Begin scan ]` button; subsequent launches: abbreviated 2-second `> ego detected.` glitch + `> resuming...`; includes `GlitchTypewriterLine` combo component for type-then-glitch
4. Rewrote `OnboardingViewModel.swift` — new state machine (boot → scanning(bugIndex) → moreDetected → confirmation → committing); BugResponse enum (yesOften=3, sometimes=2, rarely=1); response tracking; weighted sorting with tie-breaking by canonical slug order; activeBugs/deprioritizedBugs computed; nicknames + inline comments for all 7 bugs; commitConfiguration saves priorities and activates bugs
5. Rewrote `OnboardingView.swift` — BugScanCardView (soul animation + nickname + full description + inline comment + 3 response buttons), MoreDetectedView ("2 more patterns detected..." pause with continue button), ScanConfirmationView (top 3 with small souls + response labels + deprioritized count + commit button); all transitions animated
6. Updated `ContentView.swift` — passes `isFirstLaunch` to BootSequenceView; added `@AppStorage("hasCompletedOnboarding")`; handles 3 states: first launch (boot → scan), incomplete onboarding (scan only), returning user (TodayView); calls `beginScan()` after boot completes
7. Rewrote `OnboardingViewModelTests.swift` — 19 tests covering: state machine (initial/beginScan/respond/moreDetected/continue/confirmation), response weighting, tie-breaking by original order, all-rarely edge case, deprioritized exclusion, commit flow (activation + user creation + priorities), onboarding check, nicknames, inline comments, response labels, no-bugs edge case, fewer-than-5-bugs skip
8. Added canonical slug ordering in `loadBugs()` so bug display order is deterministic regardless of repository implementation
9. Build: 0 errors, 346/347 tests pass (1 pre-existing flaky TemporalCrashDetectorTests)

## What Changed
- `BootSequenceView` now takes `isFirstLaunch: Bool` parameter (breaking change for callers)
- `OnboardingViewModel` no longer has `currentStep`, `availableBugs`, `rankedBugs`, `showingAllBugs`, `hasMoreBugs` — replaced by `state: OnboardingState`, `responses: [UUID: BugResponse]`, `allBugs: [Bug]`
- `OnboardingView` no longer has `WelcomeStepView`, `BugRankingView`, `ReorderableList`, `BugRowView`, `PriorityConfirmationView` — replaced by `BugScanCardView`, `MoreDetectedView`, `ScanConfirmationView`
- Old `OnboardingStep` enum replaced by `OnboardingState` enum
- New `BugResponse` enum added at module level
- `ContentView` added `@AppStorage("hasCompletedOnboarding")` tracking

## Decisions
- Kept glitch effect inline in BootSequenceView via `GlitchTypewriterLine` rather than using the standalone `GlitchText` component, since the type-then-glitch combo requires different state management
- Canonical slug ordering hardcoded in ViewModel to ensure consistent display order
- Boot sequence is not skippable on first launch (per plan)
- "2 more detected" pause only triggers when there are more than 5 bugs
- All 7 bugs get BugPriority entries on commit (not just top 3) — this ensures DailyFixService weighted selection works across all bugs

## Issues
- Pre-existing: `TemporalCrashDetectorTests` is flaky (not R3-related)
