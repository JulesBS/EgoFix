# EgoFix — UI/UX Design Review

> Reviewer's brief: judge EgoFix against a design-award bar (Apple Design Awards / Awwwards),
> with the heaviest weight on first-run onboarding and overall UI/UX craft.
> This was a static read of the SwiftUI implementation (no device run available in this
> environment). Findings cite `file:line`. Severity: **Blocker** (a jury will mark it down),
> **Major** (visible craft gap), **Minor** (polish).

---

## Verdict in one paragraph

EgoFix has a genuinely award-*worthy core idea and a first-run sequence to match*: ego defenses
reframed as bugs, diagnosed not by a checkbox questionnaire but by a choreographed "awakening"
— a 3D ASCII "soul" that orbits, then **splits on the word "bugs"** — followed by scenario-based
self-diagnosis, reframe beats, and a bento "patterns detected" reveal with animated signal-strength
bars. The concept and the motion direction are the strongest assets and clear the Innovation and
Interaction bars. What stands between this and an actual award is **craft consistency and
inclusivity**: Dynamic Type is broken in the hero copy, there is *zero* Reduce Motion handling in
an app that is almost entirely motion, several contrast and hit-target choices fail Apple's own
guidelines, and the design system leaks (hardcoded status colors, two SF Symbols inside an
otherwise strict ASCII aesthetic, a corner-radius inconsistency). None of these are architectural;
they are a focused, finishable punch-list. The app is ~80% of the way to award-grade. The last 20%
is accessibility and token discipline.

---

## What is already award-caliber (protect these)

