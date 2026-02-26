# EgoFix - Claude Project Guide

> See `egofix-detailed-spec.md` for full model definitions, TDD test plan, detector thresholds, UI copy examples, and content requirements.
> See `egofix-bugs-redesign.md` for the definitive bug list (7 bugs), fix examples by interaction type, and content pipeline targets. This is the source of truth for all bug/fix content.

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

| Slug | Title | Nickname | Color |
|------|-------|----------|-------|
| need-to-be-right | Need to be right | The Corrector | Red/orange |
| need-to-impress | Need to impress | The Performer | Purple/indigo |
| need-to-be-liked | Need to be liked | The Chameleon | Cyan/teal |
| need-to-control | Need to control | The Controller | Yellow/amber |
| need-to-compare | Need to compare | The Scorekeeper | Green |
| need-to-deflect | Need to deflect | The Deflector | Gray/silver |
| need-to-narrate | Need to narrate | The Narrator | Blue/dark blue |

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

### M0: Wire Up
Connect views to real data. One path works: launch → onboard → see fix → mark it.

### M1: The Daily Loop
Onboarding, Today view (fix + inline comment), outcome marking, crash → quick fix, streak counter, daily notification, post-outcome micro-education, version display + increment.

### M2: Weekly Depth
Weekly diagnostic (Sunday prompt), weekly summary, bug library with lifecycle (Identified → Active → Stable → Resolved), version history/changelog, contribution graph, share-a-fix, multiple active bugs.

### M3: Intelligence
Pattern detection → UI, pattern surfacing with cooldowns, personal insight copy, history/stats view, regression testing on stable bugs.

### M4: Visual Polish
Full theme (grids, scanlines, glows), ASCII soul animations on bug views, boot sequence, transitions, micro-interactions.

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
| `Services/DailyFixService.swift` | Fix assignment and completion logic |
| `Resources/SeedData/fixes.json` | Seed data for fixes |

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
