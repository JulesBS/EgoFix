#!/bin/bash
# EgoFix UX Redesign Setup Script
# Run from your EgoFix repo root: bash setup-redesign.sh

set -e

if [ ! -f "CLAUDE.md" ]; then
    echo "ERROR: Run this from your EgoFix repo root (where CLAUDE.md lives)"
    exit 1
fi

echo "Setting up R1-R6 UX redesign files..."

# Create task directories
mkdir -p tasks/r1-soul-system
mkdir -p tasks/r2-today-rebuild
mkdir -p tasks/r3-onboarding-rewrite
mkdir -p tasks/r4-progressive-disclosure
mkdir -p tasks/r5-tone-polish
mkdir -p tasks/r6-transitions

# --- CLAUDE.md ---
cat > CLAUDE.md << 'CLAUDE_EOF'
# EgoFix - Claude Project Guide

> See `egofix-detailed-spec.md` for full model definitions, TDD test plan, detector thresholds, UI copy examples, and content requirements.
> See `egofix-bugs-redesign.md` for the definitive bug list (7 bugs), fix examples by interaction type, and content pipeline targets. This is the source of truth for all bug/fix content.
> See `egofix-ux-redesign.md` for the full UX redesign rationale, diagnosis of current problems, and design principles for the R1-R6 rebuild.

## ⚠️ CURRENT WORK: UX Redesign (R1–R6)

M0–M4 built all features but the experience has no cohesion. The UX redesign rebuilds the **presentation layer** on top of working infrastructure. The data layer, services, repositories, detectors, and interaction types are all solid — don't touch them unless a task plan explicitly says to.

**Active task plans are in `tasks/r{1-6}-*/plan.md`**. Read the relevant plan before starting any redesign work.

### What's Changing
- **ASCII art → Animated souls**: Static `BugASCIIArt.swift` replaced by multi-frame `BugSoulView` with 7 bugs × 3 intensities = 21 animation states
- **Tab bar → Single screen**: `ContentView` TabView removed. Today is the only screen. Navigation reveals progressively.
- **Onboarding → "The Scan"**: Drag-to-rank replaced by one-bug-at-a-time full-screen cards with soul animations and 3-option responses
- **Boot sequence → Narrative**: Generic loading bars replaced by typewriter narrative with ego glitch effect
- **Dead-end completion → Done-for-today state**: Outcome view transitions to a resting hub with soul + status + optional depth
- **Progressive disclosure**: Nothing appears until data justifies it (History at 3 fixes, Patterns at first detection, full nav at day 14+)
- **Crash flow → 2 taps**: Remove intermediate screens, auto-log on bug selection

### What's NOT Changing
- All 18 SwiftData models
- All repository protocols + local implementations + mocks
- All 19 services (DailyFixService, CrashService, VersionService, etc.)
- All 6 pattern detectors
- All 14 interaction type views
- 294 seed fixes (inline comments audited in R5)
- Widget + Live Activity support
- All test infrastructure

### Task Dependency Chain
```
R1 (Soul System) ← no dependencies
    ↓
R2 (Today Rebuild) ← R1
    ↓
R3 (Onboarding Rewrite) ← R1, R2
    ↓
R4 (Progressive Disclosure) ← R2, R3
    ↓
R5 (Tone & Polish) ← R1-R4
    ↓
R6 (Transitions & Feel) ← R1-R5
```

---

## Vision

EgoFix is an iOS app for ego reduction through daily micro-challenges ("fixes"). Users identify their ego "bugs" (e.g., need-to-be-right, need-to-be-liked) and receive daily fixes to work on them. The app surfaces behavioral blind spots through daily challenges, tracks patterns over time, and eventually shows users things about themselves they didn't know.

**Brand voice:** "A smart friend who sees through your shit and likes you anyway." Deadpan, dry, knowing. Never preachy, never gentle, never condescending.

**Design metaphor:** Ego patterns = bugs. Challenges = fixes. Progress = version numbers. Bad days = crashes. The aesthetic is terminal/IDE — monospace fonts, dark mode, muted syntax-highlighting colors. Not a wellness app.

**Engagement philosophy:** Engagement mechanics are the delivery system, not the product. Every mechanic must pass one test: does it deliver the user to a moment of genuine self-awareness? Streaks, notifications, and variable rewards are tools — what matters is what they deliver the user to. We meet users where they are (dopamine-conditioned, notification-saturated) and use that conditioning to create moments of genuine self-awareness.

---

## Tech Stack

- **Language**: Swift 5
- **UI**: SwiftUI with MVVM architecture
- **Persistence**: SwiftData (local-first)
- **Testing**: XCTest
- **Minimum iOS**: 18.0

## Architecture

```
EgoFix/
├── Models/           # SwiftData @Model classes
├── Views/            # SwiftUI views organized by feature
│   ├── Today/        # Daily fix card
│   ├── History/      # Past completions
│   ├── Onboarding/   # Bug selection flow
│   └── Components/   # Reusable UI components
├── ViewModels/       # @Observable view models
├── Services/         # Business logic (DailyFixService, etc.)
├── Repositories/     # Data access layer with protocols
└── Resources/        # SeedData JSON files
```

## Key Patterns

### Repository Pattern
All data access goes through repository protocols for testability:
```swift
protocol FixRepository {
    func getById(_ id: UUID) async throws -> Fix?
    func getForBug(_ bugId: UUID) async throws -> [Fix]
    // ...
}
```

### Service Layer
Services coordinate business logic and use repositories:
```swift
class DailyFixService {
    func assignDailyFix(for userId: UUID) async throws -> FixCompletion
    func markOutcome(_ completionId: UUID, outcome: FixOutcome, outcomeData: Data?) async throws
}
```

### JSON-Encoded Configuration
Complex data stored as `Data?` with typed accessors:
```swift
// Fix model stores configurationData: Data?
var quizConfig: QuizConfig? {
    guard interactionType == .quiz, let data = configurationData else { return nil }
    return try? JSONDecoder().decode(QuizConfig.self, from: data)
}
```

## Design System - Brutalist IDE Aesthetic

- **Background**: Pure black (`Color.black`)
- **Text**: White primary, gray secondary
- **Fonts**: Always monospaced (`.system(.body, design: .monospaced)`)
- **Colors**: Green (success/validation), Yellow (warning), Red (error/failure)
- **Accent colors**: Cyan, Mint, Indigo, Pink, Teal for interaction types
- **Corners**: Minimal rounding (2-4pt)
- **Spacing**: Generous padding (16-24pt)
- **Never**: Gradients, soft colors, nature imagery, wellness aesthetic, emojis in app copy

