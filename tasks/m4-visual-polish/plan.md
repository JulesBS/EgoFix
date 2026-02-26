# Task: M4 — Visual Polish

**Status**: Active
**Branch**: m4-visual-polish
**Goal**: Make EgoFix feel like a terminal. Boot sequence, scanlines, glows, ASCII art, transitions, and micro-interactions. The app should feel like software debugging yourself.

## Context

M0–M3 complete. All features work. The app uses monospaced fonts and black backgrounds but currently feels like a standard dark-mode app. M4 transforms it into the brutalist IDE aesthetic described in CLAUDE.md. Read CLAUDE.md for the full design system spec.

**Design language reminder:**
- Background: Pure black
- Text: White primary, gray secondary
- Fonts: Always monospaced
- Colors: Green (success), Yellow (warning), Red (error/failure)
- Accent colors: Cyan, Mint, Indigo, Pink, Teal for interaction types
- Corners: Minimal rounding (2-4pt)
- Never: Gradients, soft colors, nature imagery, wellness aesthetic, emojis

## Phases

### Phase 1: Boot Sequence
On first launch (after onboarding completes, or on subsequent app opens), show a brief terminal-style boot sequence before the main UI appears. 2-3 seconds max.

```
EgoFix v1.0
Loading modules...
[################] bugs.db
[################] fixes.db
[################] patterns.db
System ready.
> _
```

- Monospaced text appearing line-by-line with slight delays
- Green text on black background
- Progress bars animate left-to-right
- Blinking cursor at the end
- Fade/cut to main UI after cursor blinks twice
- Only show on cold launch, not tab switches
- Store "hasSeenBoot" so it's a quick flash on subsequent launches (not full sequence)

New file: Views/Components/BootSequenceView.swift
Modify: ContentView.swift (show boot before main content), EgoFixApp.swift if needed

### Phase 2: Scanline & CRT Effect
Add a subtle scanline overlay that gives the whole app a CRT monitor feel.

- Very subtle horizontal lines (opacity 0.03-0.05) across the entire screen
- Optional: very slight screen curvature/vignette at edges (dark corners)
- This should be a reusable overlay modifier that can be applied to any view
- Performance: use a pre-rendered image or simple repeating pattern, not per-frame drawing
- Must not interfere with touch targets or readability

New file: Views/Components/ScanlineOverlay.swift (or a ViewModifier)
Modify: ContentView.swift (apply overlay to main content)

### Phase 3: Glow Effects
Add subtle glow effects to key interactive elements:

- Green glow on the primary action buttons (Applied, Continue, etc.)
- Red glow on the crash button [ ! ]
- Severity-colored glow on pattern alert cards
- Cursor/blinking effect on text input fields (journal, observation)
- Glow should be subtle — just a shadow with color, not a neon sign
- Use `.shadow(color:radius:)` with low radius (3-5pt)

Modify: FixCardView.swift (action buttons), CrashView.swift, PatternAlertView.swift, journal/observation interaction views

### Phase 4: ASCII Art for Bug Views
Each of the 7 bugs gets a small ASCII art representation shown in the bug library and bug detail views. These should feel like terminal art — simple, monospaced, evocative.

Examples (create your own, these are just direction):
- Need to be right: a pointing finger or exclamation mark
- Need to impress: a peacock or spotlight
- Need to be liked: a mirror or mask
- Need to control: a puppet strings or grid
- Need to compare: a scale/balance
- Need to deflect: a shield or arrow bouncing
- Need to narrate: a speech bubble or microphone

Keep them small (5-8 lines, 20-30 chars wide). Store as string constants.

New file: Views/Components/BugASCIIArt.swift (enum or struct with art per bug slug)
Modify: BugLibraryView.swift, BugDetailView.swift (display the art)

### Phase 5: Transitions & Micro-interactions
Add polish to state changes throughout the app:

- **Tab transitions**: Subtle fade when switching tabs (not the default iOS slide)
- **Fix card appearance**: Slide up or typewriter-style reveal when today's fix loads
- **Outcome marking**: Brief flash of outcome color (green/yellow/red) when user marks applied/skipped/failed
- **Completion view**: Text appears with typing animation (letter by letter for the outcome message)
- **Pattern alert**: Slides in from top with a brief shake/pulse
- **Streak counter**: Number ticks up with a brief scale animation when incrementing
- **Crash button**: Subtle pulse animation (scale 1.0 → 1.05 → 1.0, repeating slowly)

Use SwiftUI `.transition()`, `.animation()`, `withAnimation {}`, and `matchedGeometryEffect` where appropriate. Keep animations fast (0.2-0.4s) and crisp — no bouncy/spring physics.

Modify: TodayView.swift, FixCardView.swift, CompletionView.swift, PatternAlertView.swift, StreakCardView.swift, CrashView.swift, ContentView.swift (tab bar)

### Phase 6: Typography & Spacing Audit
Review every view for consistency with the design system:

- Every text element uses `.system(.size, design: .monospaced)` — no exceptions
- Check for any default system fonts that slipped through
- Consistent spacing: 16-24pt padding
- Consistent corner radius: 2-4pt (no rounded corners > 4pt)
- Color consistency: verify green/yellow/red usage matches outcome semantics everywhere
- Remove any leftover default iOS styling (blue tints, rounded rects, etc.)
- Tab bar matches the terminal aesthetic (already partially styled)

Audit all view files. Fix any inconsistencies found.

### Phase 7: Tests & Verification
- Verify boot sequence doesn't break app launch flow
- Verify scanline overlay doesn't block interactions
- Verify animations don't cause layout issues
- Run full test suite — all must pass
- Build project — 0 errors
- Test on iPhone simulator to verify visual appearance

## Acceptance Criteria
- [ ] Boot sequence plays on launch (2-3s terminal animation)
- [ ] Scanline overlay visible across all screens (subtle, not distracting)
- [ ] Glow effects on action buttons and crash button
- [ ] ASCII art for all 7 bugs in bug library/detail views
- [ ] Smooth transitions between states (fix loading, outcome marking, completion)
- [ ] Typing animation on completion message
- [ ] Crash button has pulse animation
- [ ] All text is monospaced — zero exceptions
- [ ] All corners ≤ 4pt radius
- [ ] No gradients, no soft colors, no wellness aesthetic anywhere
- [ ] All existing tests still pass
- [ ] Project builds with 0 errors
