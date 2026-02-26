# EgoFix — Detailed Specification

> This is the detailed technical reference. CLAUDE.md is the quick-start guide.
> When they conflict, CLAUDE.md wins — it has the latest decisions.

---

## Overview

An iOS app that helps users reduce ego through daily micro-challenges. The core hook is self-knowledge: the app surfaces patterns users don't consciously notice about themselves.

**Brand voice:** "A smart friend who sees through your shit and likes you anyway."

**What it's not:** A wellness app. No soft gradients, no nature imagery, no "You're doing great!", no empty validation.

**What it is:** A tool that plays the same engagement game as every other app on your phone, but changes what's on the other side of the dopamine hit. Streaks get you to open the app. Once open, you're face-to-face with a challenge that makes you see yourself clearly. The mechanic is the delivery system. The self-awareness is the product.

---

## Design Direction

### Metaphor: Ego as Buggy Code

Your ego is legacy software — poorly documented, full of defensive functions that fire when they shouldn't. The app helps you refactor.

### Visual Language

- Monospace fonts, dark mode palette (like an IDE)
- Brutalist, utility-first — almost like a terminal or notes app
- No gradients, no soft purples, no nature imagery
- Muted syntax-highlighting colors
- Each bug has its own color from the syntax palette

### Tone

- Deadpan, dry, matter-of-fact
- Slightly antagonistic coach — doesn't coddle
- Self-aware about the irony ("Congrats on the humility challenge. No, you don't get a badge.")
- Honest about its own mechanics ("// This metric is meaningless. But you looked anyway.")

### Vocabulary

| Concept | Term |
|---------|------|
| Ego pattern | Bug |
| Mission | Fix |
| Completing a challenge | Applied |
| Progress over time | Version (e.g., v1.3) |
| Bad ego day | Crash |
| Starting fresh | Reboot |
| Stable bug returning | Regression |

---

## Technical Stack

- **Platform:** iOS 18+ (Swift 5, SwiftUI)
- **Persistence:** SwiftData (local-first)
- **Backend:** None. Design for future sync (UUIDs, timestamps, soft deletes, sync tokens)
- **Architecture:** Repository pattern for data access (swap local for remote later)
- **Testing:** TDD approach, XCTest

---

## Data Models

All models use UUIDs and include `createdAt`, `updatedAt`, and `deletedAt` (soft delete) for sync-readiness. SwiftData `@Model` classes with `@Attribute(.unique)` for IDs.

### UserProfile

```swift
struct UserProfile: Identifiable, Codable {
    let id: UUID
    var currentVersion: String          // e.g., "1.3"
    var primaryBugId: UUID?
    var currentStreak: Int              // consecutive days of engagement
    var longestStreak: Int
    var lastEngagementDate: Date?
    var streakFreezeAvailable: Bool     // one free per week, resets Sunday
    var createdAt: Date
    var updatedAt: Date
    
    // Sync-ready
    var syncToken: String?
    var lastSyncedAt: Date?
}
```

### Bug

```swift
struct Bug: Identifiable, Codable {
    let id: UUID
    let slug: String                     // "need-to-be-right"
    let title: String                    // "Need to be right"
    let description: String
    var isActive: Bool
    var status: BugStatus
    var activatedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
}

enum BugStatus: String, Codable {
    case identified
    case active
    case stable
    case resolved
}
```

### Fix

```swift
struct Fix: Identifiable, Codable {
    let id: UUID
    let bugId: UUID
    let type: FixType
    let severity: FixSeverity
    let interactionType: InteractionType
    let prompt: String                   // the challenge text
    let inlineComment: String?           // optional "// This is harder when..."
    let validation: String?              // instruction for interaction completion
    var configurationData: Data?         // JSON-encoded config for interaction type
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
}

enum FixType: String, Codable {
    case daily
    case weekly                          // "system overhaul"
    case quickFix                        // after a crash
}

enum FixSeverity: String, Codable {
    case low
    case medium
    case high
}

enum InteractionType: String, Codable {
    case standard                        // simple prompt
    case timed                           // timer must complete
    case multiStep                       // sequential steps
    case quiz                            // multiple choice
    case scenario                        // situation + response
    case counter                         // track occurrences
}
```

### Fix Configuration (JSON-encoded)

```swift
struct TimedConfig: Codable {
    let durationSeconds: Int
    let prompt: String?
}

struct MultiStepConfig: Codable {
    let steps: [Step]
    struct Step: Codable {
        let id: String
        let instruction: String
    }
}

struct QuizConfig: Codable {
    let question: String
    let options: [Option]
    struct Option: Codable {
        let id: String
        let text: String
        let weightModifier: Double
        let insight: String?
    }
}

struct ScenarioConfig: Codable {
    let situation: String
    let options: [Option]
    struct Option: Codable {
        let id: String
        let text: String
        let insight: String?
    }
}

struct CounterConfig: Codable {
    let targetDescription: String
    let unit: String?
}
```