### Animation Principles
- **Speed**: Fast and crisp (0.15-0.35s). No spring physics, no bounce.
- **Easing**: `.easeOut` or `.linear` — never `.spring` or `.bouncy`
- **Text**: Appears by typing (character by character), not by fading in
- **Transitions**: Opacity + position changes, not scale (terminal text doesn't zoom)
- **The soul is the constant**: It reacts, everything else changes around it. The soul never disappears during transitions.

## Fix Interaction Types

| Type | Description | Config Struct |
|------|-------------|---------------|
| `standard` | Simple prompt | None |
| `timed` | Timer must complete | `TimedConfig` |
| `multiStep` | Sequential steps | `MultiStepConfig` |
| `quiz` | Multiple choice | `QuizConfig` |
| `scenario` | Situation + response | `ScenarioConfig` |
| `counter` | Track occurrences | `CounterConfig` |
| `observation` | Notice something, report back | `ObservationConfig` |
| `abstain` | Go a period WITHOUT doing something | `AbstainConfig` |
| `substitute` | When urge X arises, do Y instead | `SubstituteConfig` |
| `journal` | Short text prompt, 2-3 sentences | None (uses reflection field) |
| `reversal` | Do the opposite of your default | None |
| `predict` | Predict outcome, then observe reality | `PredictConfig` |
| `body` | Notice a physical sensation tied to ego | None |
| `audit` | End-of-day review of behaviors | `AuditConfig` |

## The Seven Ego Bugs

| Slug | Title | Nickname | Color | Soul Visual |
|------|-------|----------|-------|-------------|
| need-to-be-right | Need to be right | The Corrector | Red/orange | Pointing finger / exclamation mark, pulses and jabs |
| need-to-impress | Need to impress | The Performer | Purple/indigo | Spotlight / figure on stage, poses and strobes |
| need-to-be-liked | Need to be liked | The Chameleon | Cyan/teal | Face/mask shifting between expressions, fragments |
| need-to-control | Need to control | The Controller | Yellow/amber | Grid / control panel, switches flipping and warping |
| need-to-compare | Need to compare | The Scorekeeper | Green | Balance scale, tips and rocks with numbers |
| need-to-deflect | Need to deflect | The Deflector | Gray/silver | Shield / arrows deflecting, cracks under barrage |
| need-to-narrate | Need to narrate | The Narrator | Blue/dark blue | Speech bubble, words appear, overflows and spawns |

Each soul has 3 intensity states (quiet/present/loud) with 4-8 animation frames per state. See `BugSoulFrames.swift` for frame data and `egofix-ux-redesign.md` section 3 for design rationale.

See `egofix-bugs-redesign.md` for full descriptions, root mechanisms, daily-life examples, and 100+ fix examples across all interaction types.

---

## Content Tone Rules

- Fixes are specific and observational: "Count how many sentences you start with 'I' today" not "be more humble"
- Inline comments reframe, don't repeat: `// The urge to correct isn't about accuracy. It's about status.`
- Pattern insights feel personal: "You skip listening fixes on days you crash about being right" not "You skipped 4 fixes"
- Post-outcome education explains WHY the pattern exists, not just what to do
- Failure is data, not shame: "No fanfare. You did the thing." / "Crash logged. That's the whole point of logging."

---

## Engagement Features (To Build)

### Streak Counter
- Track consecutive days of engagement
- Display with self-aware comment: `// This metric is meaningless. But you looked anyway.`
- One free streak freeze per week (not monetized, no guilt)
- Breaking a streak = silent reset. No "you lost your streak!" notification.

### Contribution Graph
GitHub-style grid encoding two dimensions:
- **Color = outcome:** Green (applied), Yellow (skipped), Red (crash), Gray outline (opened, no action), Empty (no activity)
- **Intensity = depth:** Darker = high-severity fix, reflection written, crash with note. Lighter = low-severity, quick tap-through.

### Social Sharing
Forward a fix (prompt + inline comment) to a friend with minimal EgoFix watermark. **Never shared:** streak, version, stats, personal data. The share is about the content, not the sender.

### Post-Outcome Education
After marking a fix outcome, show a brief micro-education tidbit explaining WHY the pattern exists. Randomized from a pool per bug.

### Notifications
- Daily: "Fix #042 is ready" (configurable time)
- Anti-notification: After stable period, "Still running smoothly?" — more stability = less contact

---

## Pattern Detection (To Build)

Six detectors, each implementing `PatternDetector` protocol:

| Detector | Trigger |
|----------|---------|
| Avoidance | >50% skip rate on a bug (min 4 skips) |
| Temporal (day) | >40% crashes on same weekday (min 3) |
| Temporal (time) | >50% crashes in same time bucket (min 3) |
| Context Spike | >60% loud responses in one context (min 3) |
| Correlated Bugs | Pearson r > 0.7 over 6+ weeks |
| Plateau | 4+ weeks present/loud despite 6+ fixes applied |
| Improvement | Downward trend ending in quiet over 4+ weeks |

Surfacing: max one pattern per session, same type not within 14 days, priority: alert > insight > observation.

---

## Development Milestones

### M0–M4: Feature Build (Complete)
All features implemented: onboarding, daily fix loop, 14 interaction types, crash flow, version system, streak, weekly diagnostic, pattern detection + surfacing, bug lifecycle, contribution graph, share, boot sequence, scanlines, ASCII art, transitions. 296 tests passing.

### R1–R6: UX Redesign (Active)
See `tasks/r{1-6}-*/plan.md` for detailed plans.

| Phase | Focus | Key Deliverables |
|-------|-------|-----------------|
| R1 | Soul System | `BugSoulFrames`, `BugSoulView`, `BugIntensityProvider`. 21 animation states. |
| R2 | Today Rebuild | Single-screen hub. Version + streak header. Soul as hero. Done-for-today state. Kill tab bar. |
| R3 | Onboarding Rewrite | Boot sequence with typewriter + glitch. "The Scan" — one bug at a time. Direct-to-first-fix. |
| R4 | Progressive Disclosure | `AppProgressTracker`. Footer links unlock over time. Full nav at day 14+. |
| R5 | Tone & Polish | 2-tap crash. Inline diagnostic. Audit all 294 fix comments. Screen-by-screen copy pass. |
| R6 | Transitions | Soul reactions to outcomes. Fix card entrance. State transition choreography. No spring physics. |

### M5: Ship
App icon, first-run polish, edge cases, App Store submission.

---

## Anti-Patterns (Never Build These)

- Badges or achievements
- XP or rank systems
- Social leaderboards
- Friend activity feeds ("3 friends applied fixes today")
- Loot drops / daily spin / random rewards
- Seasonal FOMO events
- Any mechanic that rewards volume of taps over depth of engagement
- "You're doing great!" or any variation

---

## Build & Test Commands

```bash
# Build
xcodebuild -scheme EgoFix -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.0' build

# Run all tests
xcodebuild test -scheme EgoFix -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.0'

# Run specific test class
xcodebuild test -scheme EgoFix -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.0' -only-testing:EgoFixTests/FixConfigurationTests
```

## Testing Conventions

- Test files mirror source structure in `EgoFixTests/`
- Model tests: Direct property assertions
- Service tests: Use mock repositories (many currently skipped pending mocks)
- ViewModel tests: Use `@MainActor` annotation
- Name format: `test_ClassName_behavior_condition()`

## Key Files

| File | Purpose |
|------|---------|
| `Models/Fix.swift` | Core fix model with interaction types |
| `Models/FixConfiguration.swift` | Config structs for each interaction type |
| `Models/FixCompletionData.swift` | Outcome structs for each interaction type |
| `ViewModels/FixInteractionManager.swift` | Manages all interaction type state |
| `Views/Components/FixCardView.swift` | Main fix display card (scrollable) |
| `Views/Components/BugSoulView.swift` | Animated ASCII soul (R1) — replaces BugASCIIArt |
| `Views/Components/BugSoulFrames.swift` | Frame data for 7 bugs × 3 intensities (R1) |
| `Services/BugIntensityProvider.swift` | Determines bug intensity from data (R1) |
| `Services/DailyFixService.swift` | Fix assignment and completion logic |
| `Resources/SeedData/fixes.json` | Seed data for fixes |
| `egofix-ux-redesign.md` | Full UX redesign rationale and plan |
| `egofix-bugs-redesign.md` | Definitive bug list, fix examples, content targets |

## Seed Data Format

```json
{
  "id": "uuid",
  "bugSlug": "need-to-be-right",
  "type": "daily",
  "severity": "medium",
  "interactionType": "quiz",
  "prompt": "Self-assessment",
  "validation": "Select an answer",
  "configuration": {
    "quiz": {
      "question": "What was your instinct?",
      "options": [
        {"id": "a", "text": "Option A", "weightModifier": 1.2, "insight": "..."}
      ]
    }
  }
}
```

## Common Tasks

### Adding a new fix interaction type
1. Add case to `InteractionType` enum in `Fix.swift`
2. Create config struct in `FixConfiguration.swift`
3. Create outcome struct in `FixCompletionData.swift`
4. Add config accessor to `Fix` extension
5. Add outcome accessor to `FixCompletion` extension
6. Handle in `FixInteractionManager.swift`
7. Create view in `Views/Components/Interactions/`
8. Add case to `FixInteractionView.swift` switch
9. Update `canMarkApplied` logic
10. Add tests

### Adding a new bug type
1. Add to `Resources/SeedData/bugs.json`
2. Add related fixes to `Resources/SeedData/fixes.json`

## Notes

- SwiftData models use `@Attribute(.unique)` for IDs
- All async service methods use `async throws`
- Views use `@StateObject` for owned view models
- Timer functionality uses `TimerService` with `TimerSession` model
- Live Activities supported for timer fixes

CLAUDE_EOF

# --- egofix-ux-redesign.md ---
cat > egofix-ux-redesign.md << 'REDESIGN_EOF'
# EgoFix — UX Redesign Plan

> The architecture works. The data layer works. The 294 fixes are solid. What's missing is the *experience*. This document redesigns the user journey from first launch through the first month, transforms the ASCII art into living animated souls, and creates a progressive disclosure system that makes the app feel like it's revealing itself over time.

---

## 1. DIAGNOSIS: What's Actually Wrong

### 1.1 No Narrative Arc
The app currently dumps users from onboarding directly into a tab bar with four equally-weighted destinations. There's no sense of "you are here" or "here's what happens next." The Today view is a floating card with no context. The completion screen is a dead end. Every session feels the same.

### 1.2 The ASCII Animations Don't Exist
The spec described "animated visualizations that serve as visual souls responding to intensity levels." What shipped is `BugASCIIArt` — static string constants rendered at 10pt font, buried in the Bug Library view (which is itself behind Docs → Bug Library). There is:
- No animation
- No intensity response
- No presence on the main screen
- No "soul" concept at all

### 1.3 No Progressive Disclosure
Every tab is visible from day one. History is empty. Patterns is empty. Docs is static explainer text. On day one, 3 of 4 tabs are dead ends. The app should reveal itself as the user generates data.

### 1.4 The Today View Has No Identity
No version number displayed prominently. No bug name as a header. No streak. No sense of progression. It's just a card floating in black.

### 1.5 Tone Is Inconsistent
The brand voice ("a smart friend who sees through your shit") only surfaces in completion messages and some inline comments. The rest is neutral technical labels: `SEVERITY: Medium`, `DAILY`, `STANDARD`, `VALIDATION`. The personality disappears for 90% of the interaction.

### 1.6 Onboarding Is Mechanical
Welcome → Rank 7 bugs by dragging → Confirm top 3 → Done. No moment of recognition. No explanation of what each bug actually means. No "oh shit, that's me" moment. The bug descriptions are truncated to 2-line captions in the ranking view.

### 1.7 Boot Sequence Is Generic
"EgoFix v1.0 / Loading modules... / bugs.db / fixes.db / patterns.db / System ready." This could be any app. It sets no tone, creates no anticipation, and teaches nothing about the metaphor.

---

## 2. DESIGN PRINCIPLES FOR THE REDESIGN

1. **The app is a character.** It has opinions. It notices things. It talks to you like a knowing friend, not a dashboard.
2. **Every screen earns the next.** Nothing appears until it has reason to exist.
3. **The bug is always present.** Your primary bug's ASCII soul is a persistent companion — visible, animated, responsive.
4. **Silence is a feature.** The app gets quieter as you get better. Empty states aren't errors — they're earned.
5. **One thing at a time.** No tab bars on day one. The app is a single-screen experience that expands.

---

## 3. THE ANIMATED ASCII SOULS

This is the single biggest missing piece. Each bug needs a living, breathing visual identity.

### 3.1 What a Soul Is

An ASCII soul is a **multi-frame terminal animation** (4–8 frames, looping) that represents a bug's current state. It lives on the Today screen as the primary visual element. It's the first thing you see when you open the app.

Think of it like a tamagotchi rendered in monospace — but instead of cute, it's unsettling. It shows you what your ego pattern looks like when it's running.

### 3.2 Soul States

Each soul has **3 intensity states** that change based on weekly diagnostic data and crash frequency:

| State | Trigger | Visual Behavior |
|-------|---------|-----------------|
| **Quiet** | Diagnostic: quiet, no recent crashes | Slow, minimal animation. Breathing. Almost dormant. Feels contained. |
| **Present** | Diagnostic: present, or 1-2 crashes this week | Medium animation. Fidgeting. Restless. Clearly active. |
| **Loud** | Diagnostic: loud, or 3+ crashes this week | Fast, aggressive animation. Glitching. Expanding. Feels urgent. |

### 3.3 The Seven Souls — Animation Concepts

Each soul is 12–16 chars wide, 6–8 lines tall. Rendered at **size 14** minimum (not 10). Centered on screen with the bug's accent color.

**The Corrector** (need-to-be-right) — A pointing finger / exclamation mark that pulses
- Quiet: finger slowly taps, `!` fades in/out gently
- Present: finger wags side to side, `!` blinks
- Loud: finger jabs aggressively, `!!` appears, characters scatter and reform

**The Performer** (need-to-impress) — A spotlight / figure on stage
- Quiet: spotlight dims on/off, figure stands still
- Present: figure poses, spotlight sweeps
- Loud: figure frantically changes poses, spotlight strobes, `LOOK AT ME` flashes

**The Chameleon** (need-to-be-liked) — A face/mask that shifts between expressions
- Quiet: face is neutral, occasional subtle shift
- Present: face alternates between :) and :| 
- Loud: face rapidly cycles through expressions, features misalign, identity fragmenting

**The Controller** (need-to-control) — A grid / control panel with switches
- Quiet: grid stable, one switch occasionally flips
- Present: multiple switches flipping, grid lines shifting
- Loud: grid warping, switches misfiring, `CTRL` blinking erratically

**The Scorekeeper** (need-to-compare) — A balance scale tipping
- Quiet: scale balanced, barely moving
- Present: scale slowly tips one way, then the other
- Loud: scale violently rocking, numbers appearing and disappearing on each side

**The Deflector** (need-to-deflect) — A shield / arrows bouncing off
- Quiet: shield static, rare arrow deflects
- Present: arrows coming more frequently, shield shifting
- Loud: barrage of arrows, shield cracking, things getting through

**The Narrator** (need-to-narrate) — A speech bubble / text that won't stop
- Quiet: single `...` blinking in a speech bubble
- Present: words appearing and disappearing: `blah`, `but`, `unfair`
- Loud: speech bubble overflowing, text spilling out, multiple bubbles spawning

### 3.4 Technical Implementation

```swift
struct BugSoulView: View {
    let slug: String
    let intensity: BugIntensity  // .quiet, .present, .loud
    
    @State private var frame: Int = 0
    @State private var timer: Timer?
    
    var body: some View {
        Text(currentFrame)
            .font(.system(size: fontSize, design: .monospaced))
            .foregroundColor(BugASCIIArt.color(for: slug).opacity(opacity))
            .multilineTextAlignment(.center)
            .onAppear { startAnimation() }
            .onDisappear { stopAnimation() }
    }
    
    private var frameRate: Double {
        switch intensity {
        case .quiet: return 1.5    // slow, breathing
        case .present: return 0.6  // medium, fidgeting
        case .loud: return 0.25   // fast, glitching
        }
    }
    
    private var fontSize: CGFloat { 14 }
    
    private var opacity: Double {
        switch intensity {
        case .quiet: return 0.5
        case .present: return 0.7
        case .loud: return 1.0
        }
    }
}
```

Each bug provides an array of frames per intensity level — stored as static `[[String]]` arrays in the `BugSoulFrames` enum. The view cycles through them at the appropriate frame rate.

### 3.5 Where Souls Appear

| Location | Size | Behavior |
|----------|------|----------|
| **Today view** (primary) | Large (fills upper third of screen) | Animated, responds to current intensity |
| **Bug detail sheet** | Medium | Animated at current intensity |
| **Onboarding bug selection** | Small, inline | Static or slow-animate on selection |
| **Crash flow** | Large, loud intensity | Always "loud" during crash logging |
| **Completion screen** | Medium, transitioning | Shifts from current → one step quieter (reward) |

---

## 4. THE REDESIGNED USER JOURNEY

### 4.1 First Launch: The Boot Sequence (Redesigned)

The current boot sequence is generic loading bars. The new one sets the entire tone.

```
> scanning user...
> ego detected.
> multiple patterns found.
> status: unexamined.

This is not a self-help app.
This is a debugger.

Your ego is legacy code —
poorly documented functions
that fire when they shouldn't.

Let's see what we're working with.

[ Begin scan ]
```

