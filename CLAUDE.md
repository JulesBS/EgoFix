# EgoFix - Claude Project Guide

> See `egofix-detailed-spec.md` for full model definitions, TDD test plan, detector thresholds, UI copy examples, and content requirements.
> See `egofix-bugs-redesign.md` for the definitive bug list (7 bugs), fix examples by interaction type, and content pipeline targets. This is the source of truth for all bug/fix content.

## Vision

EgoFix is an iOS app for ego reduction through daily missions ("fixes"). Users identify their ego "bugs" (e.g., need-to-be-right, need-to-be-liked) and receive daily fixes to work on them. The app surfaces behavioral blind spots through daily challenges, tracks patterns over time, and eventually shows users things about themselves they didn't know.

**Brand voice:** "A smart friend who sees through your shit and likes you anyway." Deadpan, dry, knowing. Never preachy, never gentle, never condescending.

**Design metaphor:** Ego defense mechanisms = faulty code. Ego patterns = bugs in the user's operating system. The app = a debugger. Challenges = fixes. Progress = version numbers. Bad days = crashes (stack traces). The aesthetic is terminal/IDE — monospace fonts, dark mode, muted syntax-highlighting colors. Not a wellness app.

**Engagement philosophy:** Engagement mechanics are the delivery system, not the product. Every mechanic must pass one test: does it deliver the user to a moment of genuine self-awareness? Streaks, notifications, and variable rewards are tools — what matters is what they deliver the user to. We meet users where they are (dopamine-conditioned, notification-saturated) and use that conditioning to create moments of genuine self-awareness.

---

## Tech Stack

- **Language**: Swift 5
- **UI**: SwiftUI with MVVM architecture
- **Persistence**: SwiftData (local-first)
- **Testing**: XCTest
- **Minimum iOS**: 18.0
- **Widget**: WidgetKit (App Group: `group.egofix.shared`)
- **Live Activity**: ActivityKit

## Architecture

```
EgoFix/
├── Models/           # SwiftData @Model classes
├── Views/            # SwiftUI views organized by feature
│   ├── Today/        # Daily mission flow (briefing → active → check-in)
│   ├── History/      # Past completions
│   ├── Onboarding/   # Bug selection flow
│   ├── Settings/     # Notification times, preferences
│   └── Components/   # Reusable UI components
│       └── Interactions/  # 14 interaction type views
├── ViewModels/       # @Observable view models
├── Services/         # Business logic (DailyFixService, etc.)
├── Repositories/     # Data access layer with protocols
└── Resources/        # SeedData JSON files

EgoFixWidget/
├── EgoFixWidget.swift           # Widget views + timeline provider
├── EgoFixWidgetLiveActivity.swift  # Live Activity views
├── LiveActivityAttributes.swift    # Shared between app + widget
└── SharedTypes.swift              # SharedFixState + WidgetStorageManager
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

All design tokens live in `EgoTheme.swift` (single source of truth).

### Colors
- **Background**: `EgoTheme.bg` — #131313 (warm dark, not pure black)
- **Text primary**: `EgoTheme.textPrimary` — #E5E2E1 (warm off-white)
- **Text muted**: `EgoTheme.textMuted` — #84967E (sage green for secondary text, labels, comments)
- **Green accent**: `EgoTheme.green` — #00FF41 (success, validation, active states)
- **Amber**: `EgoTheme.amber` — #FDAF00 (warning, pending)
- **Red**: `.red` (error, crash — no custom token yet)
- **Accent colors**: Cyan, Mint, Indigo, Pink, Teal, Purple, Orange, Blue for interaction types
- **Surface**: `EgoTheme.surface` — #353534 (card/button backgrounds)
- **Border**: `EgoTheme.border` — olive-green at 0.4 opacity
- **Glass**: `.glassCard()` modifier — `.ultraThinMaterial` + dark glass base

### Typography
- **Body text**: `EgoTheme.mono()` — system monospaced at body size
- **Labels**: `EgoTheme.label()` — caption2 monospaced, use with `.tracking(1.5-2.8)`
- **Headings**: `EgoTheme.heading(size)` — light weight monospaced

### Spacing
- 4pt (tight) → 8pt (small) → 12pt (medium) → 16pt (default) → 24pt (large) → 32pt (xl)

### Shared Components
- `InteractionHeader` — type label + status for fix interaction views
- `InlineCommentView` — italic `// comment` display
- `.interactionCard(borderColor:)` — card shell for all 14 interaction views
- `FigmaCTAButton` — uppercase tracked CTA with arrow
- `FigmaSecondaryButton` — text-only secondary action
- `TerminalLoading` — animated `> loading...` indicator
- `TerminalEmptyState` — comment-style empty state
- `TerminalTabSelector` — horizontal tab bar
- `TerminalDivider` — 0.5pt themed divider
- `CornerBracket` / `.cornerBrackets()` — corner bracket decoration
- `.greenGlow()` — green shadow matching Figma spec
- `.glassCard()` — glass-morphism card with border