### FixCompletion

```swift
struct FixCompletion: Identifiable, Codable {
    let id: UUID
    let fixId: UUID
    let userId: UUID
    let outcome: FixOutcome
    var reflection: String?              // optional private note
    var outcomeData: Data?              // JSON-encoded interaction outcome
    let assignedAt: Date
    var completedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
}

enum FixOutcome: String, Codable {
    case pending
    case applied
    case skipped
    case failed
}
```

### Crash

```swift
struct Crash: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let bugId: UUID?
    var note: String?
    let crashedAt: Date
    var rebootedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
}
```

### VersionEntry

```swift
struct VersionEntry: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let version: String
    let changeType: VersionChangeType
    let description: String
    let createdAt: Date
    var deletedAt: Date?
}

enum VersionChangeType: String, Codable {
    case majorUpdate                     // 1.x -> 2.0
    case minorUpdate                     // 1.0 -> 1.1
    case crash
    case reboot
}
```

### AnalyticsEvent

```swift
struct AnalyticsEvent: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let eventType: EventType
    let bugId: UUID?
    let fixId: UUID?
    let context: EventContext?
    let dayOfWeek: Int                   // 1-7
    let hourOfDay: Int                   // 0-23
    let timestamp: Date
    var deletedAt: Date?
}

enum EventType: String, Codable {
    case fixAssigned
    case fixApplied
    case fixSkipped
    case fixFailed
    case crashLogged
    case crashRebooted
    case appOpened
    case weeklyCompleted
    case patternViewed
    case patternDismissed
    case fixShared                       // forwarded a fix to someone
}

enum EventContext: String, Codable {
    case work
    case home
    case social
    case family
    case online
    case unknown
}
```

### DetectedPattern

```swift
struct DetectedPattern: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let patternType: PatternType
    let severity: PatternSeverity
    let title: String
    let body: String
    let relatedBugIds: [UUID]
    let dataPoints: Int
    let detectedAt: Date
    var viewedAt: Date?
    var dismissedAt: Date?
    var deletedAt: Date?
}

enum PatternType: String, Codable {
    case avoidance
    case temporalCrash
    case contextualSpike
    case correlatedBugs
    case plateau
    case regression
    case improvement
}

enum PatternSeverity: String, Codable {
    case observation
    case insight
    case alert
}
```

### WeeklyDiagnostic

```swift
struct WeeklyDiagnostic: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let weekStarting: Date
    let responses: [BugDiagnosticResponse]
    let completedAt: Date
    var deletedAt: Date?
}

struct BugDiagnosticResponse: Codable {
    let bugId: UUID
    let intensity: BugIntensity
    let primaryContext: EventContext?
}

enum BugIntensity: String, Codable {
    case quiet
    case present
    case loud
}
```

### MicroEducation

```swift
struct MicroEducation: Identifiable, Codable {
    let id: UUID
    let bugSlug: String
    let trigger: EducationTrigger       // when to show
    let body: String                     // the insight text
    var createdAt: Date
    var deletedAt: Date?
}

enum EducationTrigger: String, Codable {
    case afterApplied                    // shown after marking fix as applied
    case afterSkipped
    case afterFailed
    case afterCrash
    case duringDiagnostic
    case restDay                         // no fix assigned
}
```

---

## Repository Pattern

Abstract data access for sync-readiness:

```swift
protocol FixRepository {
    func getAll() async throws -> [Fix]
    func getById(_ id: UUID) async throws -> Fix?
    func getForBug(_ bugId: UUID) async throws -> [Fix]
    func getDailyFix(for bugId: UUID, excluding: [UUID]) async throws -> Fix?
    func save(_ fix: Fix) async throws
    func delete(_ id: UUID) async throws
}
```

Matching protocols for: `BugRepository`, `FixCompletionRepository`, `CrashRepository`, `UserRepository`, `VersionEntryRepository`, `AnalyticsEventRepository`, `PatternRepository`, `WeeklyDiagnosticRepository`, `MicroEducationRepository`.

Each protocol gets a `Local` implementation using SwiftData.

---

## Pattern Detection Logic

### Detector Protocol

```swift
protocol PatternDetector {
    var patternType: PatternType { get }
    var minimumDataPoints: Int { get }
    func analyze(events: [AnalyticsEvent], diagnostics: [WeeklyDiagnostic]) -> DetectedPattern?
}
```