Key changes:
- Text appears line-by-line with typewriter effect
- The word "ego" briefly glitches (character substitution, then resolves)
- No progress bars — this is a narrative, not a loading screen
- "Begin scan" replaces "Initialize" — sets up what onboarding actually is
- Boot sequence is **not skippable** on first launch (it's 8 seconds, max)
- On subsequent cold launches: abbreviated 2-second version with just the glitch + `> v{version} resuming...`

### 4.2 Onboarding: The Scan (Redesigned)

Current: rank 7 bugs by dragging. No context, no moment of recognition.

New flow — **one bug at a time:**

**Step 1: The Scan**
Show bugs one at a time, full screen. For each bug:

```
PATTERN DETECTED: The Corrector

Correcting others. Winning arguments.
Having the last word.

// You feel physical discomfort when
// someone says something wrong.

Does this run in your system?

[ Yes, often ]  [ Sometimes ]  [ Rarely ]
```

- Show the bug's ASCII soul (animated at "present" intensity) as the background/header
- User sees the full description and daily-life examples
- Three-option response instead of abstract ranking
- "Yes, often" and "Sometimes" both flag it as relevant; "Rarely" deprioritizes
- Cycle through all 7 bugs (show 5 initially, "2 more patterns detected" to reveal rest)
- This takes ~90 seconds but creates 7 moments of self-recognition

**Step 2: Your Configuration**

```
SCAN COMPLETE

3 active patterns detected:

#1  The Corrector      // runs often
    [soul animation]

#2  The Chameleon      // runs sometimes  
    [soul animation]

#3  The Scorekeeper    // runs sometimes
    [soul animation]

// Fixes will target these patterns.
// Priority: #1 gets more attention.
// You can adjust this anytime.

[ Commit configuration ]
```

- Show the ASCII souls of their selected bugs, animated
- Clear explanation of what happens next
- "Commit configuration" (not just "Commit") — tells them they're setting something up

**Step 3: First Fix (Immediate)**

Don't go to a tab bar. Go directly to the first fix:

```
FIRST FIX ASSIGNED

Your system is v1.0.
Let's start.
```

Then show the fix card — same screen, no navigation.

### 4.3 The Today View (Redesigned)

Current: a fix card floating in black with no context.

New: a **single-screen experience** with clear identity and hierarchy.

```
┌─────────────────────────────────┐
│ v1.2            ∙∙∙ 4 day run   │  ← version + streak, small, top bar
│                                 │
│      [ASCII SOUL ANIMATION]     │  ← primary bug soul, large, centered
│      [    animated, living  ]   │
│      [    at current state  ]   │
│                                 │
│ // The Corrector is present.    │  ← status line — changes with intensity
│                                 │
│─────────────────────────────────│
│                                 │
│ FIX #037                        │
│ Let someone else have the       │
│ last word today.                │
│                                 │
│ // This is harder when you're   │
│ // sure you're right.           │
│ // That's the point.            │
│                                 │
│ [interaction UI if applicable]  │
│                                 │
│ [ Apply ]  [ Skip ]  [ Fail ]   │
│                                 │
│              [ ! ]              │  ← crash button, subtle, bottom
└─────────────────────────────────┘
```

Key changes:
- **Version number always visible** top-left
- **Streak displayed** top-right (with self-aware tone — see streak section)
- **Bug soul is the hero element** — large, animated, always present
- **Status line** below soul: "The Corrector is quiet." / "The Corrector is present." / "The Corrector is loud." — changes based on data
- **Fix card is below the soul** — scrollable if the interaction type needs space
- **Crash button** moves to bottom center, smaller, less floating-action-button-ish
- **No tab bar visible initially** (see progressive disclosure)

### 4.4 Post-Outcome Flow (Redesigned)

Current: dead-end completion screen with "Tomorrow brings another fix."

New: the completion screen **does something.**

**On Apply:**
```
+
FIX APPLIED

No fanfare. You did the thing.

// [micro-education tidbit]

[soul animation shifts one tick quieter momentarily]

v1.2 → v1.3   // if version incremented
```

Then after 2 seconds, **the soul reappears** at the top, and the screen settles into a "done for today" state:

```
v1.3            ∙∙∙ 5 day run

     [soul — quiet animation]

// Fix applied. System stable.
// Come back tomorrow.

     ↓ scroll for more ↓
```

Scrolling down reveals (only if data exists):
- This week's fixes (applied/skipped/failed count)
- Last pattern detected (if any)
- "History" link → opens history view

This "done state" is the **home base** when there's no pending fix. It's not a dead end — it's a resting place with optional depth.

**On Skip:**
```
~
FIX SKIPPED

Noted. No judgment.
// But the pattern noticed you noticing it.
```

**On Fail:**
```
x
FIX FAILED

The bug won this round.
// That's data, not defeat.
```

### 4.5 Progressive Disclosure: How the App Expands

**Day 1:** Single-screen only. Today view with fix. No tabs. No navigation except the crash button.

**Day 3 (after 3 interactions):** A subtle prompt appears below the done-state:

```
// 3 fixes in.
// History is accumulating.

[ View history → ]
```

Tapping this opens the History view for the first time. From now on, a small `[ history ]` link is visible in the done-state footer.

**Day 7 (after first weekly diagnostic):** The weekly diagnostic prompt appears naturally in the Today view (not a separate tab). After completion, a new link appears:

```
// First diagnostic complete.
// Pattern analysis initialized.

[ View patterns → ]
```

**Day 14 (first pattern detected):** Pattern surfaces in the Today flow (before or after fix, per existing surfacing rules). After acknowledging, the Patterns section becomes a persistent link.

**Day 21+:** By now the user has history, patterns, and diagnostics. At this point (and only at this point), introduce a **minimal navigation drawer or bottom tabs** — but only for sections that have content:

```
[ Today ]  [ History ]  [ Patterns ]  [ · · · ]
```

The `· · ·` menu contains Docs and Bug Library. These are reference material, not primary navigation.

**The rule:** Nothing appears until the user has generated the data that makes it meaningful.

### 4.6 The Streak (Redesigned Tone)

Current: StreakCardView exists but has no personality.

New: The streak counter is always visible (top-right of Today view) but with the brand's self-aware tone:

```
// Day count formats:
∙ 1           // just a number, first day
∙∙ 2          // dots = days
∙∙∙ 3
∙∙∙∙ 4
∙∙∙∙∙ 5

// At 7 days:
∙∙∙∙∙∙∙ 7    // This metric is meaningless.

// At 14 days:
14 days       // You're still here.

// At 30 days:
30 days       // The app should be getting quieter by now.

// Streak break:
∙ 0           // Reset. No drama.
```

- No streak-break notification. Ever.
- One free freeze per week (automatic, not requested)
- The streak is always small text, never celebrated

### 4.7 The Crash Flow (Redesigned)

Current: sheet opens, big red "!", three-step flow.

New: The crash flow should feel **fast and low-friction.** Two taps to log.

**Tap 1:** Crash button → immediate bug selection (no intermediate "Something resurfaced?" screen):

```
CRASH

[ The Corrector    ]  ← tap to select
[ The Chameleon    ]
[ The Scorekeeper  ]

// optional note _______________
```

**Tap 2:** Select bug → crash logged immediately. Optional note field is visible but not required.

```
LOGGED.

[loud soul animation of the crashed bug]

// It happens. That's the whole
// point of logging.

[ Quick fix → ]  [ Done ]
```

The soul shows at loud intensity for the crashed bug. "Quick fix" is offered but not forced.

### 4.8 The Weekly Diagnostic (Redesigned)

Current: separate view via sheet. Functional but disconnected.

New: The diagnostic appears **inside the Today view** on Sunday/Monday as a replacement for the fix card:

```
v1.3            ∙∙∙ 7 day run

     [soul animation]

WEEKLY DIAGNOSTIC

This week, The Corrector felt...

[ Quiet ]  [ Present ]  [ Loud ]

// 2 more bugs to check →
```

Same flow, but it happens in-place rather than in a sheet. Feels like part of the daily rhythm, not a pop-up interruption.

---

## 5. TONE INJECTION POINTS

Every screen needs at least one moment of personality. Here's where the current app is too neutral and what to add:

### 5.1 Status Lines (New)

Below the soul on the Today view, a single status line that changes:

```
// Quiet days:
"The Corrector is dormant. Enjoy the silence."
"System running clean."
"No crashes. Suspicious."

// Present days:
"The Corrector is present. Watch for it today."
"Running in the background."
"Active but contained."

// Loud days:
"The Corrector is loud today."
"High CPU usage on this pattern."
"This is when the fixes matter most."

// Post-crash:
"Crash logged. Recovery mode."
"The Corrector won that round."

// Long streak:
"v1.7 — still debugging."
"12 days. The app noticed."
```

Randomize from a pool. One line per session.

### 5.2 Empty States (Fix Current)

Current empty states are bland. New ones:

```
// History (no data yet):
"// Nothing here yet."
"// That changes tomorrow."

// Patterns (no patterns yet):
"// Patterns emerge from data."
"// Keep logging. The app is watching."
"// (In a non-creepy way.)"

// After completion (done for today):
"// System idle."
"// You're free to go."
```

### 5.3 Fix Card Comments

The inline comments (`// This is harder when...`) are the app's best feature. Ensure every fix has one. For fixes currently missing `inlineComment`, add one. The comment should reframe, not repeat:

```
// Good: "The urge to correct isn't about accuracy. It's about status."
// Bad:  "Try to let them be wrong."  (just repeats the prompt)

// Good: "Notice what happens in your body when you don't intervene."
// Bad:  "This might be difficult."  (obvious, adds nothing)
```

---

## 6. NAVIGATION ARCHITECTURE

### 6.1 Kill the Day-One Tab Bar

Replace with progressive single-screen → expanding navigation:

```
WEEK 1:    [ Today screen only ]
                  ↓
WEEK 2:    [ Today ] + [ History link in footer ]
                  ↓  
WEEK 3:    [ Today ] + [ History ] + [ Patterns link after first detection ]
                  ↓
WEEK 4+:   Minimal bottom nav: [ Today | History | Patterns | ··· ]
```

The `···` overflow contains: Bug Library, Docs, Settings.

### 6.2 Today Screen States

The Today view is now a **state machine** with clear states:

```
States:
1. LOADING          → spinner (brief)
2. BOOT             → first-launch boot sequence (one time)
3. ONBOARDING       → the scan flow (one time)  
4. FIX_AVAILABLE    → soul + fix card + actions
5. INTERACTION      → mid-fix (timer running, multi-step in progress, etc.)
6. OUTCOME          → completion message + education
7. DONE_FOR_TODAY   → soul + status line + optional scroll-down content
8. DIAGNOSTIC       → weekly check-in (replaces fix on Sunday/Monday)
9. PATTERN_ALERT    → pattern surfacing (before or after fix)
10. QUICK_FIX       → post-crash fix
```

All of these happen on the same screen. No sheets except crash (which is a genuine interruption from anywhere).

---

## 7. SPECIFIC VIEW CHANGES

### 7.1 ContentView.swift — Gut and Rebuild

- Remove `TabView` entirely for initial experience
- Replace with single `TodayView` that handles all states
- Add `NavigationStack` for progressive history/patterns access
- Move crash button inside `TodayView` (bottom of scroll)
- Tab bar appears only after unlocking criteria met (AppStorage flags)

### 7.2 OnboardingView.swift — Rebuild as "Scan"

- Replace drag-to-rank with one-bug-at-a-time full-screen cards
- Each card shows: soul animation, title, full description, daily-life examples
- Three-option response: `[ Yes, often ]  [ Sometimes ]  [ Rarely ]`
- Final confirmation shows top bugs with animated souls
- Transitions directly to first fix (no tab bar reveal)

### 7.3 TodayView.swift — Rebuild as Hub

- Add soul animation as hero element (upper 40% of screen)
- Add version + streak header bar
- Add status line below soul
- Fix card becomes lower portion of a ScrollView
- Done-for-today state replaces fix card after outcome
- Weekly diagnostic renders inline, not as sheet
- Pattern alerts render inline, not as separate state
- Footer expands over time with history/patterns links

### 7.4 BugASCIIArt.swift → BugSoul.swift — Full Rewrite

- Replace static strings with frame arrays per intensity
- Create `BugSoulView` with timer-driven animation
- 3 intensity levels × 7 bugs = 21 animation sets
- Each animation: 4–8 frames, ~12–16 chars wide, 6–8 lines tall
- Size 14 font minimum
- Color from existing `BugASCIIArt.color(for:)` palette

### 7.5 BootSequenceView.swift — Rewrite

- Replace generic loading bars with narrative copy
- Add glitch effect on "ego"
- Make non-skippable on first launch (~8 seconds)
- Create abbreviated version for subsequent cold launches (~2 seconds)

### 7.6 CompletionView.swift — Extend

- After typing animation completes, transition to done-for-today state
- Show version increment inline if applicable
- Soul animation momentarily shifts quieter as reward
- Scroll-down content appears after delay

### 7.7 FixCardView.swift — Simplify

- Remove `DAILY` / `STANDARD` / type badge row (users don't care about taxonomy)
- Remove `VALIDATION` collapsible (integrate into interaction views where needed)
- Keep: fix number, severity, bug name, prompt, inline comment, interaction UI, action buttons
- Ensure inline comment is always visible (not hidden behind scrolling)

### 7.8 CrashView.swift — Streamline

- Remove intermediate "Something resurfaced?" screen
- Go directly to bug selection on open
- Auto-log on bug tap (note field visible but optional)
- Show loud soul animation of crashed bug
- Quick fix offered, not forced

---

## 8. IMPLEMENTATION PHASES

### Phase R1: Soul System (Foundation)
**Scope:** Build the animation engine and all 21 soul states.

1. Create `BugSoulFrames.swift` — frame arrays for all 7 bugs × 3 intensities
2. Create `BugSoulView.swift` — timer-driven animation view
3. Create `BugIntensityProvider.swift` — determines current intensity from diagnostic data + crash frequency
4. Test: preview all 21 states, verify frame rates, verify color rendering
5. Delete old `BugASCIIArt.swift`

### Phase R2: Today View Rebuild
**Scope:** Rebuild the Today view as the single-screen hub.

1. New `TodayView` layout: header bar (version + streak) → soul → status line → fix card → footer
2. Done-for-today state with soul + scroll-down content
3. Status line pool (randomized per session)
4. Crash button repositioned inside view
5. Remove TabView from ContentView (Today is now the only screen)
6. Test: full daily flow works without any navigation

### Phase R3: Onboarding Rewrite
**Scope:** Replace drag-to-rank with one-at-a-time scan.

1. New scan flow: one bug per screen with soul + description + 3-option response
2. Prioritization logic: "Yes, often" = weight 3, "Sometimes" = weight 2, "Rarely" = weight 1
3. Configuration confirmation screen with animated souls
4. Direct transition to first fix (no tab reveal)
5. New boot sequence copy with glitch effect
6. Test: full first-launch flow from boot → scan → first fix

### Phase R4: Progressive Disclosure
**Scope:** Build the expanding navigation system.

1. AppStorage flags: `hasSeenHistory`, `hasSeenPatterns`, `diagnosticCount`, `fixCount`
2. Footer links appear based on criteria (3 fixes → history, first diagnostic → patterns)
3. History and Patterns views accessible via NavigationStack push
4. Tab bar materializes at day 21+ / enough data thresholds
5. Docs and Bug Library move to overflow menu
6. Test: fresh install shows no navigation; simulate 21 days to verify progressive unlock

### Phase R5: Tone & Polish
**Scope:** Inject personality everywhere.

1. Audit every screen for brand voice — add status lines, fix empty states, improve copy
2. Ensure every fix in seed data has an `inlineComment`
3. Streak counter with self-aware commentary
4. Crash flow streamlined to 2 taps
5. Weekly diagnostic renders inline in Today view
6. Completion view transitions to done-for-today state
7. Pattern alerts render inline
8. Remove all type/taxonomy badges from fix card (DAILY, STANDARD, etc.)

### Phase R6: Transitions & Feel
**Scope:** Make screen transitions feel cohesive.

1. Soul intensity shift animation (smooth transition between states)
2. Fix card entrance: slides up from below soul
3. Outcome flash: soul reacts to outcome (green pulse on apply, red flash on fail)
4. Done-for-today: soul settles, footer content fades in
5. Navigation transitions: push-style for history/patterns
6. Boot sequence: glitch effect implementation

---

## 9. WHAT TO KEEP

Not everything needs to change. These are solid:

- **All 18 data models** — no changes needed
- **All repository protocols + implementations** — no changes needed
- **All 6 pattern detectors** — no changes needed
- **DailyFixService, CrashService, VersionService** — no changes needed
- **All 14 interaction type views** — keep as-is, they work
- **294 seed fixes** — keep, but audit for missing inlineComments
- **FixInteractionManager** — no changes needed
- **Pattern surfacing logic** — keep, just change where it renders
- **Weekly diagnostic logic** — keep, just change where it renders
- **ScanlineOverlay** — keep (subtle, doesn't hurt)
- **All test infrastructure** — keep, extend for new views

---

## 10. WHAT TO DELETE

- `BugASCIIArt.swift` — replaced by soul system
- Tab bar in `ContentView` (for initial experience)
- `BootSequenceView.swift` — rewrite entirely
- `OnboardingView.swift` — rewrite entirely (scan flow)
- `DocsView.swift` as a primary tab — moves to overflow
- Intermediate crash confirmation screen (`CrashInitialView`)
- Type badge row in `FixCardView` (DAILY / STANDARD / etc.)
- Validation collapsible in `FixCardView`

---

## 11. SUCCESS CRITERIA

After this redesign, a first-time user should:

1. **Understand the metaphor** within 10 seconds of launch (boot sequence)
2. **Feel seen** during onboarding (the scan creates recognition moments)
3. **See their bug as a living thing** on the Today screen (soul animation)
4. **Know exactly what to do** every time they open the app (one fix, three buttons)
5. **Feel something** after marking an outcome (soul reacts, version ticks)
6. **Discover new features naturally** as they generate data (progressive disclosure)
7. **Never see an empty screen** that wasn't earned through stability

After 30 days, a returning user should:

1. **Open the app and immediately see their bug's current state** (soul at correct intensity)
2. **Have a sense of progression** (version number, historical soul states)
3. **Have received at least 2-3 pattern insights** that surprised them
4. **Feel the app getting quieter** (fewer prompts, earned silence)
5. **Not need any feature explained** — everything revealed itself through use

REDESIGN_EOF

# --- tasks/r1-soul-system/plan.md ---
cat > tasks/r1-soul-system/plan.md << 'R1_SOUL_SYSTEM_EOF'
# Task: R1 — Soul System

**Status**: Pending
**Branch**: r1-soul-system
**Goal**: Replace static ASCII art with animated multi-frame "souls" for all 7 bugs at 3 intensity levels. The soul is the app's visual heartbeat — a living terminal animation that represents each ego pattern.

## Context

Read CLAUDE.md for project context and `egofix-ux-redesign.md` for the full redesign rationale.

Currently `BugASCIIArt.swift` contains static string constants rendered at 10pt font. These are only shown in the Bug Library (behind Docs tab). Nobody sees them.

The redesign makes souls the **primary visual element** of the entire app — large, animated, front-and-center on the Today screen. This task builds the animation engine and all 21 soul states (7 bugs × 3 intensities). Later tasks (R2) will integrate them into views.

## Design Constraints

- **Size**: 12–16 chars wide, 6–8 lines tall per frame
- **Font size**: 14pt minimum (not 10 — these need to be readable and prominent)
- **Frame count**: 4–8 frames per animation loop
- **Colors**: Use existing `BugASCIIArt.color(for:)` palette (red-orange, purple, cyan, yellow, green, gray, blue)
- **Style**: Terminal art. Unsettling, not cute. These show what the ego pattern looks like when it's running.

## What to Build

### File 1: `EgoFix/Views/Components/BugSoulFrames.swift`

An enum that provides frame arrays for each bug at each intensity. Structure:

```swift
enum BugSoulFrames {
    /// Returns frames for a given bug slug and intensity
    static func frames(for slug: String, intensity: BugIntensity) -> [String] {
        switch slug {
        case "need-to-be-right": return correctorFrames(intensity)
        case "need-to-impress": return performerFrames(intensity)
        // ... etc
        default: return unknownFrames()
        }
    }
}
```

Each bug needs 3 sets of frames:

**The Corrector** (need-to-be-right, red-orange):
- Quiet (4 frames): An exclamation mark gently pulsing. Minimal movement. Finger/pointer barely tapping.
- Present (6 frames): Exclamation wags. Finger pointing more insistently. Characters shifting.
- Loud (8 frames): Exclamation doubles (!!). Finger jabbing. Characters glitching/scattering and reforming. Frame variance is high.

**The Performer** (need-to-impress, purple):
- Quiet (4 frames): Spotlight barely visible, figure still.
- Present (6 frames): Figure posing, spotlight sweeping side to side.
- Loud (8 frames): Figure frantically changing poses, spotlight strobing, text fragments like `LOOK` appearing.

**The Chameleon** (need-to-be-liked, cyan):
- Quiet (4 frames): Face mostly stable, very subtle expression shift.
- Present (6 frames): Face alternating between expressions `:)` → `:|` → `:)`.
- Loud (8 frames): Face rapidly morphing, features misaligning, identity fragmenting — parts of different expressions overlapping.

**The Controller** (need-to-control, yellow):
- Quiet (4 frames): Grid stable, one switch occasionally flipping.
- Present (6 frames): Multiple switches flipping, lines shifting.
- Loud (8 frames): Grid warping, `CTRL` blinking, switches misfiring in wrong positions.

**The Scorekeeper** (need-to-compare, green):
- Quiet (4 frames): Scale balanced, barely moving.
- Present (6 frames): Scale slowly tipping one direction, then the other.
- Loud (8 frames): Scale violently rocking, numbers appearing and disappearing on each side.

**The Deflector** (need-to-deflect, gray):
- Quiet (4 frames): Shield static, rare deflection.
- Present (6 frames): Arrows more frequent, shield shifting position.
- Loud (8 frames): Barrage of arrows, shield cracking, fragments getting through.

**The Narrator** (need-to-narrate, blue):
- Quiet (4 frames): Single `...` blinking in speech bubble.
- Present (6 frames): Words fading in/out: `blah`, `but`, `unfair`.
- Loud (8 frames): Bubble overflowing, text spilling, multiple bubbles appearing.

**Important**: Every frame in a set must be the **same dimensions** (pad with spaces). This prevents layout jitter during animation. Use a consistent width and height per bug.

### File 2: `EgoFix/Views/Components/BugSoulView.swift`

The animated view component:

```swift
struct BugSoulView: View {
    let slug: String
    let intensity: BugIntensity
    var size: SoulSize = .large
    
    enum SoulSize {
        case small   // 11pt, for lists
        case medium  // 13pt, for sheets
        case large   // 16pt, for Today screen hero
    }
    
    @State private var currentFrame: Int = 0
    
    var body: some View {
        let frames = BugSoulFrames.frames(for: slug, intensity: intensity)
        
        Text(frames.isEmpty ? "" : frames[currentFrame % frames.count])
            .font(.system(size: fontSize, design: .monospaced))
            .foregroundColor(BugASCIIArt.color(for: slug).opacity(colorOpacity))
            .multilineTextAlignment(.center)
            .lineSpacing(1)
            .onAppear { startAnimation(frameCount: frames.count) }
    }
    
    private var frameRate: Double {
        switch intensity {
        case .quiet: return 1.2
        case .present: return 0.5
        case .loud: return 0.2
        }
    }
    
    private var fontSize: CGFloat {
        switch size {
        case .small: return 11
        case .medium: return 13
        case .large: return 16
        }
    }
    
    private var colorOpacity: Double {
        switch intensity {
        case .quiet: return 0.5
        case .present: return 0.75
        case .loud: return 1.0
        }
    }
}
```

Use a timer (via `TimelineView` or `Timer.publish`) to advance frames. **Use `TimelineView(.periodic(from: .now, by: frameRate))`** — this is the SwiftUI-native approach and doesn't leak timers.

The view should smoothly handle:
- Slug changes (bug switches)
- Intensity changes (diagnostic data updates)
- Size changes
- Appearing/disappearing without timer leaks

### File 3: `EgoFix/Services/BugIntensityProvider.swift`

Determines the current intensity for a bug based on data:

```swift
class BugIntensityProvider {
    let weeklyDiagnosticRepository: WeeklyDiagnosticRepository
    let crashRepository: CrashRepository
    
    /// Returns current intensity for a bug, based on most recent diagnostic + crash frequency
    func currentIntensity(for bugId: UUID) async throws -> BugIntensity {
        // 1. Check most recent weekly diagnostic for this bug
        // 2. Check crash count for this bug in the last 7 days
        // 3. Rules:
        //    - If diagnostic said "loud" OR 3+ crashes this week → .loud
        //    - If diagnostic said "present" OR 1-2 crashes this week → .present
        //    - If diagnostic said "quiet" AND 0 crashes this week → .quiet
        //    - Default (no data): .present (not quiet — we don't assume calm)
    }
}
```

### File 4: Delete `BugASCIIArt.swift`

Remove entirely. The `BugASCIIArt.color(for:)` function should move into `BugSoulView` or a shared `BugColors` enum so color mapping isn't lost.

**Before deleting**, check all references:
- `BugASCIIArtView` is used in `BugLibraryRowView` and `BugDetailView`
- `BugASCIIArt.color(for:)` may be referenced elsewhere
- Replace all `BugASCIIArtView(slug:)` calls with `BugSoulView(slug:, intensity:, size:)`

### File 5: Update existing views to use BugSoulView

- `BugLibraryRowView`: Replace `BugASCIIArtView(slug: bug.slug)` with `BugSoulView(slug: bug.slug, intensity: .present, size: .small)`
- `BugDetailView`: Replace `BugASCIIArtView(slug: bug.slug)` with `BugSoulView(slug: bug.slug, intensity: .present, size: .medium)`

For now, hardcode `.present` intensity in these views — R2 will wire up the real intensity provider.

## Steps

1. Create `BugSoulFrames.swift` with all 21 animation sets (7 bugs × 3 intensities)
2. Create `BugSoulView.swift` with timer-driven frame animation
3. Create `BugIntensityProvider.swift` with intensity determination logic
4. Move color mapping out of `BugASCIIArt` into a reusable location
5. Replace all `BugASCIIArtView` usages with `BugSoulView`
6. Delete `BugASCIIArt.swift`
7. Add SwiftUI Preview for all 7 bugs at all 3 intensities (scrollable grid)
8. Write tests for `BugIntensityProvider` (quiet/present/loud determination)
9. Write tests for `BugSoulFrames` (all slugs return non-empty frames for all intensities)
10. Verify all existing tests still pass
11. Build — 0 errors

## Frame Design Guidelines

When designing the ASCII frames, follow these rules:
- All frames in a set must have **identical dimensions** (same line count, same max width, pad trailing spaces)
- Use only ASCII characters: letters, numbers, `!@#$%^&*()-_=+[]{}|;:'",.<>/?~` and box-drawing if needed
- No emoji, no Unicode beyond basic ASCII
- The art should be **abstract/symbolic** — not literal drawings of people
- Quiet frames should feel calm and contained
- Present frames should feel restless and shifting
- Loud frames should feel urgent, glitchy, and slightly broken
- Each frame should be recognizably "the same thing" — don't completely change the shape between frames

## Acceptance Criteria

- [ ] `BugSoulFrames` provides frame arrays for all 7 bugs × 3 intensities (21 sets total)
- [ ] Every frame set has 4-8 frames
- [ ] All frames within a set have identical dimensions
- [ ] `BugSoulView` animates smoothly at 3 different speeds (quiet=slow, present=medium, loud=fast)
- [ ] `BugSoulView` supports 3 sizes (small=11pt, medium=13pt, large=16pt)
- [ ] `BugIntensityProvider` determines intensity from diagnostics + crashes
- [ ] `BugIntensityProvider` defaults to `.present` when no data exists
- [ ] `BugASCIIArt.swift` is deleted
- [ ] Bug colors are preserved in new location
- [ ] `BugLibraryRowView` and `BugDetailView` use `BugSoulView`
- [ ] Preview exists showing all 21 states in a scrollable grid
- [ ] Tests for intensity provider (quiet, present, loud, default)
- [ ] Tests for frame data integrity (non-empty, consistent dimensions)
- [ ] All existing tests still pass
- [ ] Project builds with 0 errors

R1_SOUL_SYSTEM_EOF

# --- tasks/r1-soul-system/progress.md ---
cat > tasks/r1-soul-system/progress.md << 'PROGRESS_EOF'
# Progress

## Status: Not Started

## Completed
(none)

## Issues
(none)
PROGRESS_EOF

# --- tasks/r2-today-rebuild/plan.md ---
cat > tasks/r2-today-rebuild/plan.md << 'R2_TODAY_REBUILD_EOF'
# Task: R2 — Today View Rebuild

**Status**: Pending
**Branch**: r2-today-rebuild
**Depends on**: R1 (soul system must exist)
**Goal**: Rebuild the Today view as the app's single-screen hub — soul animation as hero, version + streak header, status line, fix card below, done-for-today state, no tab bar.

## Context

Read CLAUDE.md for project context, `egofix-ux-redesign.md` for full redesign rationale, and the R1 task plan for soul system details.

Currently `TodayView.swift` shows a fix card floating in black space. No version number, no bug identity, no sense of place. `ContentView.swift` wraps everything in a `TabView` with 4 tabs visible from day one. The completion screen (`CompletionView.swift`) is a dead end.

This task transforms Today into the entire app experience. The tab bar is removed. Everything happens on one screen. Navigation to other sections comes later (R4).

## What Exists (Keep)

- `TodayViewModel.swift` — state machine with loading/fix/pattern/crash states. Keep the logic, modify the states.
- `FixCardView.swift` — fix display. Keep but modify (remove type badges, simplify).
- `CompletionView.swift` — outcome display. Keep typing animation, extend with done-state.
- `FixInteractionManager` + all 14 interaction type views — keep completely untouched.
- `VersionService`, `DailyFixService`, `StreakService` — keep, just wire into new UI.
- `CrashView.swift` — keep as sheet (crashes are interruptions from anywhere).

## What to Build

### 1. New Today View Layout

Replace the current `TodayView` body with this hierarchy:

```
ScrollView {
    VStack {
        // HEADER BAR
        HStack {
            versionLabel      // "v1.3" — left aligned
            Spacer()
            streakLabel       // "∙∙∙ 5" or "5 days" — right aligned
        }
        
        // SOUL (hero element — upper 40% of screen)
        BugSoulView(slug: primaryBugSlug, intensity: currentIntensity, size: .large)
            .frame(height: 200)  // approximate — adjust to look right
        
        // STATUS LINE
        Text(statusLine)      // "// The Corrector is present."
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(.gray)
        
        // MAIN CONTENT (changes based on state)
        switch state {
        case .fixAvailable:    fixCardContent
        case .interaction:     interactionContent
        case .outcome:         outcomeContent
        case .doneForToday:    doneContent
        case .diagnostic:      diagnosticContent
        case .patternAlert:    patternAlertContent
        case .quickFix:        quickFixContent
        }
        
        // CRASH BUTTON (always at bottom)
        crashButton
    }
}
```

### 2. State Machine Update

Update `TodayViewModel` states. Current states likely include loading, fix, pattern, etc. New states:

```swift
enum TodayState {
    case loading
    case fixAvailable(Fix)
    case interaction(Fix)           // timer running, multi-step in progress
    case outcome(FixOutcome, Fix)   // just marked, showing completion
    case doneForToday               // no pending fix, resting state
    case diagnostic                 // weekly check-in (Sunday/Monday)
    case patternAlert(DetectedPattern)  // surfaced pattern
    case quickFix(Fix)              // post-crash fix
}
```

Key behavior:
- On launch → check for pending fix → `.fixAvailable` or `.doneForToday`
- On outcome marked → `.outcome` → after 3 seconds auto-transition to `.doneForToday`
- On Sunday/Monday with no completed diagnostic → `.diagnostic` (replaces fix)
- Pattern alerts fire before fix (alerts) or after outcome (insights) per existing surfacing rules
- Quick fix after crash dismissal

### 3. Version Label

Top-left of header bar. Pull from `UserProfile.currentVersion`:

```swift
Text("v\(viewModel.currentVersion)")
    .font(.system(.caption, design: .monospaced))
    .foregroundColor(.green)
```

Wire `TodayViewModel` to fetch current version from `UserRepository` on appear.

### 4. Streak Label

Top-right of header bar. Pull from `StreakService`:

```swift
// Format based on count:
// 1-6: dots + number   "∙∙∙ 3"
// 7+: just number      "7 days"
// 0: "∙ 0"
```

The streak should be **understated**. Small, gray text. No celebration animation (that's removed — the old `StreakCardView` tick-up animation is cut). The streak is information, not reward.

At specific milestones, the streak text gains brief self-aware commentary (stored in a lookup, not runtime-computed):
- Day 7: display tooltip or subtitle "// This metric is meaningless."
- Day 14: "// You're still here."
- Day 30: "// The app should be getting quieter."

These are subtle — small gray text below the streak number, visible for that day only.

### 5. Status Line Pool

Below the soul, one randomized status line per session. Create `StatusLineProvider`:

```swift
enum StatusLineProvider {
    static func line(for intensity: BugIntensity, bugTitle: String, context: StatusContext) -> String
    
    enum StatusContext {
        case normal
        case postCrash
        case longStreak(Int)
        case firstDay
    }
}
```

Lines per intensity (pool of 5+ each, pick randomly per session):

**Quiet:**
- "// \(bugTitle) is dormant. Enjoy the silence."
- "// System running clean."
- "// No crashes. Suspicious."
- "// Low activity on this pattern."
- "// Quiet doesn't mean gone."

**Present:**
- "// \(bugTitle) is present. Watch for it today."
- "// Running in the background."
- "// Active but contained."
- "// The pattern is warm. Not hot."
- "// Detectable levels. Nothing alarming."

**Loud:**
- "// \(bugTitle) is loud today."
- "// High CPU usage on this pattern."
- "// This is when the fixes matter most."
- "// Elevated activity. The fix is calibrated for this."
- "// Your ego is noisy. That's why you're here."

**Post-crash:**
- "// Crash logged. Recovery mode."
- "// \(bugTitle) won that round."
- "// System restarting."

Pick one on viewDidAppear, store in `@State` so it doesn't change mid-session.

### 6. Fix Card Simplification

Modify `FixCardView.swift`:
- **Remove** the type badge row (`DAILY`, `STANDARD`, `TIMED`, etc.)
- **Remove** the validation collapsible section
- **Remove** the `[ share ]` button from header
- **Keep**: Fix number (`FIX #037`), severity, bug name as comment, prompt text, inline comment, interaction UI, action buttons
- **Move** severity from header row to a subtle label: `// severity: medium`
- Make inline comment **always visible** — never behind scroll or collapse

The fix card should feel like reading a terminal command, not a feature-rich card:

```
FIX #037
// the-corrector · medium

Let someone else have the last word today.

// This is harder when you're sure
// you're right. That's the point.

[ Applied ]   [ Skipped ]   [ Failed ]
```

### 7. Done-for-Today State

After marking an outcome and the completion animation finishes, transition to resting state:

```swift
// doneForToday content:
VStack(spacing: 24) {
    // Soul continues animating (maybe shift one tick quieter briefly as reward)
    
    Text(doneStatusLine)  // "// Fix applied. System stable." or "// Fix skipped. No judgment."
        .font(.system(.caption, design: .monospaced))
        .foregroundColor(.gray)
    
    // This week's summary (only if data exists)
    if viewModel.weekSummary != nil {
        weekSummarySection  // "3 applied, 1 skipped, 0 failed this week"
    }
    
    // Footer links (progressive — see R4, for now just placeholder)
    // These will be empty/hidden until R4 wires them up
}
```

The done state is **not a dead end**. It's a calm landing page. The user knows the app is done with them for today.

### 8. Remove Tab Bar from ContentView

Replace `ContentView.swift`:
- Remove `TabView` entirely
- Make `TodayView` the root view (wrapped in NavigationStack for future push navigation in R4)
- Keep crash as a `.sheet` presented from TodayView (or via overlay)
- The other views (History, Patterns, Docs) still exist as files but are **not navigable yet** — R4 adds progressive links

```swift
struct ContentView: View {
    var body: some View {
        NavigationStack {
            TodayView(viewModel: ...)
        }
        .preferredColorScheme(.dark)
    }
}
```

### 9. Outcome View Integration

Currently `CompletionView` is a separate full-screen view. Instead, the outcome renders **inline** in the Today scroll view:

- Show the outcome symbol (+ / ~ / x) with typing animation (keep existing)
- Show the outcome message with typing animation (keep existing)
- Show the micro-education tidbit (keep existing)
- Show version increment if applicable: `v1.2 → v1.3`
- After typing completes (2-3 seconds), auto-transition to doneForToday state
- **Do not** show "// Tomorrow brings another fix" — the done state handles the landing

### 10. Weekly Diagnostic Inline

Currently the diagnostic is a sheet. Move it inline:
- When state is `.diagnostic`, the main content area shows the diagnostic flow
- Same UI as current diagnostic (bug intensity selection, context selection) but rendered in the Today scroll view, not a sheet
- On completion, transition to fix or doneForToday
- Skip button available, same as current

This may require refactoring `WeeklyDiagnosticView` to work as an inline component rather than a standalone sheet. If this is too complex for this task, keep it as a sheet for now and add a TODO comment — the inline rendering can happen in R5.

### 11. Crash Button Repositioning

Move the crash button from the tab bar / floating position into the Today view:
- Bottom of the scroll content, subtle
- Small text: `[ ! ]` with red glow (keep existing glow effect)
- Tapping still presents crash flow as a sheet (crashes interrupt everything)
- The crash sheet flow is unchanged (R5 will streamline it to 2 taps)

## Steps

1. Update `TodayViewModel` with new state enum and transitions
2. Wire version + streak into TodayViewModel (fetch on appear)
3. Create `StatusLineProvider` with line pools for all intensities + contexts
4. Rebuild `TodayView` body with new layout: header → soul → status → content → crash
5. Simplify `FixCardView`: remove type badges, share button, validation section
6. Build done-for-today state view
7. Integrate outcome display inline (refactor from separate CompletionView or render inline)
8. Replace `ContentView` TabView with NavigationStack + TodayView only
9. Move crash button into TodayView bottom
10. Verify diagnostic still works (as sheet if inline is too complex)
11. Verify pattern alerts still surface correctly in new state machine
12. Run all existing tests — fix any that reference removed TabView or CompletionView navigation
13. Add tests for new state transitions (fixAvailable → outcome → doneForToday)
14. Add tests for StatusLineProvider
15. Build — 0 errors

## Important Notes

- **Don't break the interaction types.** The 14 interaction views (timed, multi-step, counter, etc.) plug into the fix card. They must continue working exactly as they do now. Test each one.
- **Don't break the crash flow.** It stays as a sheet. Don't change CrashView internals.
- **Don't break pattern surfacing.** The TodayViewModel already has pattern state handling — keep the surfacing service wired in, just make sure patterns render inline in the new layout.
- **Don't add navigation to History/Patterns yet.** That's R4. The Today view is intentionally a single screen for now.
- **Keep the ScanlineOverlay.** Apply it to the new ContentView root.

## Acceptance Criteria

- [ ] Today view shows: version (top-left), streak (top-right), soul (large, animated), status line, fix card, crash button
- [ ] Soul uses `BugSoulView` from R1, displays primary bug at current intensity
- [ ] Version label shows current version from UserProfile
- [ ] Streak label shows current streak with appropriate formatting
- [ ] Status line is randomized per session from intensity-appropriate pool
- [ ] Fix card simplified: no type badges, no share button, no validation section
- [ ] Inline comment always visible on fix card
- [ ] Marking outcome shows completion inline (typing animation preserved)
- [ ] After outcome, view transitions to done-for-today resting state
- [ ] Done state shows soul + status + optional week summary
- [ ] **No tab bar** — ContentView is NavigationStack with TodayView only
- [ ] Crash button is inside TodayView, presents crash sheet on tap
- [ ] Diagnostic still accessible (sheet is acceptable if inline is too complex)
- [ ] Pattern alerts still surface and display correctly
- [ ] All 14 interaction types still work (test each one)
- [ ] All existing tests pass (update any that assumed TabView)
- [ ] New tests for state transitions and StatusLineProvider
- [ ] Project builds with 0 errors

R2_TODAY_REBUILD_EOF

# --- tasks/r2-today-rebuild/progress.md ---
cat > tasks/r2-today-rebuild/progress.md << 'PROGRESS_EOF'
# Progress

## Status: Not Started

## Completed
(none)

## Issues
(none)
PROGRESS_EOF

# --- tasks/r3-onboarding-rewrite/plan.md ---
cat > tasks/r3-onboarding-rewrite/plan.md << 'R3_ONBOARDING_REWRITE_EOF'
# Task: R3 — Onboarding Rewrite

**Status**: Pending
**Branch**: r3-onboarding-rewrite
**Depends on**: R1 (soul system), R2 (Today view rebuild)
**Goal**: Replace the drag-to-rank onboarding with a narrative "Scan" flow — one bug at a time, full descriptions, animated souls, moments of recognition. Rewrite the boot sequence to set tone. End by dropping the user directly into their first fix.

## Context

Read CLAUDE.md for project context and `egofix-ux-redesign.md` for full redesign rationale.

Current onboarding flow (`OnboardingView.swift`):
1. `WelcomeStepView` — "Your ego is legacy software. Let's debug it." + `[ Initialize ]`
2. `BugRankingView` — Drag-to-reorder list of 7 bugs (titles + 2-line truncated descriptions)
3. `PriorityConfirmationView` — Shows top 3 + `[ Commit ]`

Problems: No moment of recognition. Bug descriptions are truncated. No soul animations shown. No explanation of what happens next. Mechanical, not emotional.

Current boot sequence (`BootSequenceView.swift`):
- "EgoFix v1.0 / Loading modules... / bugs.db / fixes.db / System ready."
- Generic loading bars. Could be any app.

## What to Build

### 1. New Boot Sequence (`BootSequenceView.swift` — Full Rewrite)

Replace generic loading bars with narrative copy that sets the entire tone:

```
> scanning user...
> ego detected.
> multiple patterns found.
> status: unexamined.

This is not a self-help app.
This is a debugger.

Your ego is legacy code —
poorly documented functions
that fire when they shouldn't.

Let's see what we're working with.

[ Begin scan ]
```

Implementation:
- Each line appears with typewriter effect (character by character, ~30ms per char)
- Lines appear sequentially with 200-400ms delay between lines
- The `>` prefixed lines appear fast (like terminal output)
- The narrative paragraph appears slower (like someone typing thoughtfully)
- The word "ego" on line 2 briefly **glitches** — 2-3 random character substitutions over 300ms, then resolves to "ego". This is the signature visual moment. Implement with a timer that swaps characters at the index of "ego" a few times before settling.
- `[ Begin scan ]` button fades in after all text has appeared
- Total sequence: ~8 seconds. **Not skippable** on first launch.
- Store `@AppStorage("hasCompletedOnboarding")` — boot only shows on first launch
- On subsequent cold launches: abbreviated version — just the glitch + `> v{version} resuming...` (2 seconds max). This uses the existing `@AppStorage("hasSeenBoot")` pattern.

New file structure — or rewrite `BootSequenceView.swift` in place. The view needs:
- A `TypewriterText` helper (animates string character by character)
- A glitch effect on a specific word
- Sequential line reveals
- A fade-in button at the end

### 2. New Onboarding Flow: The Scan (`OnboardingView.swift` — Full Rewrite)

Replace drag-to-rank with one-bug-at-a-time full-screen cards.

**Step 1: Bug Scan (7 screens)**

For each bug, show a full-screen card:

```
PATTERN DETECTED

[Soul animation — present intensity, medium size]

The Corrector

Correcting others. Winning arguments.
Having the last word. You feel physical
discomfort when someone says something
wrong — and you feel relief when you
set it right.

// You're not helping them.
// You're helping yourself feel certain.

Does this run in your system?

[ Yes, often ]  [ Sometimes ]  [ Rarely ]
```

Implementation per card:
- Bug soul animation at top (from R1 `BugSoulView`, `.present` intensity, `.medium` size)
- Bug title large
- Bug full `description` from the Bug model (the long one, not truncated)
- An inline comment below description — these are new copy, one per bug. See copy list below.
- Three response buttons at bottom
- Transition between bugs: fade or slide-left
- Show all 7 bugs. Show first 5 normally, then after 5th: "2 more patterns detected..." with brief pause before revealing 6th and 7th. This creates a micro-moment of discovery.
- Store responses in temporary state (not persisted until confirmation)

**Response mapping:**
- "Yes, often" → priority weight 3
- "Sometimes" → priority weight 2  
- "Rarely" → priority weight 1

**Inline comments for each bug (new copy to write):**

| Bug | Inline Comment |
|-----|---------------|
| The Corrector | `// You're not helping them. You're helping yourself feel certain.` |
| The Performer | `// The applause isn't for you. It's for the version of you that showed up.` |
| The Chameleon | `// You've been so many people, you're not sure which one is real.` |
| The Controller | `// If you let go, nothing bad happens. That's the part you don't believe.` |
| The Scorekeeper | `// You're not measuring them. You're measuring yourself against them.` |
| The Deflector | `// The joke lands, the moment passes, and the feeling stays.` |
| The Narrator | `// You've told this story so many times it feels like it happened to someone else.` |

These are suggestions — Claude Code should use these or write equally good ones in the EgoFix voice.

**Step 2: Configuration Confirmation**

After all 7 bugs scanned, show the configuration:

```
SCAN COMPLETE

3 active patterns detected:

#1  The Corrector       // runs often
    [small soul animation]

#2  The Chameleon       // runs sometimes
    [small soul animation]

#3  The Scorekeeper     // runs sometimes
    [small soul animation]

4 patterns deprioritized.

// Fixes will target your top patterns.
// #1 gets the most attention.
// You can adjust this anytime.

[ Commit configuration ]
```

Implementation:
- Sort bugs by weight (3 → 2 → 1), then by original order for ties
- Top 3 (weight ≥ 2) become "active" — show with small soul animations
- Remaining 4 are "deprioritized" — mentioned but not shown
- If user rated all bugs "Rarely", show the top 3 by original order with a note: `// Interesting. Let's start here anyway.`
- `[ Commit configuration ]` button

On commit:
- Create/update UserProfile
- Set bug priorities (activate top 3, identify rest)
- Assign first fix immediately
- **Transition directly to TodayView with fix** — no intermediate screen, no tab reveal
- Set `@AppStorage("hasCompletedOnboarding")` = true

### 3. TypewriterText Component

Reusable component for the boot sequence and potentially other places:

```swift
struct TypewriterText: View {
    let text: String
    let characterDelay: Double      // seconds between characters
    var onComplete: (() -> Void)?
    
    @State private var displayedCount: Int = 0
    
    var body: some View {
        Text(String(text.prefix(displayedCount)))
            .font(.system(.body, design: .monospaced))
            .foregroundColor(.green)
            .onAppear { startTyping() }
    }
}
```

Should support:
- Configurable speed
- Completion callback
- Color and font size overrides
- Cursor blink at current position (optional)

### 4. Glitch Effect Component

For the "ego" glitch in boot sequence:

```swift
struct GlitchText: View {
    let text: String
    let glitchRange: Range<String.Index>  // which characters to glitch
    let duration: Double                   // total glitch time
    
    // Randomly substitutes characters in the range for `duration`,
    // then resolves to the real text
}
```

Or implement inline within the boot sequence view — doesn't need to be a reusable component if it's only used once.

### 5. Delete Old Onboarding Components

After building the new flow, remove:
- `WelcomeStepView` (or whatever the welcome step is named)
- `BugRankingView` (the drag-to-reorder view)
- `PriorityConfirmationView` (the old confirmation)
- `OnboardingViewModel.swift` — rewrite or heavily modify

### 6. Update OnboardingViewModel

New state machine:

```swift
enum OnboardingState {
    case boot                          // boot sequence
    case scanning(bugIndex: Int)       // showing bug N of 7
    case moreDetected                  // "2 more patterns detected..." pause
    case confirmation                  // showing final config
    case committing                    // saving and transitioning
}

class OnboardingViewModel: ObservableObject {
    @Published var state: OnboardingState = .boot
    @Published var responses: [UUID: BugResponse] = [:]  // bugId → response
    
    enum BugResponse: Int {
        case yesOften = 3
        case sometimes = 2
        case rarely = 1
    }
    
    var sortedBugs: [Bug]  // all 7 bugs in display order
    var activeBugs: [Bug]  // top 3 by weight after scan
    
    func respondToBug(_ bugId: UUID, response: BugResponse) { ... }
    func commitConfiguration() async { ... }
}
```

## Steps

1. Create `TypewriterText` component
2. Implement glitch effect (inline or component)
3. Rewrite `BootSequenceView` with narrative copy, typewriter, glitch, `[ Begin scan ]`
4. Build bug scan card view (single bug, full screen, soul + description + buttons)
5. Build scan flow (7 cards sequentially, "2 more detected" pause after 5th)
6. Build configuration confirmation view (top 3 with souls, commit button)
7. Rewrite `OnboardingViewModel` with new state machine and response tracking
8. Wire commit action: create user profile, set bug priorities, assign first fix
9. Ensure commit transitions directly to TodayView (no tab reveal, no intermediate)
10. Handle edge case: all bugs rated "Rarely"
11. Handle subsequent launches: abbreviated boot (`> v{version} resuming...`)
12. Delete old onboarding components (WelcomeStepView, BugRankingView, PriorityConfirmationView)
13. Update any tests that reference old onboarding flow
14. Write tests for: response weighting, bug sorting, edge cases, commit flow
15. Test full flow: launch → boot → scan all 7 → confirm → first fix visible
16. Build — 0 errors

## Important Notes

- **The boot sequence must feel deliberate.** 8 seconds of narrative is worth more than 2 seconds of loading bars. Don't rush it.
- **Each bug card should create a moment of recognition.** The full description + inline comment is the hook. If the copy doesn't land, the whole onboarding fails.
- **Don't skip the "2 more detected" moment.** This tiny pause creates the feeling that the app is discovering things, not just showing a list.
- **On commit, go straight to the fix.** The user should see their soul animation and first fix within seconds of committing. No "welcome to the app" screen, no feature tour, no tips.

## Acceptance Criteria

- [ ] Boot sequence shows narrative copy with typewriter effect
- [ ] "ego" glitches briefly before resolving
- [ ] `[ Begin scan ]` appears after all text, triggers onboarding
- [ ] Boot is not skippable on first launch
- [ ] Subsequent launches show abbreviated boot (2 seconds)
- [ ] Bug scan shows 7 bugs one at a time, full screen
- [ ] Each bug card shows: soul animation, title, full description, inline comment, 3 response buttons
- [ ] After 5th bug: "2 more patterns detected..." pause before 6th
- [ ] Configuration screen shows top 3 bugs with small soul animations
- [ ] `[ Commit configuration ]` creates profile, sets priorities, assigns first fix
- [ ] After commit, user lands on TodayView with fix visible — no intermediate screens
- [ ] Edge case: all "Rarely" still produces valid top 3
- [ ] Old onboarding components deleted
- [ ] Tests for response weighting, sorting, commit flow
- [ ] All existing tests pass
- [ ] Project builds with 0 errors

R3_ONBOARDING_REWRITE_EOF

# --- tasks/r3-onboarding-rewrite/progress.md ---
cat > tasks/r3-onboarding-rewrite/progress.md << 'PROGRESS_EOF'
# Progress

## Status: Not Started

## Completed
(none)

## Issues
(none)
PROGRESS_EOF

# --- tasks/r4-progressive-disclosure/plan.md ---
cat > tasks/r4-progressive-disclosure/plan.md << 'R4_PROGRESSIVE_DISCLOSURE_EOF'
# Task: R4 — Progressive Disclosure

**Status**: Pending
**Branch**: r4-progressive-disclosure
**Depends on**: R2 (Today view is the single-screen hub), R3 (onboarding complete)
**Goal**: Build the expanding navigation system — features reveal themselves as the user generates data. No empty tabs, no dead ends. History appears after 3 fixes. Patterns appears after first detection. Full nav materializes around week 3-4.

## Context

Read CLAUDE.md for project context and `egofix-ux-redesign.md` for full redesign rationale.

After R2, the app is a single TodayView screen with no navigation to History, Patterns, Docs, or Bug Library. Those views still exist as files but are unreachable. This task makes them reachable — progressively.

The principle: **nothing appears until the user has generated the data that makes it meaningful.**

## What to Build

### 1. Unlock State Tracking

Create `AppProgressTracker` that manages unlock flags:

```swift
class AppProgressTracker: ObservableObject {
    // Persisted via @AppStorage or UserDefaults
    @Published var totalFixesCompleted: Int      // applied + skipped + failed
    @Published var firstDiagnosticCompleted: Bool
    @Published var firstPatternDetected: Bool
    @Published var hasSeenHistory: Bool
    @Published var hasSeenPatterns: Bool
    @Published var daysActive: Int               // distinct days with app interaction
    
    // Computed unlock states
    var isHistoryUnlocked: Bool {
        totalFixesCompleted >= 3
    }
    
    var isPatternsUnlocked: Bool {
        firstPatternDetected
    }
    
    var isFullNavUnlocked: Bool {
        daysActive >= 14 && totalFixesCompleted >= 10
    }
    
    var isBugLibraryUnlocked: Bool {
        totalFixesCompleted >= 7  // after first version bump
    }
}
```

Wire this into TodayViewModel — update counts after each fix completion, diagnostic, etc. Use `@AppStorage` for persistence so it survives app restarts without needing SwiftData queries on every launch.

### 2. Footer Links in Done-for-Today State

In R2, the done-for-today state has a placeholder for footer content. Now populate it:

**After 3 fixes (history unlocks):**

A one-time prompt appears in the done-state footer:

```
// 3 fixes logged.
// Your history is building.

[ View changelog → ]
```

After first tap, the prompt changes to a persistent subtle link:

```
[ changelog → ]
```

**After first pattern detected (patterns unlocks):**

```
// First pattern detected.
// The app noticed something.

[ View pattern → ]
```

Then persists as:

```
[ patterns → ]
```

**After 7 fixes / first version bump (bug library unlocks):**

```
// v1.1 — your first update.
// You can explore your bugs anytime.

[ bug library → ]
```

Then persists as part of the overflow.

### 3. Navigation Implementation

Use `NavigationStack` (already set up in R2's ContentView):

```swift
struct ContentView: View {
    @StateObject var progressTracker = AppProgressTracker()
    
    var body: some View {
        NavigationStack {
            TodayView(viewModel: ..., progressTracker: progressTracker)
                .navigationDestination(for: AppDestination.self) { dest in
                    switch dest {
                    case .history: HistoryView(viewModel: ...)
                    case .patterns: PatternsView(viewModel: ...)
                    case .bugLibrary: BugLibraryView(viewModel: ...)
                    case .docs: DocsView()
                    case .settings: SettingsView()
                    }
                }
        }
    }
}

enum AppDestination: Hashable {
    case history
    case patterns
    case bugLibrary
    case docs
    case settings
}
```

Footer links in TodayView use `NavigationLink(value: .history)` etc.

### 4. Full Navigation Bar (Week 3-4+)

Once `isFullNavUnlocked` is true, add a minimal bottom nav bar:

```swift
// Only show when fully unlocked
if progressTracker.isFullNavUnlocked {
    HStack {
        navButton("today", destination: nil, isActive: true)  // current screen
        if progressTracker.isHistoryUnlocked {
            navButton("history", destination: .history)
        }
        if progressTracker.isPatternsUnlocked {
            navButton("patterns", destination: .patterns)
        }
        navButton("···", destination: nil, showsMenu: true)  // overflow
    }
}
```

The nav bar should be:
- Monospaced, small text, not icons
- Dark background, subtle divider at top
- `today` / `history` / `patterns` / `···`
- The `···` opens a small menu: Bug Library, Docs, Settings
- Keep the brutalist aesthetic — no SF Symbols, no rounded pill indicators

**Important**: Even after the nav bar appears, the Today view remains the primary screen. The nav bar is a convenience, not a reorganization.

### 5. Unlock Moment Animations

When a section first unlocks, the footer link should appear with a brief animation:
- Slide up + fade in (0.3s)
- The `//` comment line appears first (typing style), then the link fades in below
- First unlock for each section includes the one-time descriptive prompt
- After the user taps it once, replace with the persistent compact link

### 6. One-Time Unlock Prompts

For each unlock, the prompt only shows once. Track with AppStorage flags:

```swift
@AppStorage("hasSeenHistoryUnlock") var hasSeenHistoryUnlock = false
@AppStorage("hasSeenPatternsUnlock") var hasSeenPatternsUnlock = false
@AppStorage("hasSeenBugLibraryUnlock") var hasSeenBugLibraryUnlock = false
```

After user taps the link (or views the section), set the flag and switch to the compact persistent link.

### 7. Empty State Updates

Even though sections only unlock when they have data, edge cases exist (e.g., patterns tab unlocks but the pattern gets dismissed). Update empty states with personality:

**History (shouldn't be empty if unlocked, but just in case):**
```
// Nothing here yet.
// That changes tomorrow.
```

**Patterns (if all patterns dismissed):**
```
// All caught up.
// The app is still watching.
```

These already exist from M3/M4 but verify the copy matches the tone.

### 8. Docs & Settings

**Docs** moves to the `···` overflow menu. It's reference material, not primary navigation. No changes to `DocsView` content — just relocated.

**Settings** (new, minimal):
- Bug priority adjustment (reorder active bugs)
- Notification preferences (if notifications exist)
- Reset / clear data
- About / version info
- This can be very simple for now — a basic list in monospaced terminal style

Create `SettingsView.swift` with minimal content. It doesn't need to be polished — just functional and on-brand.

### 9. Wire Unlock Triggers

Update the following to increment AppProgressTracker:

- `TodayViewModel` (or wherever fix outcomes are processed): increment `totalFixesCompleted` on any outcome
- `WeeklyDiagnosticViewModel`: set `firstDiagnosticCompleted` on first completion
- `DiagnosticEngine` / `PatternSurfacingService`: set `firstPatternDetected` when first pattern is created
- App launch: increment `daysActive` (check if today != last active date)

## Steps

1. Create `AppProgressTracker` with all unlock flags and computed states
2. Wire fix completion, diagnostic completion, pattern detection, and day counting into tracker
3. Add footer link section to TodayView done-for-today state
4. Implement history unlock: prompt at 3 fixes → persistent link
5. Implement patterns unlock: prompt on first pattern → persistent link
6. Implement bug library unlock: prompt at first version bump → persistent link
7. Add `NavigationStack` destinations for all sections
8. Implement full nav bar (appears at week 3-4+ threshold)
9. Create `···` overflow menu (Bug Library, Docs, Settings)
10. Create minimal `SettingsView`
11. Add unlock moment animations (slide up + fade in)
12. Track one-time prompt visibility with AppStorage flags
13. Verify empty states have personality-matched copy
14. Test unlock sequence: fresh install → 3 fixes → history visible → diagnostic → pattern → patterns visible → day 14 → full nav
15. Test edge case: rapid usage (all unlocks in one day)
16. Test edge case: minimal usage (only 1 fix per week)
17. All existing tests pass
18. Build — 0 errors

## Important Notes

- **Don't force unlocks.** If a user completes 10 fixes in one day, they might unlock history AND see their first pattern AND get the nav bar all at once. That's fine — show each unlock prompt in sequence, not simultaneously.
- **The nav bar is text, not icons.** `today | history | patterns | ···` in monospaced font. This is a terminal, not an iPhone app.
- **Footer links are always subtle.** Small text, gray color, left-aligned. They're discoverable but not demanding.
- **Settings is minimal.** Don't over-build it. A list of toggles and a reset button is enough.

## Acceptance Criteria

- [ ] `AppProgressTracker` persists unlock state across app restarts
- [ ] History link appears in Today footer after 3 fixes
- [ ] Patterns link appears in Today footer after first pattern detection
- [ ] Bug Library link appears after first version bump
- [ ] Each unlock has a one-time descriptive prompt that converts to compact link after first visit
- [ ] Unlock prompts animate in (slide + fade)
- [ ] `NavigationStack` pushes to History, Patterns, Bug Library, Docs
- [ ] Full nav bar appears after 14+ active days and 10+ fixes
- [ ] Nav bar uses monospaced text labels, not icons
- [ ] `···` overflow menu contains Bug Library, Docs, Settings
- [ ] Minimal `SettingsView` exists with bug priority adjustment and reset
- [ ] Unlock triggers fire correctly from fix completion, diagnostic, pattern detection
- [ ] Days active increments correctly (once per calendar day)
- [ ] No empty/dead-end screens visible before their unlock threshold
- [ ] All existing tests pass
- [ ] Project builds with 0 errors

R4_PROGRESSIVE_DISCLOSURE_EOF

# --- tasks/r4-progressive-disclosure/progress.md ---
cat > tasks/r4-progressive-disclosure/progress.md << 'PROGRESS_EOF'
# Progress

## Status: Not Started

## Completed
(none)

## Issues
(none)
PROGRESS_EOF

# --- tasks/r5-tone-polish/plan.md ---
cat > tasks/r5-tone-polish/plan.md << 'R5_TONE_POLISH_EOF'
# Task: R5 — Tone & Polish

**Status**: Pending
**Branch**: r5-tone-polish
**Depends on**: R2 (Today view), R3 (onboarding), R4 (progressive disclosure)
**Goal**: Inject the brand voice everywhere it's missing. Streamline the crash flow to 2 taps. Render weekly diagnostics inline. Audit every screen for personality. Ensure every fix has an inline comment.

## Context

Read CLAUDE.md for project context and `egofix-ux-redesign.md` (section 5: Tone Injection Points).

The brand voice is: **"A smart friend who sees through your shit and likes you anyway."** Deadpan, dry, knowing. Never preachy, never generic.

After R1-R4, the structure is right but the personality is still inconsistent. This task is a full tone audit + targeted feature refinements.

## What to Build

### 1. Crash Flow Streamline (2 Taps)

Current flow: Crash button → `CrashInitialView` ("Something resurfaced?" + `[ Log Crash ]`) → `CrashBugSelectView` (select bug + optional note + `[ Confirm Crash ]`) → `CrashLoggedView` ("It happens." + `[ Reboot ]`) → `QuickFixView`

That's 4 screens. Reduce to 2:

**Tap 1: Crash button → immediate bug selection**

Remove `CrashInitialView` entirely. When the crash sheet opens, go straight to bug selection:

```
CRASH

[ The Corrector    ]
[ The Chameleon    ]
[ The Scorekeeper  ]

// optional note _______________
```

Tapping a bug **immediately logs the crash** (no separate confirm button). The note field is visible and editable but submitting it is not required — crash is logged on bug tap.

**Tap 2: Crash logged → quick fix offered**

```
LOGGED.

[Soul animation — loud intensity]

// It happens.
// That's the whole point of logging.

[ Quick fix → ]     [ Done ]
```

Show the crashed bug's soul at loud intensity. Quick fix is offered but optional. `[ Done ]` dismisses the sheet.

Modify: `CrashView.swift`, `CrashViewModel.swift`
Delete: `CrashInitialView` struct

### 2. Weekly Diagnostic Inline

Current: diagnostic is a sheet. Move it into the Today view state machine.

When it's Sunday evening / Monday morning and the diagnostic hasn't been completed this week:

**Today view shows diagnostic instead of fix:**

```
v1.3            ∙∙∙ 7

     [soul animation]

WEEKLY DIAGNOSTIC

This week, The Corrector felt...

[ Quiet ]   [ Present ]   [ Loud ]

// 2 more bugs to check
```

After rating all bugs (max 3), inline completion:

```
DIAGNOSTIC COMPLETE

The Corrector: present
The Chameleon: quiet
The Scorekeeper: loud

// Data logged.
// Tomorrow's fix will account for this.

[ Continue → ]
```

`[ Continue → ]` transitions to the daily fix (if available) or done-for-today.

Implementation:
- Add `.diagnostic` state to TodayViewModel state machine (may already exist from R2)
- Render the diagnostic flow as inline views in the Today ScrollView
- Reuse the diagnostic logic from `WeeklyDiagnosticViewModel` / `WeeklyDiagnosticService`
- Keep the "skip" option visible: small `[ skip → ]` below the diagnostic
- After completion, run `DiagnosticEngine.runDiagnostics()` to check for new patterns

Modify: `TodayView.swift`, `TodayViewModel.swift`
May modify: `WeeklyDiagnosticView.swift` (extract reusable components or replace entirely)

### 3. Fix Seed Data Audit — Inline Comments

Every fix in `fixes.json` / seed data should have an `inlineComment`. Currently some fixes have `null` for this field.

Audit all 294 fixes. For any fix with `inlineComment: null`, add one. The comment should follow these rules:

**Good inline comments:**
- Reframe the behavior (not repeat the prompt)
- Surface the ego mechanism behind the action
- Use `//` comment syntax naturally
- Are 1-2 lines, never more than 3
- Sound like a knowing friend, not a therapist

**Examples of good comments:**
```
// The urge to correct isn't about accuracy. It's about status.
// Notice what happens in your body when you don't intervene.
// You're performing. For whom?
// Silence after conflict isn't failure. It's restraint.
// The discomfort is the fix working.
```

**Examples of bad comments (don't write these):**
```
// This might be hard.          ← too obvious
// Try your best!               ← wrong tone entirely
// Remember to be mindful.      ← generic wellness speak
// You can do it.               ← empty validation
```

Modify: `EgoFix/Resources/SeedData/fixes.json`

This is a content task — it requires reading each fix prompt and writing a comment that adds insight. It's the most important quality pass in the entire redesign.

### 4. Screen-by-Screen Tone Audit

Go through every user-facing view and fix copy that's too neutral, too generic, or missing personality.

**Fix Card (`FixCardView.swift`):**
- The `// bug-name` caption should use the "friendly name" not the slug: `// The Corrector` not `// need-to-be-right`
- Severity label: change from `SEVERITY: Medium` to `// severity: medium` (lowercase, comment style, less shouty)

**History View (`HistoryView.swift`):**
- Section headers should have personality. Instead of just "CHANGELOG", try: `CHANGELOG // v1.0 → v{current}`
- Empty state (if somehow visible): `// Nothing here yet. That changes tomorrow.`
- Stats section: keep data-forward but add one status line. E.g., after showing fix counts: `// Most skipped bug: The Corrector. Interesting.`

**Patterns View (`PatternsView.swift`):**
- Header: Keep `DETECTED PATTERNS` but add a subtitle that changes:
  - If patterns exist: `// The app noticed {count} things.`
  - If all dismissed: `// All caught up. The app is still watching.`
- Empty state: `// Patterns emerge from data. Keep logging.`

**Bug Library (`BugLibraryView.swift`):**
- Header: `BUG LIBRARY // {active} active, {total} identified`
- Bug rows: show the soul animation (small) instead of a static icon/text

**Bug Detail (`BugDetailView.swift`):**
- Status comments should have more voice:
  - Identified: `// Detected but not yet under active monitoring.`
  - Active: `// The app is tracking this. Fixes are calibrated.`
  - Stable: `// Hasn't fired in a while. Don't get comfortable.`
  - Resolved: `// Marked resolved. The app will check back in 30 days.`

**Crash Logged (after streamline):**
- Rotate through a few messages instead of always "It happens.":
  - `// It happens. That's the whole point of logging.`
  - `// Crash logged. You caught it. That's progress.`
  - `// The bug won this round. You'll get another.`
  - `// Noted. No judgment. Just data.`

**Done-for-Today State:**
- Rotate status lines (already built in R2, verify pool is large enough — add more if needed)
- Week summary: `// This week: 4 applied, 1 skipped, 0 failed. Steady.`

### 5. Pattern Alert Copy Polish

Verify pattern alerts (from M3) still sound right in context. The patterns should feel like the app **noticing something**, not lecturing:

Good: `"You've skipped 4 of 7 fixes about listening. When The Corrector is loud, listening goes first."`
Bad: `"Consider addressing your avoidance of listening-related exercises."`

Check all 6 detector output templates and the `RecommendationEngine` copy. If M3 already polished these, verify they still fit. If not, rewrite.

### 6. Streak Commentary

Verify the streak milestone commentary (from R2) is implemented. These should appear as tiny gray subtitles below the streak number on specific days:

| Day | Comment |
|-----|---------|
| 7 | `// This metric is meaningless.` |
| 14 | `// You're still here.` |
| 21 | `// Consistency is just a pattern. Like the others.` |
| 30 | `// The app should be getting quieter by now.` |
| 60 | `// Two months. You've outlasted most.` |
| 90 | `// At this point, you're debugging the debugger.` |

One-day visibility only. After that day, the comment disappears and the streak is just a number again until the next milestone.

### 7. Loading / Error States

Add personality to any loading or error states:

**Loading:** `> loading...` (not a generic spinner — use a blinking cursor or `> _`)

**Error:** 
```
// Something broke.
// Not your ego this time. The app.
// Try again.
```

**Network error (if applicable in future):**
```
// Can't reach server.
// The work is still local.
```

## Steps

1. Streamline crash flow: remove CrashInitialView, auto-log on bug tap, 2-screen flow
2. Build inline weekly diagnostic in TodayView
3. Audit all 294 fixes for inline comments — add missing ones
4. Screen-by-screen tone audit: fix card, history, patterns, bug library, bug detail, crash, done state
5. Verify pattern alert and recommendation copy
6. Implement streak milestone commentary
7. Add personality to loading/error states
8. Run full test suite — update crash-related tests for new 2-tap flow
9. Write tests for inline diagnostic state transitions
10. Build — 0 errors

## Important Notes

- **The inline comment audit is the highest-value item.** Every fix should feel like it was written by someone who knows you. Don't write generic filler.
- **Don't make the app chatty.** One status line per screen. One comment per section. The voice should be sparse and precise — a single knowing remark, not a paragraph.
- **The crash streamline is about friction reduction.** Two taps to log a crash. No "are you sure?" confirmation. Crashes should be as easy to log as muscle memory.

## Acceptance Criteria

- [ ] Crash flow is 2 screens: bug selection → logged (no intermediate "Something resurfaced?" screen)
- [ ] Crash logs on bug tap (no separate confirm button)
- [ ] Weekly diagnostic renders inline in Today view (not as a sheet)
- [ ] Diagnostic completion transitions to fix or done-for-today
- [ ] All 294 fixes have non-null `inlineComment` values
- [ ] All inline comments follow brand voice (reframe, don't repeat; knowing, not generic)
- [ ] Fix card shows bug friendly name, not slug
- [ ] Fix card severity is lowercase comment style, not SCREAMING
- [ ] History, Patterns, Bug Library, Bug Detail views have audited copy
- [ ] Crash confirmation messages rotate from a pool
- [ ] Streak milestone commentary appears on correct days
- [ ] Loading states use terminal-style indicator (not generic spinner)
- [ ] Error states have personality
- [ ] All existing tests pass (update crash flow tests)
- [ ] Project builds with 0 errors

R5_TONE_POLISH_EOF

# --- tasks/r5-tone-polish/progress.md ---
cat > tasks/r5-tone-polish/progress.md << 'PROGRESS_EOF'
# Progress

## Status: Not Started

## Completed
(none)

## Issues
(none)
PROGRESS_EOF

# --- tasks/r6-transitions/plan.md ---
cat > tasks/r6-transitions/plan.md << 'R6_TRANSITIONS_EOF'
# Task: R6 — Transitions & Feel

**Status**: Pending
**Branch**: r6-transitions
**Depends on**: R1-R5 (all previous redesign phases)
**Goal**: Make state transitions feel cohesive and intentional. Soul reacts to outcomes. Screens flow into each other. The app feels like a single living surface, not a collection of views.

## Context

Read CLAUDE.md for project context and `egofix-ux-redesign.md` (section on transitions).

After R1-R5, all the pieces are in place: animated souls, rebuilt Today hub, progressive disclosure, consistent tone. This final phase makes the seams disappear. Every state change should feel deliberate — fast but not abrupt, smooth but not bouncy.

**Animation principles for EgoFix:**
- Fast and crisp (0.15-0.35s). No spring physics, no bounce.
- Use `.easeOut` or `.linear` — never `.spring` or `.bouncy`
- Opacity + position changes, not scale (terminal text doesn't zoom)
- Text appears by typing, not by fading in
- The soul is the constant — it reacts, everything else changes around it

## What to Build

### 1. Soul Reaction to Outcomes

When the user marks a fix outcome, the soul should **visibly react** before the completion message appears:

**Applied (+):**
- Soul briefly shifts one intensity level quieter (e.g., present → quiet animation for 2 seconds)
- Soul color pulses brighter once (opacity 1.0 flash, then settles back)
- This signals: "the pattern responded to the fix"

**Skipped (~):**
- Soul does nothing. No reaction. Stays at current intensity.
- This signals: "the pattern doesn't care that you skipped"

**Failed (x):**
- Soul briefly flickers/glitches (2-3 rapid frame jumps, like a VHS tracking error)
- Soul shifts one intensity level louder for 2 seconds, then returns to normal
- This signals: "the pattern noticed"

Implementation:
```swift
// In BugSoulView, add a reaction modifier:
struct BugSoulView: View {
    // ... existing properties
    var reaction: SoulReaction?
    
    enum SoulReaction {
        case applied    // flash quiet
        case failed     // glitch loud
    }
}
```

The reaction is a temporary override of the intensity — triggered by the parent view, lasting ~2 seconds, then returning to the data-driven intensity.

### 2. Fix Card Entrance

When the Today view loads with a new fix, the fix card should **slide up from below the soul**:

- Soul is already visible and animating
- Fix card starts off-screen (below viewport)
- Slides up to its resting position with `.easeOut` over 0.3s
- Slight delay after soul appears (0.5s) so the user sees the soul first

```swift
// Example approach:
.transition(.move(edge: .bottom).combined(with: .opacity))
```

### 3. Outcome to Done-State Transition

After marking an outcome:
1. Action buttons fade out (0.15s)
2. Fix card content fades out (0.2s)
3. Soul reaction plays (see #1 above, 1-2 seconds)
4. Outcome symbol (+/~/x) types in below the soul
5. Outcome message types in (existing TypewriterText from R3)
6. Micro-education tidbit fades in (if applicable)
7. After typing completes (2-3 seconds), transition to done-for-today:
   - Outcome text fades out (0.2s)
   - Done-state content fades in: status line, week summary, footer links (0.3s, staggered)

The soul **never disappears** during this transition. It's the constant element.

### 4. State Transition Orchestration

Create a transition coordinator that manages the timing of multi-step transitions:

```swift
class TransitionCoordinator: ObservableObject {
    @Published var phase: TransitionPhase = .idle
    
    enum TransitionPhase {
        case idle
        case exitingContent     // current content fading out
        case soulReacting       // soul playing reaction
        case enteringContent    // new content appearing
    }
    
    func transition(from: TodayState, to: TodayState, soulReaction: SoulReaction?) async {
        // Phase 1: exit current content (0.2s)
        // Phase 2: soul reaction (1-2s, or 0s if no reaction)
        // Phase 3: enter new content (0.3s)
    }
}
```

Or implement via `withAnimation` chains with `DispatchQueue.main.asyncAfter` delays. Keep it simple — a full coordinator class is optional if inline animations work cleanly.

### 5. Diagnostic Inline Transitions

When the diagnostic flow progresses through bugs:
- Current bug's rating buttons fade out
- Next bug's soul + name + buttons slide in from the right
- The transition should feel like flipping through cards

On diagnostic completion:
- Diagnostic content fades out
- Summary types in (completion message)
- Then transitions to fix or done-for-today

### 6. Pattern Alert Entrance

When a pattern surfaces:
- Pattern card slides down from below the soul (pushes fix card down or replaces it)
- Subtle red/yellow border pulse on the card (1 pulse, not repeating)
- `[ Noted ]` button glows briefly
- On dismiss: card slides up and out, fix card slides back in from below

### 7. Crash Sheet Transitions

The crash sheet should feel urgent:
- Sheet background: slightly red-tinted black (very subtle, like `Color.red.opacity(0.03)` mixed with black)
- Bug list items appear with staggered delay (50ms each) — creates a rapid cascade effect
- On crash logged: brief screen flash (red overlay at 0.1 opacity for 100ms, then fade)
- Soul at loud intensity slams in (no gentle fade — appears instantly)

### 8. Unlock Moment Transitions (Progressive Disclosure)

When a new section unlocks (from R4):
- The footer area expands smoothly to accommodate the new link
- Comment line (`// 3 fixes logged...`) types in with TypewriterText
- Link fades in 0.5s after the comment finishes typing
- Total unlock animation: ~2 seconds

### 9. Boot Sequence Transitions (Subsequent Launches)

On subsequent cold launches (abbreviated boot from R3):
- `> v{version} resuming...` types in
- Brief glitch on version number
- Cross-fade to Today view (0.3s)
- Soul is already animating when Today appears (no delay)

### 10. Navigation Push/Pop

When navigating to History, Patterns, etc. via footer links or nav bar:
- Standard `NavigationStack` push animation, but verify it doesn't break the terminal aesthetic
- Navigation bar should be hidden or styled minimally (`.toolbar(.hidden, for: .navigationBar)`)
- Back button: `[ ← back ]` in monospaced font, not default iOS chevron
- Or use a custom back button: `[ ← today ]`

```swift
.navigationBarBackButtonHidden(true)
.toolbar {
    ToolbarItem(placement: .navigationBarLeading) {
        Button("[ ← today ]") { dismiss() }
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(.gray)
    }
}
```

### 11. Micro-Interactions Polish

Small things that make the app feel alive:

- **Cursor blink**: On any screen with typewriter text, show a blinking cursor `_` at the end of the last typed line (0.5s on, 0.5s off). Cursor disappears when new content appears.
- **Button press feedback**: Action buttons (Applied/Skipped/Failed) should briefly invert colors on press (white text on colored background → colored text on dark background). Not a scale animation — just a color flash.
- **Scroll indicator**: If the Today view needs scrolling, use a subtle `↓` indicator that fades out once the user scrolls.

## Steps

1. Implement soul reactions (applied: quiet flash, skipped: nothing, failed: glitch)
2. Add fix card entrance animation (slide up from below soul)
3. Build outcome → done-for-today transition sequence
4. Add diagnostic flow transitions (bug-to-bug, completion)
5. Add pattern alert entrance/exit animations
6. Style crash sheet (red tint, staggered list, flash on log)
7. Add unlock moment animations (typing comment + fade-in link)
8. Style subsequent-launch boot transition
9. Customize navigation push/pop (monospaced back button, hidden nav bar)
10. Add micro-interactions: cursor blink, button press feedback, scroll indicator
11. Performance check: verify animations don't cause frame drops on older devices
12. Test all transitions end-to-end: launch → fix → outcome → done → crash → diagnostic → pattern
13. Verify no animation conflicts (e.g., soul reaction + content transition happening simultaneously)
14. All existing tests pass
15. Build — 0 errors

## Important Notes

- **The soul never disappears.** It's the constant in every transition. Everything else can fade/slide/type, but the soul stays anchored.
- **No spring physics.** This is a terminal, not a social media app. Animations should be crisp: `.easeOut` or `.linear`, 0.15-0.35s duration. No overshoot, no wiggle, no bounce.
- **Typing > fading for text.** When new text appears, it should type in (character by character) unless it's a label or data field. Typing feels like a terminal. Fading feels like iOS.
- **Don't over-animate.** If in doubt, cut the animation. The app's power comes from its restraint. One well-placed reaction is worth ten smooth transitions.
- **Test on device.** Simulator doesn't accurately show animation performance. If you can't test on device, keep animations simple and use `drawingGroup()` on complex views.

## Acceptance Criteria

- [ ] Soul reacts to applied (brief quiet shift), failed (glitch), skipped (nothing)
- [ ] Soul reaction lasts ~2 seconds then returns to data-driven intensity
- [ ] Fix card slides up from below soul on load
- [ ] Outcome → done-for-today is a smooth multi-step sequence (buttons out → soul reacts → outcome types → done fades in)
- [ ] Soul remains visible and animated throughout all transitions
- [ ] Diagnostic transitions between bugs feel like card flipping
- [ ] Pattern alerts slide in/out smoothly
- [ ] Crash sheet has red tint, staggered bug list, flash on log
- [ ] Unlock moments: comment types in, link fades in
- [ ] Navigation uses monospaced `[ ← today ]` back button, not iOS default
- [ ] Cursor blinks at end of typed text
- [ ] Button press gives color-flash feedback (not scale)
- [ ] No spring/bounce animations anywhere
- [ ] All animation durations between 0.15-0.35s (except soul reactions and typing)
- [ ] No frame drops during transitions
- [ ] All existing tests pass
- [ ] Project builds with 0 errors

R6_TRANSITIONS_EOF

# --- tasks/r6-transitions/progress.md ---
cat > tasks/r6-transitions/progress.md << 'PROGRESS_EOF'
# Progress

## Status: Not Started

## Completed
(none)

## Issues
(none)
PROGRESS_EOF


echo ""
echo "✓ CLAUDE.md updated"
echo "✓ egofix-ux-redesign.md created"
echo "✓ tasks/r1-soul-system/plan.md + progress.md"
echo "✓ tasks/r2-today-rebuild/plan.md + progress.md"
echo "✓ tasks/r3-onboarding-rewrite/plan.md + progress.md"
echo "✓ tasks/r4-progressive-disclosure/plan.md + progress.md"
echo "✓ tasks/r5-tone-polish/plan.md + progress.md"
echo "✓ tasks/r6-transitions/plan.md + progress.md"
echo ""
echo "Now run:"
echo "  git add -A && git commit -m 'Add R1-R6 UX redesign plans + updated CLAUDE.md'"
echo "  git push"
