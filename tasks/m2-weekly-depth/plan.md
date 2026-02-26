# Task: M2 — Weekly Depth

**Status**: Active
**Branch**: m2-weekly-depth
**Goal**: Complete all M2 milestone features so the app has weekly rhythm, bug lifecycle, contribution graph, sharing, and multi-bug support.

## Context

M0 and M1 are complete. The daily loop works end-to-end. Several M2 pieces already exist but need finishing or integration. Read CLAUDE.md for full project context including design system, tone rules, and anti-patterns.

## What Already Exists

- **Weekly diagnostic**: WeeklyDiagnosticView, WeeklyDiagnosticViewModel, WeeklyDiagnosticService — built but needs integration into the main flow (trigger on Sundays)
- **Version history/changelog**: VersionService, HistoryView changelog tab — working
- **Calendar view**: ActivityCalendarView, MonthGridView, DayDetailView — working but shows intensity-only (shades of green). Spec requires outcome-based colors.
- **Share service**: ShareService.generateShareContent() exists — no UI (no share button, no share sheet)
- **Bug model**: BugStatus enum (identified/active/stable/resolved) exists — no lifecycle management UI or service logic
- **Multiple bugs**: UserProfile.bugPriorities array supports it — need to verify full flow works and add management UI
- **Streak**: StreakService + StreakCardView — working

## Phases

### Phase 1: Contribution Graph Upgrade
The calendar currently shows only green intensity. Per CLAUDE.md spec it should encode TWO dimensions:
- **Color = outcome**: Green (applied), Yellow (skipped), Red (crash/failed), Gray outline (opened, no action), Empty (no activity)
- **Intensity = depth**: Darker = high-severity fix, reflection written, crash with note. Lighter = low-severity, quick tap-through.

Update MonthGridView to use CalendarDay.outcomeColor for the hue and CalendarDay.intensity for the brightness/opacity. Update the legend to show outcome colors, not just intensity levels. Update DayDetailView to show outcome breakdown.

Files to modify: MonthGridView.swift, ActivityCalendarView.swift (legend), DayDetailView.swift
Files to check: CalendarActivity.swift (model already has outcomeColor — good), StatsService.swift (verify calendar data includes outcome info)

### Phase 2: Bug Library & Lifecycle
Create a bug library view accessible from the app (likely a section in the Docs tab or a new view). Show all 7 bugs with their current status (Identified/Active/Stable/Resolved) and a visual indicator.

Lifecycle transitions:
- Identified → Active: When user selects bug during onboarding (already works)
- Active → Stable: When pattern detection shows sustained quiet (4+ weeks quiet on weekly diagnostics)
- Stable → Resolved: Manual user action ("I think I've got this one")
- Resolved → Active: Regression detected (crash spike on resolved bug)

Create a BugLifecycleService that checks and transitions bug statuses based on weekly diagnostic data.
Create a BugLibraryView showing all bugs, their status, lifecycle history.

New files: Services/BugLifecycleService.swift, Views/Bugs/BugLibraryView.swift, Views/Bugs/BugDetailView.swift
Modify: ContentView.swift (add navigation to bug library), Bug.swift (may need lifecycle timestamp fields)

### Phase 3: Share-a-Fix UI
Add a share button to FixCardView (or CompletionView — after marking outcome). When tapped, present a system share sheet with the content from ShareService.generateShareContent().

Per CLAUDE.md: share only the prompt + inline comment. Never: streak, version, stats, personal data. Minimal "— EgoFix" watermark.

Modify: FixCardView.swift or CompletionView.swift (add share button)
New: Views/Components/ShareFixView.swift if needed for the share sheet wrapper

### Phase 4: Weekly Diagnostic Integration
The WeeklyDiagnosticView exists but isn't triggered. Wire it up:
- Check on app launch (in ContentView or TodayViewModel): is it Sunday? Has the user already done this week's diagnostic?
- If not done, present WeeklyDiagnosticView as a sheet before showing the daily fix
- After diagnostic completion, show a brief weekly summary (applied/skipped/crashed counts for the week, any patterns detected)

Create a WeeklySummaryView that shows after the diagnostic completes.

Modify: TodayViewModel.swift (add diagnostic check), TodayView.swift (present diagnostic sheet)
New: Views/Diagnostic/WeeklySummaryView.swift

### Phase 5: Multiple Active Bugs
UserProfile.bugPriorities already supports multiple bugs. Verify and wire up:
- During onboarding, user can select 1-3 bugs (update OnboardingView if it currently limits to 1)
- DailyFixService should rotate fixes across active bugs using priority weights
- Add a "Manage Bugs" UI where user can activate/deactivate bugs and reorder priority
- Show which bug a fix belongs to on the FixCardView

Modify: OnboardingView.swift, OnboardingViewModel.swift, DailyFixService.swift, FixCardView.swift
New: Views/Bugs/ManageBugsView.swift (or integrate into BugLibraryView from Phase 2)

### Phase 6: Tests & Verification
- Write tests for BugLifecycleService
- Write tests for weekly diagnostic trigger logic
- Write tests for multi-bug fix rotation
- Run full test suite — all must pass
- Build project — 0 errors

New: EgoFixTests/ServiceTests/BugLifecycleServiceTests.swift
New: Additional test cases in existing test files

## Acceptance Criteria
- [ ] Contribution graph shows outcome colors (green/yellow/red/gray) with intensity
- [ ] Bug library view shows all 7 bugs with lifecycle status
- [ ] Bug lifecycle transitions work (Active → Stable → Resolved, regression detection)
- [ ] Share button on fix card/completion produces share sheet with prompt + comment only
- [ ] Weekly diagnostic triggers on Sundays, shows summary after
- [ ] User can have 1-3 active bugs, fixes rotate across them
- [ ] All new features use monospaced fonts, black background, brutalist aesthetic
- [ ] All existing tests still pass
- [ ] New tests cover lifecycle, diagnostic trigger, and multi-bug rotation
- [ ] Project builds with 0 errors