### Detector Thresholds

| Detector | Trigger Condition |
|----------|-------------------|
| Avoidance | >50% skip rate on a bug, minimum 4 skips |
| Temporal (day) | >40% crashes on same weekday, minimum 3 |
| Temporal (time) | >50% crashes in same time bucket, minimum 3 |
| Context Spike | >60% loud responses in one context, minimum 3 |
| Correlated Bugs | Pearson r > 0.7 over 6+ weeks |
| Plateau | 4+ weeks present/loud despite 6+ fixes applied |
| Improvement | Downward trend ending in quiet over 4+ weeks |

### Surfacing Rules

- Max one pattern per session
- Same pattern type not shown within 14 days
- Priority: alert > insight > observation
- Alerts: shown before daily fix
- Insights: shown after fix outcome
- Observations: patterns tab only

---

## Weekly Diagnostic Flow

1. Prompt on Sunday evening or Monday morning
2. For each active bug (max 3, rotate if more):
   - "This week, [bug] felt..." → Quiet / Present / Loud
   - If not Quiet: "Where was it loudest?" → Work / Home / Social / Family / Online / Unsure
3. Completion screen with weekly summary
4. Skip always available, no guilt

---

## Engagement Features

### Streak System

- Track consecutive days where user engaged (opened fix, logged crash, or completed diagnostic)
- Display with self-aware inline comment: `// This metric is meaningless. But you looked anyway.`
- One free streak freeze per week (resets Sunday). Not monetized.
- Breaking a streak = silent reset. No "you lost your streak!" notification. Counter just goes back to 0.
- The streak serves the app (gets users to open it). The app doesn't serve the streak.

### Contribution Graph

GitHub-style grid displayed in History/Stats view. Each square encodes two dimensions:

**Color = outcome type:**
- Green: fix applied
- Yellow: fix skipped
- Red: crash logged
- Gray outline: app opened but no action taken
- Empty: no activity

**Intensity = depth of engagement:**
- Dark shade: high-severity fix applied, reflection written, crash logged with note
- Light shade: low-severity fix, quick tap-through, minimal engagement

The graph is a mirror, not a scoreboard. Users see their own temporal patterns (Monday crash clusters, avoidance streaks, deep engagement weeks) before the detection engine even tells them.

### Social Sharing

Users can forward a fix (prompt text + inline comment) to a friend via share sheet. The shared content includes:
- Fix prompt and inline comment
- Minimal EgoFix watermark/attribution

**Never shared:** Streak count, version number, completion status, contribution graph, reflection text, or any personal data. The share is about the content, not the sender.

### Post-Outcome Micro-Education

After marking a fix outcome, display a brief educational tidbit explaining WHY the underlying pattern exists. Pulled from `MicroEducation` pool, filtered by bug and trigger type, randomized.

Examples:
- After applying a "need to be right" fix: "The need to be right is rarely about the facts. It's usually about the feeling of being seen as competent."
- After logging a crash: "Ego flares aren't failures. They're your nervous system doing what it learned to do. The fact that you noticed is the whole point."
- During weekly diagnostic: "Most people think they're self-aware. Studies show we're accurate about our own behavior roughly 15% of the time."

### Notifications

- **Daily fix reminder:** Once per day, configurable time. "Fix #042 is ready."
- **Timer completion:** "Timer complete. How did it go?"
- **Anti-notification:** After stable period: "Still running smoothly?" More stability = less contact.
- **No guilt notifications.** No "you lost your streak!" or "you haven't opened the app in 3 days!"

---

## Development Milestones

### M0: Wire Up
Connect existing views to real data layer. One working path: launch → onboard → see fix → mark outcome.

### M1: The Daily Loop
- Onboarding: pick your primary bug, see first fix immediately
- Today view: display fix with inline comment
- Outcome marking: applied / skipped / failed (one tap)
- Optional reflection (private note)
- Post-outcome micro-education tidbit
- Crash button (always accessible, 2 taps to log)
- Quick fix assigned after crash
- Streak counter (self-aware version)
- Version display + increment (7 fixes applied → minor bump)
- Daily push notification
- Local persistence

### M2: Weekly Depth
- Bug library (multiple active bugs)
- Bug lifecycle: Identified → Active → Stable → Resolved
- Weekly diagnostic (30-second Sunday check-in)
- Weekly summary view
- Version history / changelog view
- Contribution graph (outcome color + engagement intensity)
- Share-a-fix (forward fix content to a friend)
- Reboot mechanic