### Rules
- **Always** use `EgoTheme` tokens, never hardcode colors or fonts
- **Corners**: Minimal rounding (2-4pt) or sharp (0pt for glass cards)
- **Dismiss buttons**: ASCII `[ x ]`, not SF Symbols
- **Never**: Gradients, nature imagery, wellness aesthetic, emojis in app copy

---

## Daily Mission Flow

Every fix (except timed/quiz/scenario) is a **daily mission** — accepted in the morning, carried throughout the day, checked in at wind-down.

### State Machine (TodayViewState)
```
loading → [diagnostic → diagnosticComplete] → fixBriefing → fixActive → [checkIn] → completed → debrief → doneForToday
                                                                ↑
                                               fixAvailable (timed/quiz/scenario — immediate)
```

### Morning Briefing (FixBriefingView)
Shows a **teaser card** — bug name, type label, severity bar, estimated time, version. Does NOT show the prompt. Creates a curiosity gap. `[ ACCEPT MISSION ]` reveals the fix.

**Type labels** (from `InteractionType.typeLabel`):
- standard → "A practice", counter → "Track a pattern", observation → "Something to notice"
- abstain → "A challenge", substitute → "A swap", journal → "A question"
- reversal → "Do the opposite", predict → "A test", body → "A body scan"
- audit → "End-of-day review", multiStep → "A sequence"
- timed → "Sit with it", quiz → "Self-assessment", scenario → "A situation"

