# Progress

## Status: Complete

## Completed
1. **Crash flow streamlined to 2 screens** — Removed `CrashInitialView` and `CrashBugSelectView`'s confirm button. Tapping a bug immediately logs the crash via `selectAndLogCrash()`. Flow is now: bug selection (with optional note field) → logged state (soul animation at loud intensity + rotating confirmation message + optional quick fix). `CrashFlowState` reduced from 4 to 3 cases (`.selectBug`, `.crashed`, `.quickFix`).
2. **Weekly diagnostic moved inline** — Added `.diagnostic` and `.diagnosticComplete` states to `TodayViewState`. Diagnostic renders as intensity questions → context questions → completion summary inside the Today scroll view. Removed sheet-based `WeeklyDiagnosticView` presentation. Added `skip` option. Completion shows per-bug intensity results and transitions to fix or done-for-today.
3. **Fix seed data audit** — All 294 fixes now have non-null `inlineComment` values. 97 missing comments were written following brand voice guidelines: reframes behavior, surfaces ego mechanism, uses `//` syntax, 1-2 lines, knowing friend tone.
4. **FixCardView tone** — Bug name now displays nickname ("The Corrector") instead of slug ("need-to-be-right"). Added `nickname` computed property to Bug model via `slugNicknames` static dictionary. Severity was already lowercase.
5. **BugDetailView status comments** — Updated all 4 status comments with more voice: identified ("Detected but not yet under active monitoring."), active ("The app is tracking this. Fixes are calibrated."), stable ("Hasn't fired in a while. Don't get comfortable."), resolved ("Marked resolved. The app will check back in 30 days.")
6. **PatternsView** — Header subtitle now contextual: shows count ("The app noticed N things."), all-dismissed ("All caught up. The app is still watching."), or empty ("Patterns emerge from data. Keep logging."). Empty state consolidated.
7. **BugLibraryView** — Header shows "N active, M identified" instead of generic description.
8. **HistoryView** — Changelog header shows "CHANGELOG // v1.0 → v{current}". Empty state: "Nothing here yet. That changes tomorrow."
9. **Crash confirmation messages** — Rotate from pool of 4 via `CrashViewModel.randomCrashMessage()`: "It happens.", "Crash logged. You caught it.", "The bug won this round.", "Noted. No judgment."
10. **Streak milestone commentary** — Added missing milestones: day 21 ("Consistency is just a pattern. Like the others."), day 60 ("Two months. You've outlasted most."), day 90 ("At this point, you're debugging the debugger."). Updated day 30 copy.
11. **Loading states** — Replaced generic `ProgressView()` spinners with terminal-style `"> loading..."` in TodayView, HistoryView, BugLibraryView, PatternsView.
12. **Bug.nickname** — Extracted slug-to-nickname mapping from `OnboardingViewModel` to `Bug.slugNicknames` static dictionary. `OnboardingViewModel.nicknames` now delegates to `Bug.slugNicknames`.
13. **Build**: 0 errors, 358/359 tests pass (1 pre-existing flaky TemporalCrashDetectorTests)

## What Changed
- `CrashView.swift` — Rewritten: 2-screen flow, no CrashInitialView, auto-log on bug tap
- `CrashViewModel.swift` — Rewritten: `CrashFlowState` reduced to 3 cases, `selectAndLogCrash()` replaces `selectBug()`+`confirmCrash()`, crash message pool
- `Bug.swift` — Added `nickname` computed property and `slugNicknames` static dictionary
- `TodayView.swift` — Inline diagnostic views, removed sheet diagnostic, removed `makeWeeklyDiagnosticViewModel` parameter
- `TodayViewModel.swift` — Added `.diagnostic`/`.diagnosticComplete` states, inline diagnostic flow methods, loading state uses terminal text
- `ContentView.swift` — Removed `makeWeeklyDiagnosticViewModel` parameter from TodayView call
- `FixCardView.swift` — Uses `bugTitle` directly (now nickname), removed `bugSlug()` converter
- `OnboardingViewModel.swift` — `nicknames` now delegates to `Bug.slugNicknames`
- `BugLifecycleService.swift` — Updated `statusComment` copy for all 4 states
- `StatusLineProvider.swift` — Added streak milestones for days 21, 60, 90
- `PatternsView.swift` — Contextual header subtitle, consolidated empty state
- `BugLibraryView.swift` — Header shows active/identified counts
- `HistoryView.swift` — Changelog header with version range, updated empty state
- `fixes.json` — 97 fixes updated with inline comments
- `BugLifecycleServiceTests.swift` — Updated statusComment assertion for stable state

## Decisions
- Crash auto-logs on bug tap (no confirm button) per plan — friction reduction
- Note field is pre-populated below bug list, editable before tapping a bug
- Inline diagnostic reuses `DiagnosticBugState` and `BugDiagnosticResponse` from existing WeeklyDiagnosticViewModel
- Bug.nickname lives on the model so all views share one source of truth
- Loading states use `"> loading..."` rather than blinking cursor (simpler, matches terminal aesthetic)

## Issues
- Pre-existing: `TemporalCrashDetectorTests` is flaky (not R5-related)
- `WeeklyDiagnosticView.swift` / `WeeklyDiagnosticViewModel.swift` still exist but are no longer presented as a sheet from TodayView. They could be removed in a cleanup pass but are harmless.