### M3: Intelligence
- Pattern detection engine connected to UI
- Pattern surfacing (one per session max, cooldown rules)
- All six detectors: Avoidance, Temporal, Context, Correlated, Plateau, Improvement
- Regression testing (stable bugs retested every 30 days)
- History/stats view with completion rates by bug

### M4: Visual Polish
- Full EgoTheme: grid patterns, scanline overlay, green glows
- ASCII soul animations for each bug on detail views
- Boot sequence on first launch
- Transitions and micro-interactions
- The app should feel unmistakable — like a developer tool, not a default SwiftUI app

### M5: Ship
- App icon
- First-run experience polish
- Edge case handling (empty states, error states)
- App Store metadata and screenshots
- TestFlight build

---

## TDD Test Plan

### Models

- `test_UserProfile_defaultVersion` — New user starts at v1.0
- `test_UserProfile_defaultStreak` — New user starts at streak 0
- `test_Bug_softDelete_setsTimestamp` — Deleting sets deletedAt
- `test_Fix_belongsToBug` — Fix always has valid bugId
- `test_Fix_interactionTypeConfig` — Each interaction type decodes its config correctly
- `test_FixCompletion_outcomeTransitions` — pending → applied/skipped/failed only
- `test_Crash_rebootClearsState` — Rebooting sets rebootedAt
- `test_VersionEntry_incrementsCorrectly` — 1.0 → 1.1, 1.9 → 2.0

### Repositories

- `test_FixRepo_getDailyFix_excludesCompleted` — No already-applied fixes
- `test_FixRepo_getDailyFix_matchesBug` — Returns fix for active bug only
- `test_CompletionRepo_save_updatesTimestamp` — updatedAt changes
- `test_BugRepo_getActive_filtersDeleted` — Soft-deleted bugs hidden
- `test_CrashRepo_getUnrebooted` — Returns crashes without rebootedAt

### Services

- `test_DailyFixService_assignsOnePerDay` — No double-assignment
- `test_DailyFixService_respectsCooldown` — Skipped fix not immediately reassigned
- `test_VersionService_incrementsOnMilestone` — 7 fixes → version bump
- `test_CrashService_triggersQuickFix` — Crash queues quick fix
- `test_StreakService_incrementsOnEngagement` — Any engagement bumps streak
- `test_StreakService_resetsOnMissedDay` — Gap in engagement resets to 0
- `test_StreakService_freezePreservesStreak` — Freeze available prevents reset
- `test_StreakService_freezeResetsWeekly` — Freeze availability resets Sunday
- `test_StreakService_noGuildNotificationOnBreak` — Breaking streak is silent

### Detectors

- `test_AvoidanceDetector_triggersAt50Percent`
- `test_AvoidanceDetector_ignoresBelowThreshold`
- `test_TemporalDetector_findsDayClusters`
- `test_TemporalDetector_findsTimeClusters`
- `test_CorrelatedBugs_detectsHighCorrelation`
- `test_PlateauDetector_requiresFixesApplied`
- `test_ImprovementDetector_requiresDownwardTrend`
- `test_PatternSurfacing_maxOnePerSession`
- `test_PatternSurfacing_respectsCooldown`

### Weekly Diagnostic

- `test_WeeklyDiagnostic_promptsOnSunday`
- `test_WeeklyDiagnostic_skipsIfCompleted`
- `test_WeeklyDiagnostic_capsAtThreeBugs`
- `test_WeeklyDiagnostic_rotatesBugs`

### Engagement

- `test_ContributionGraph_colorMatchesOutcome` — Applied=green, skipped=yellow, crash=red
- `test_ContributionGraph_intensityMatchesDepth` — High severity + reflection = dark
- `test_ShareFix_excludesPersonalData` — Shared content has no streak/version/stats
- `test_MicroEducation_matchesBugAndTrigger` — Correct tidbit for bug + outcome combo
- `test_MicroEducation_randomizes` — Doesn't repeat same tidbit consecutively

### ViewModels

- `test_TodayViewModel_stateTransitions` — loading → loaded → applied
- `test_TodayViewModel_showsQuickFix_afterCrash`
- `test_TodayViewModel_showsMicroEducation_afterOutcome`
- `test_HistoryViewModel_groupsByVersion`
- `test_OnboardingViewModel_setsPrimaryBug`

### Integration

- `test_fullFlow_onboardToFirstFix`
- `test_fullFlow_applyFixUpdatesVersion`
- `test_fullFlow_crashAndReboot`
- `test_fullFlow_streakAcrossMultipleDays`
- `test_fullFlow_weeklyDiagnosticFeedsPatternDetection`

---

## Seed Data

Bugs and fixes ship as bundled JSON.

### bugs.json