### Active Mission (FixActiveView)
Prompt revealed with fade-in animation. Shows:
1. **Header**: "MISSION / ACTIVE" pulsing label + countdown to wind-down time
2. **Prompt + inline comment**
3. **Interaction UI** for interactive types (counter/substitute/abstain/body)
4. **Education section**: Teaser always visible + expandable deep dive (`[ read more ]`)
5. **2-step outcome buttons**: `[ APPLIED ]` `[ DIDN'T ]` → if DIDN'T: `[ DIDN'T TRY ]` `[ TRIED, COULDN'T ]`

No crash button. No separate check-in screen needed — outcomes available anytime.

### Outcome Mapping
- APPLIED → `.applied`
- DIDN'T TRY → `.skipped` (life got in the way)
- TRIED, COULDN'T → `.failed` (the bug won — valuable data)

### Post-Outcome Flow
Completion animation (3s: symbol → title → typed message → education tidbit) → optional debrief → doneForToday

### Immediate Types (timed/quiz/scenario)
Still get morning briefing teaser → accept → but complete right there in the app via `FixCardView`. No day-long mission timer.

---

## Fix Interaction Types

| Type | Description | Config Struct | Outcome Struct |
|------|-------------|---------------|----------------|
| `standard` | Simple prompt | None | None |
| `timed` | Timer must complete | `TimedConfig` | `TimedOutcome` |
| `multiStep` | Sequential steps | `MultiStepConfig` | `MultiStepOutcome` |
| `quiz` | Multiple choice | `QuizConfig` | `QuizOutcome` |
| `scenario` | Situation + response | `ScenarioConfig` | `ScenarioOutcome` |
| `counter` | Track occurrences | `CounterConfig` | `CounterOutcome` |
| `observation` | Notice something, report back | `ObservationConfig` | `ObservationOutcome` |
| `abstain` | Go a period WITHOUT doing something | `AbstainConfig` | `AbstainOutcome` |
| `substitute` | When urge X arises, do Y instead | `SubstituteConfig` | `SubstituteOutcome` |
| `journal` | Short text prompt, 2-3 sentences | None | None (uses reflection) |
| `reversal` | Do the opposite of your default | None | None |
| `predict` | Predict outcome, then observe reality | `PredictConfig` | `PredictOutcome` |
| `body` | Region + sensation picker for somatic awareness | `BodyConfig` | `BodyOutcome` |
| `audit` | End-of-day review of behaviors | `AuditConfig` | `AuditOutcome` |

### Special interaction features
- **body**: Chip picker for body regions (jaw, chest, hands...) + sensations (tension, heat, tightness...). Must select ≥1 of each.
- **abstain**: Countdown timer when `durationSeconds` is set in config. Slip button logs slips with timestamps (doesn't reset timer). Toggle fallback when no duration.
- **counter/substitute**: Tracking UI available on active mission screen (not just check-in).

## The Seven Ego Bugs

| Slug | Title | Color |
|------|-------|-------|
| need-to-be-right | Need to be right | Red/orange |
| need-to-impress | Need to impress | Purple/indigo |
| need-to-be-liked | Need to be liked | Cyan/teal |
| need-to-control | Need to control | Yellow/amber |
| need-to-compare | Need to compare | Green |
| need-to-deflect | Need to deflect | Gray/silver |
| need-to-narrate | Need to narrate | Blue/dark blue |

**No character nicknames.** The slug IS the display name. Ego patterns are bugs to fix, not personality types to wear.

See `egofix-bugs-redesign.md` for full descriptions, root mechanisms, daily-life examples, and 100+ fix examples across all interaction types.

---

## Content Architecture

### Micro-Education (Two-Tier)
Each of the 210 micro-education entries has three content fields:
- **`body`**: Original single-paragraph education (backward compat)
- **`teaser`**: 1-2 punchy sentences, always visible on mission screen. The hook.
- **`deepDive`**: 2-3 paragraphs, expandable via "read more". Psychology, neuroscience, the "why."

Fallback: `MicroEducation.effectiveTeaser` extracts first sentence of `body` if `teaser` is nil.

### Content Tone Rules
- Fixes are specific and observational: "Count how many sentences you start with 'I' today" not "be more humble"
- Inline comments reframe, don't repeat: `// The urge to correct isn't about accuracy. It's about status.`
- Education uses code/debugger metaphors: "This bug fires when...", "The subroutine runs before you're conscious of it", "Your ACC daemon has the sensitivity cranked to max"
- Psychology references framed through code: "Festinger's research basically says your comparison module runs on a relative scale, not absolute"
- Failure is data, not shame: "No fanfare. You did the thing." / "Bug won. Data logged."
- **Never**: mindful, healing, journey, gentle, kind to yourself, self-care, proud of you, great job, wellness language of any kind

### Seed Data (293 fixes, 210 education entries)
- 42 fixes per bug (7 bugs) across 14 interaction types
- ~40% low severity, ~40% medium, ~20% high
- Mix of daily (196), quickFix (48), weekly (50)
- All interaction types with configs have proper configuration data

---

## Widget (4 Mission States)

Widget communicates with app via `SharedFixState` in App Group UserDefaults.

| State | What Shows | Trigger |
|-------|-----------|---------|
| **Waiting** | Bug + type label + severity. No prompt. "Mission waiting." | Fix assigned, not accepted |
| **Active** | Prompt + countdown + inline comment | Fix accepted |
| **Check-in** | "Time to check in." | Wind-down time reached |
| **Done** | Outcome symbol + status line | Outcome marked |

Widget sizes: systemSmall, systemMedium, accessoryRectangular, accessoryCircular.

## Live Activity
- Starts on mission accept (all day-long fixes, not just timed)
- Shows prompt + countdown to wind-down time
- **7-hour stale cap** — widget takes over after
- Ends on outcome mark or stale timeout

## Notifications

| When | Content | ID |
|------|---------|-----|
| Morning (configurable, default 8am) | "Fix #042 is ready." | `morning_reminder` |
| Wind-down (configurable, default 9pm) | "Time to check in on Fix #042." | `fix_winddown_{id}` |
| Weekly (stable streak ≥7 days) | "Still running smoothly?" | `anti_notification` |

**Never send**: "You forgot!", streak-at-risk guilt, mid-day check-ins, social notifications, re-engagement nagging.

## Settings (AppProgressTracker)
- `windDownTime: String` — "HH:mm", default "21:00". Also sets mission end time.
- `morningNotificationTime: String` — "HH:mm", default "08:00"
- `antiNotificationsEnabled: Bool` — default true

---

## Pattern Detection (Built)

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

## Anti-Patterns (Never Build These)

- Badges or achievements
- XP or rank systems
- Social leaderboards
- Friend activity feeds ("3 friends applied fixes today")
- Loot drops / daily spin / random rewards
- Seasonal FOMO events
- Any mechanic that rewards volume of taps over depth of engagement
- "You're doing great!" or any variation
- Wellness language, therapy speak, "healing journey" framing
- Standalone crash button (crashes are captured via 2-step outcome: "Tried, couldn't")

---

## Build & Test Commands

```bash
# Build (use Xcode MCP build_project when available)
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
| `Models/Fix.swift` | Core fix model + InteractionType enum with typeLabel, estimatedTime, teaserComment |
| `Models/FixConfiguration.swift` | Config structs (TimedConfig, QuizConfig, BodyConfig, AbstainConfig, etc.) |
| `Models/FixCompletionData.swift` | Outcome structs (BodyOutcome, AbstainOutcome with SlipEvent, etc.) |
| `Models/MicroEducation.swift` | Education model with body, teaser, deepDive + effectiveTeaser/effectiveDeepDive |
| `ViewModels/TodayViewModel.swift` | Core state machine — mission flow, education, countdown, widget sync |
| `ViewModels/FixInteractionManager.swift` | Manages all 14 interaction type states |
| `Views/Today/FixBriefingView.swift` | Morning teaser card (no prompt) |
| `Views/Today/FixActiveView.swift` | Active mission (countdown, education, 2-step outcome) |
| `Views/Today/CheckInView.swift` | Check-in with 2-step outcome flow |
| `Views/Components/FixCardView.swift` | Immediate fix display (timed/quiz/scenario) |
| `Services/DailyFixService.swift` | Fix assignment and completion logic |
| `Services/AppProgressTracker.swift` | Wind-down time, morning time, feature unlock tracking |
| `Services/SharedStorageManager.swift` | App ↔ Widget communication via App Group |
| `Services/LiveActivityService.swift` | Live Activity lifecycle (7h cap) |
| `Services/NotificationService.swift` | Morning, wind-down, anti-notifications |
| `Resources/SeedData/fixes.json` | 293 fixes with configs |
| `Resources/SeedData/micro_education.json` | 210 education entries with teaser + deepDive |

## Seed Data Format

### Fix
```json
{
  "id": "uuid",
  "bugSlug": "need-to-be-right",
  "type": "daily",
  "severity": "medium",
  "interactionType": "body",
  "prompt": "Scan your body next time you suppress a correction",
  "validation": "Did you notice a sensation?",
  "inlineComment": "The correction you didn't say is still in your body somewhere.",
  "configuration": {
    "body": {
      "scanRegions": ["Jaw", "Chest", "Hands", "Shoulders", "Throat", "Stomach"],
      "sensationDescriptors": ["Tension", "Heat", "Tightness", "Clenching", "Pressure", "Buzzing"]
    }
  }
}
```

### Micro-Education
```json
{
  "id": "me-right-01",
  "bugSlug": "need-to-be-right",
  "trigger": "postApply",
  "body": "The urge to correct is a status signal...",
  "teaser": "This bug fires fastest when you feel outranked.",
  "deepDive": "Your ACC daemon has the sensitivity cranked to max..."
}
```

## Common Tasks

### Adding a new fix interaction type
1. Add case to `InteractionType` enum in `Fix.swift` (+ typeLabel, estimatedTime, teaserComment)
2. Create config struct in `FixConfiguration.swift`
3. Create outcome struct in `FixCompletionData.swift`
4. Add config accessor to `Fix` extension
5. Handle in `FixInteractionManager.swift` (state, setup, canMarkApplied, generateOutcome)
6. Create view in `Views/Components/Interactions/`
7. Add case to `FixInteractionView.swift` switch
8. Add to SeedDataLoader's `SeedFixConfiguration`
9. Add tests
10. Update `isImmediate` if needed

### Adding a new bug type
1. Add to `Resources/SeedData/bugs.json`
2. Add related fixes to `Resources/SeedData/fixes.json`
3. Add micro-education entries to `Resources/SeedData/micro_education.json` (with teaser + deepDive)

## Notes

- SwiftData models use `@Attribute(.unique)` for IDs
- All async service methods use `async throws`
- Views use `@StateObject` for owned view models
- Timer functionality uses `TimerService` with `TimerSession` model
- Live Activities supported for all day-long fixes (7h cap), not just timers
- Widget is the primary persistent presence (survives after LA dies)
- `SharedFixState` defined in both `SharedStorageManager.swift` (app) and `SharedTypes.swift` (widget) — must stay in sync
- `AbstainOutcome` has custom `init(from:)` decoder for backward compatibility with older stored data