1. **The awakening sequence** (`OnboardingView.swift:155-330`). The pacing is deliberate and
   literary: paired action/justification lines ("It learned to correct people / so you'd never be
   wrong."), the justification lines rendered dimmer (`lineColor`, `:255-262`) as the ego's quiet
   excuses, then the single naming beat where "bugs" glitches and the soul splits with a medium
   haptic and a green screen-flash (`:302-313`). This is the kind of moment juries quote.
2. **Diagnosis by scenario, not survey** (`ScenarioPhaseView`, `:336-477`). Picking how you'd react
   to a situation — and watching specific cubes in the soul flicker in response
   (`cubeIndicesForOption` → `setCubeFlickerTarget`, `:54-55`) — turns self-assessment into something
   that feels like the app is *reading* you. Far above a Likert scale.
3. **The bento reveal** (`BugDiagnosticTile`, `:700-803`). "STATUS / NODE 01", animated match-score
   bars, HIGH/MED/LOW signal labels, per-bug accent color. It earns the "diagnostic readout"
   metaphor instead of just claiming it.
4. **The committing terminal** (`CommittingPhaseView`, `:807-926`). Staggered `SYS:` lines with
   PENDING→OK, a success border-flash, an error shake with retry. The app stays in character even
   during a loading state — most apps drop a spinner here.
5. **Restraint in motion vocabulary.** No spring/bounce anywhere (confirmed across the codebase),
   `.easeOut` for reveals, consistent 0.2–0.4s transition band. The motion has a point of view.
6. **The ambient soul on Today** (`TodayView.swift:32-56`): the same creature that named your bug
   now breathes behind the daily screen at 8–18% opacity scaled by intensity, correctly
   `accessibilityHidden`. Quiet, coherent, on-theme.

> Note: the shipped onboarding (awakening → scenario → reframe → reveal → committing) has moved
> **past** what `CLAUDE.md` and `tasks/r3-onboarding-rewrite` describe (a yes/sometimes/rarely
> scan). The docs are stale; the code is better than the docs. Update `CLAUDE.md` so the
> award submission narrative matches what actually ships.

---

## Blockers — a jury *will* mark these down

### B1. Dynamic Type is broken in the hero copy
The most-read text in the app uses fixed point sizes and will not scale for users who set larger
text:
- Scenario situation: `font: .system(size: 18, weight: .light, design: .monospaced)`
  (`OnboardingView.swift:388`)
- Bug name in the reveal tile: `.system(size: 18, ...)` (`:727`)
- Reframe line + `//` prefix: `.system(size: 16, ...)` (`:498`, `:505`)
- Active-fix prompt: 18pt fixed (`FixActiveView.swift:64`); large outcome/ASCII numerals at 28/48pt
  (`TodayView.swift:523`, `:687`).

`EgoTheme.heading(_ size:)` (`EgoTheme.swift:65-67`) bakes in a fixed size and is the root enabler.
**Fix:** route hero text through `EgoTheme.mono(.title3/.body)` (which use scalable text styles),
and replace `heading(size:)` with a `@ScaledMetric`-backed variant or text-style mapping. This is
the single most-cited accessibility miss and the easiest to lose "Inclusivity" on.

### B2. Zero Reduce Motion support in an almost-entirely-motion app
There is **no** `@Environment(\.accessibilityReduceMotion)` check anywhere. The boot typewriter,
glitch, scanlines, soul orbit/split/flicker, button pulses, streak tick-up, pattern shake, and crash
flash all run unconditionally. A motion-sensitive juror turning on Reduce Motion is a standard ADA
test pass; today they get the full show. **Fix:** read the environment once, and when set: cut
typewriter to instant text, skip glitch/flash/shake/pulse, and freeze the soul to a single
representative frame (the soul system is frame-based, so this is a clean swap).

### B3. The onboarding hero has no failure fallback
`onRendererFailed` sets `rendererFailed = true` (`OnboardingView.swift:199`) but **nothing reads it**
(`grep` confirms `:15`, `:39`, `:131`, `:199` only). If `MTLCreateSystemDefaultDevice()` /
`OnboardingSoulRenderer(...)` returns nil (`OnboardingSoulView.swift:35`), the centerpiece becomes a
silent 280pt black square and the narrative plays on around a void. Low probability on modern
hardware, but it is the make-or-break first impression and the demo could be filmed anywhere.
**Fix:** when `rendererFailed`, swap in a static `BugSoulView`/ASCII fallback so the awakening still
reads.

### B4. Near-invisible primary affordance
The reframe "// tap to continue" hint is `EgoTheme.textMuted.opacity(0.3)` (`OnboardingView.swift:529`)
— roughly 1.2:1 on the dark background, effectively unreadable. It is the only signal that the user
can advance. **Fix:** raise to full `textMuted` (and gate its blink on Reduce Motion).

### B5. Sub-44pt hit targets on real controls
Text-only `[ back ]` buttons with no padding (`OnboardingView.swift:354-358`,
`FixActiveView.swift:263-267`) and the counter `[ - ]` (`CounterInteractionView`, 6pt vertical
padding) fall well under Apple's 44×44pt minimum. **Fix:** add `.contentShape(Rectangle())` + a
`.frame(minHeight: 44)` (or padding) without changing the visual glyph.

---

## Major — visible craft gaps

### M1. The design system leaks status colors everywhere
`.red` / `.yellow` / `.green` are hardcoded for severity/status across StatsDashboard (`:21,36,43,51,57`),
ActivityCalendar legend (`:88-90`), BugLibrary badges (`:67-69`), BugDetail status (`:113-122`),
WeeklyDiagnostic (`:23,76-78`), WeeklySummary, the IntensityButton, and most interaction views.
`EgoTheme` has no `statusGood/statusWarning/statusAlert` (and no red token at all). **Fix:** add the
three status tokens to `EgoTheme` and replace the literals. One afternoon; removes a whole class of
drift and makes "red" tunable.

### M2. Two SF Symbols break the ASCII contract
`Image(systemName: "checkmark.circle.fill")` appears in `MultiStepInteractionView:132` and
`TimedInteractionView:110`. CLAUDE.md's rule is ASCII (`[ x ]`, `✓`) over SF Symbols, and the rest of
the app honors it. In a strict terminal aesthetic, one rounded glyph reads as a seam. **Fix:** ASCII
checkmark.

### M3. Corner-radius inconsistency
`.interactionCard()` uses `cornerRadius(4)` while the convention (and `glassCard()` at
`EgoTheme.swift:90`) is 1–2pt; `CounterInteractionView:55` also uses 4. Minor in isolation, but
brutalist work lives or dies on this kind of consistency. **Fix:** standardize to 2pt.

### M4. Translucency with no Reduce Transparency fallback
`glassCard()` layers `.ultraThinMaterial.opacity(0.3)` over `glass.opacity(0.5)`
(`EgoTheme.swift:87-88`) and never checks `\.accessibilityReduceTransparency`. **Fix:** swap to a
solid `surface` fill when the setting is on.

### M5. Muted text contrast sits at the floor
The sage `textMuted` (#84967E) on #131313 is ~3.8:1 — passes AA for large text, fails AAA and is
borderline for the small `//` comment captions that carry much of the app's voice. Not a blocker,
but "Visuals" juries notice strained legibility. Consider nudging the token ~10% lighter, or
reserving the dimmest variant for genuinely decorative text only.

### M6. VoiceOver gaps on signature elements
The soul as a *content* element (BugLibrary/BugDetail) has no label; body/region chips lack
`.accessibilityValue` for selected state; counters/timers lack `.accessibilityValue`. (The Today
ambient soul is correctly hidden — that part is right.) **Fix:** label the soul as
"Bug: {slug}, intensity {level}" where it carries meaning, and add selection/value to stateful
controls.

---

## Minor — polish

- **Auto-advance on reframe** (`:513-518`) moves users through meaningful copy on a timer. Reading
  speed varies; consider tap-only, or a longer floor, so no one feels the screen yanked away.
- **Duration drift:** counter animates at 0.1s vs the 0.2s standard elsewhere — unify the
  interaction-feedback band.
- **`DispatchQueue.asyncAfter` sequencing chains** (PatternAlert `:68-81`, BugSoul reactions,
  Crash flow) work but are fragile under load; the newer onboarding code already uses structured
  `Task`/`await` — bring the older views in line.
- **Scanline overlay** isn't marked `.accessibilityHidden(true)` (decorative).
- Decorative ASCII brackets (`[ ... ]`) are read literally by VoiceOver in a few buttons; fine, but
  custom labels would clean it up.

---

## Prioritized path to award-grade

**Phase A — Inclusivity (unlocks the "Inclusivity" category; removes the disqualifiers).**
B1 Dynamic Type, B2 Reduce Motion, B4 contrast hint, B5 hit targets, M4 Reduce Transparency,
M6 VoiceOver values. This is the highest-leverage work and the difference between "beautiful demo"
and "award entry."

**Phase B — Token discipline (tightens "Visuals & Graphics").**
M1 status color tokens, M2 ASCII glyphs, M3 corner radius, M5 muted-text contrast tune.

**Phase C — Resilience & docs.**
B3 renderer fallback, minor motion/timing cleanup, and refresh `CLAUDE.md`/`tasks` so the submission
narrative matches the shipped scenario-based onboarding.

**Phase D — Submission craft (not code).**
Capture the awakening→split→reveal as the hero reel; lead the submission with Innovation +
Interaction (the soul and the diagnosis), and cite the Inclusivity work from Phase A. The story is
already strong; Phase A is what lets you tell it without an asterisk.

---

## Bottom line

The idea, the writing, and the onboarding choreography are good enough to win on. The reasons it
wouldn't *today* are accessibility and a handful of system-discipline leaks — all finishable without
touching the architecture. Do Phase A and B and this is a credible Apple Design Award entry in the
Innovation / Interaction / Inclusivity conversation.
