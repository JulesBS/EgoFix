# Progress

## Status: Complete

## Completed
1. **Soul reactions to outcomes** — Added `SoulReaction` enum (`.applied`, `.failed`) to BugSoulView. Applied: soul shifts one intensity level quieter for 2 seconds + brightness pulse (opacity flash to 1.0). Failed: soul shifts one intensity level louder for 2 seconds + glitch flicker (rapid horizontal jitter, 6 steps at 50ms). Skipped: no reaction. Added `BugIntensity.quieter`/`.louder` computed properties. Wired through TodayViewModel (`soulReaction` published property set in `markOutcome`).
2. **Fix card entrance animation** — FixCardView already had opacity+offset entrance (.easeOut 0.4s). Added `.transition(.move(edge: .bottom).combined(with: .opacity))` so fix card slides up from below soul when state changes.
3. **State transition orchestration** — Added `stateKey` computed property to `TodayViewState` for stable animation identity. Main content area animates between states with `.easeOut(duration: 0.25)`. Individual states have appropriate transitions: fixAvailable slides up, completed fades, doneForToday fades, pattern slides up.
4. **Diagnostic inline transitions** — Bug-to-bug progression animates on `diagnosticBugIndex` change. Diagnostic and diagnosticComplete states use opacity transitions.
5. **Pattern alert animations** — PatternAlertView now slides up from below (offset +40 → 0, was -50 → 0). Added background card styling and single border pulse in severity color (pulses once then fades). Existing shake effect preserved.
6. **Crash sheet styling** — Red-tinted background (`Color.red.opacity(0.03)` over black). Staggered bug list appearance (50ms per item cascade). Brief red flash overlay on crash logged (0.1 opacity for 100ms, then fade). Soul appears instantly at loud intensity (no gentle fade). Message and done button appear after flash clears.
7. **Unlock moment animations** — `UnlockPromptView` now uses `TypewriterText` for comment (types at 0.025s/char). Link fades in 0.5s after typing completes. No longer uses simple opacity fade-in.
8. **Custom navigation back button** — Created `TerminalBackButton` ViewModifier: hides default iOS back chevron, shows `[ ← today ]` in monospaced gray. Applied to all destination views (History, Patterns, Bug Library, Docs, Settings).
9. **Cursor blink** — TypewriterText cursor now blinks with 0.5s on/off cycle (was always visible). Blinks during and after typing.
10. **Button press feedback** — ActionButton now inverts colors on press: colored background with black text (was subtle background highlight). No scale animation — just a color flash.
11. **Boot sequence transition** — Already implemented in ContentView with `.easeOut(duration: 0.3)` cross-fade.
12. **Build**: 0 errors, 358/359 tests pass (1 pre-existing flaky TemporalCrashDetectorTests)

## What Changed
- `BugSoulView.swift` — Added `SoulReaction` enum, `reaction` parameter, internal state for reaction timing (brightness pulse, glitch offset, intensity override)
- `WeeklyDiagnostic.swift` — Added `BugIntensity.quieter` and `.louder` computed properties
- `TodayViewModel.swift` — Added `soulReaction` published property, set in `markOutcome()`. Added `TodayViewState.stateKey` for animation identity.
- `TodayView.swift` — Passes `soulReaction` to BugSoulView. State transitions animated via `.animation(.easeOut, value: stateKey)`. Individual content sections have `.transition()` modifiers. Diagnostic animates on bugIndex change. Destinations use `.terminalBackButton()`.
- `FixCardView.swift` — ActionButton press feedback: color inversion (colored bg + black text on press)
- `PatternAlertView.swift` — Slides from below (+40 offset), background card styling, single border pulse in severity color
- `CrashView.swift` — Red-tinted background, staggered bug list (50ms cascade), red flash overlay on logged, soul appears instantly, content delayed
- `AppNavigation.swift` — Added `TerminalBackButton` ViewModifier with `[ ← today ]`. `UnlockPromptView` now uses TypewriterText + delayed link fade-in.
- `TypewriterText.swift` — Cursor blinks 0.5s on/off cycle

## Decisions
- Soul reaction is a one-shot: parent sets it, internal state manages 2-second duration and auto-reset
- `SoulReaction` is a top-level enum (not nested in BugSoulView) to avoid View→ViewModel coupling
- Glitch effect uses horizontal offset jitter rather than frame rate manipulation (simpler, works with TimelineView)
- Pattern alert slides up from below (not down from above) to match fix card entrance direction
- No `TransitionCoordinator` class — inline `withAnimation` + `DispatchQueue.asyncAfter` keeps it simple
- All animation durations: 0.15-0.35s for transitions, 2.0s for soul reactions, 0.05s per glitch step
- No spring/bounce anywhere

## Issues
- Pre-existing: `TemporalCrashDetectorTests` is flaky (not R6-related)
- 80 Swift 6 Sendable warnings (pre-existing, not R6-related)