```json
[
  {
    "id": "uuid-here",
    "slug": "need-to-be-right",
    "title": "Need to be right",
    "description": "The compulsion to correct others, win arguments, or have the last word."
  },
  {
    "id": "uuid-here",
    "slug": "need-to-be-liked",
    "title": "Need to be liked",
    "description": "Adjusting your opinions or behavior to gain approval."
  },
  {
    "id": "uuid-here",
    "slug": "need-to-impress",
    "title": "Need to impress",
    "description": "Steering conversations toward your achievements or expertise."
  },
  {
    "id": "uuid-here",
    "slug": "need-to-be-busy",
    "title": "Need to be busy",
    "description": "Using busyness as status or identity."
  },
  {
    "id": "uuid-here",
    "slug": "fear-of-ordinary",
    "title": "Fear of being ordinary",
    "description": "Discomfort with being average or unremarkable."
  }
]
```

### fixes.json

Includes `interactionType` and optional `configuration` block per the existing seed data format documented in CLAUDE.md.

**Content requirements:**
- 50+ fixes per bug (5 bugs = 250+ minimum). Users shouldn't see repeats for months.
- 3 severity levels per fix. Early days get low-severity. As bugs activate, severity scales up.
- Inline comments for ~60% of fixes. The best fixes have them.
- Mix of interaction types. Not all fixes are `standard` — use timed, counter, quiz, scenario, multiStep where they genuinely add value.

### micro_education.json

```json
[
  {
    "id": "uuid-here",
    "bugSlug": "need-to-be-right",
    "trigger": "afterApplied",
    "body": "The need to be right is rarely about the facts. It's usually about the feeling of being seen as competent. The correction isn't for them — it's for your self-image."
  },
  {
    "id": "uuid-here",
    "bugSlug": "need-to-be-right",
    "trigger": "afterCrash",
    "body": "Ego flares aren't failures. They're your nervous system doing what it learned to do. The fact that you noticed is the whole point."
  }
]
```

**Content requirements:**
- 30+ tidbits per bug, spread across trigger types
- Explains WHY the pattern exists, not just what to do about it
- Draws from psychology, philosophy, behavioral science — but in plain language
- Tone: knowing, not lecturing

---

## UI Copy Examples

### Fix Card

```
FIX #037
Severity: Medium

Let someone else have the last word.

// This is harder when you're sure you're right.
// That's the point.

[ Applied ]   [ Skipped ]   [ Failed ]
```

### Crash Log

```
CRASH LOGGED

What resurfaced?

[ Need to be right ]
[ Need to be liked ]
[ Need to impress  ]
[ Need to be busy  ]
[ Fear of ordinary ]
```

### Pattern Surface

```
PATTERN DETECTED

You skip fixes about listening on days you
crash about being right. When you're in
correction mode, you stop being able to hear.

[ Noted ]
```

### Completion Feedback (with micro-education)

```
FIX APPLIED

No fanfare. You did the thing.

The need to be right is rarely about the facts.
It's usually about being seen as competent.

[ Continue ]
```

### Streak Display

```
day 14 // this number means nothing about your growth. but you looked.
```

### Share Preview (what recipient sees)

```
EgoFix

Let someone be wrong about something
that doesn't matter.

// The urge to correct isn't about accuracy.
// It's about status.
```

---

## Content Principles

1. **Specific over general.** "Notice when you name-drop" beats "be humble."
2. **Observational over prescriptive.** "Count how many times you..." beats "don't do X."
3. **Inline comments reframe, don't repeat.** They add a layer the fix alone doesn't have.
4. **Micro-education explains the WHY.** Not what to do — why the pattern exists.
5. **Pattern insights feel personal.** Use the user's actual data, not generic stats.
6. **Tone is deadpan, dry, knowing.** The brand voice, always.

---

## Anti-Patterns (Never Build)

- No badges or achievements
- No XP or rank systems
- No social leaderboards
- No friend activity feeds ("3 friends applied fixes today")
- No loot drops, daily spins, or random rewards
- No seasonal FOMO events
- No mechanic that rewards volume of taps over depth of engagement
- No "You're doing great!" or any variation
- No guilt notifications ("You lost your streak!" / "You haven't opened the app in 3 days!")
- No gradients, soft colors, nature imagery, or wellness aesthetic
- No emojis in app copy

---

## Notes

- Progress is private (except voluntarily forwarded fixes)
- Failure is expected and handled without judgment
- The app earns the right to be quiet — more stability means less contact
- The app starts loud (daily notifications, visible streak, frequent fixes) and gets quieter as bugs stabilize
- Engagement mechanics exist to deliver users to moments of self-awareness — if a mechanic doesn't pass that test, cut it
