# Task: M3 — Intelligence

**Status**: Active
**Branch**: m3-intelligence
**Goal**: Make pattern detection visible to the user with personal insight copy, complete surfacing pipeline, cooldown enforcement, browsable history, and regression alerts.

## Context

M0–M2 complete. All 6 detectors built (Avoidance, TemporalCrash, ContextSpike, CorrelatedBugs, Plateau, Improvement). DiagnosticEngine, PatternSurfacingService, PatternsView, PatternDetailView, PatternAlertView, RecommendationEngine all exist. Read CLAUDE.md for project context.

## What Already Exists

- **6 detectors**: All implemented with thresholds per spec
- **DiagnosticEngine**: Runs all detectors, 14-day cooldown per type, priority sorting (alert > insight > observation)
- **PatternSurfacingService**: Session-level max-1 pattern, before/after fix hooks, analytics logging
- **PatternAlertView**: Shows pattern with Noted/Dismiss buttons
- **PatternsView**: Lists all detected patterns with severity badges, dates, recommendation counts
- **PatternDetailView**: Full pattern view with trend chart, data point count, recommendations
- **RecommendationEngine**: 2 recommendations per pattern type
- **TodayViewModel**: Has pattern state case, calls shouldShowPatternBeforeFix

## What Needs Work

The pipeline exists but the **copy is generic** and the **integration is incomplete**:
- Detector titles are generic ("Avoidance Pattern") instead of personal ("You've been dodging 'Need to be right' fixes")
- Detectors don't include bug names in their output (they have bugIds but not titles)
- DiagnosticEngine.runDiagnostics() exists but may not be called on a regular schedule
- The regression pattern type exists in the enum but no detector creates it — BugLifecycleService detects regressions separately
- Recommendation copy reads like a self-help book, not like EgoFix tone ("Don't Panic", "Acknowledge Your Progress")

## Phases

### Phase 1: Personal Insight Copy
Rewrite all detector output and recommendation copy to match EgoFix voice. Per CLAUDE.md: "A smart friend who sees through your shit and likes you anyway." Deadpan, dry, knowing. Never preachy.

Update each detector to produce personal, specific titles and bodies that reference the actual bug being detected. Pass bug names into detector output.

Current: "Avoidance Pattern" / "You've skipped 6 of 10 fixes for this bug."
Target: "Dodging the hard ones" / "You've skipped 6 of 10 fixes for 'Need to be right.' The ones you avoid are usually the ones that matter."

Update RecommendationEngine copy to match tone.
Current: "Acknowledge Your Progress" / "Take a moment to recognize the work you've done"
Target: "Still running" / "Whatever you're doing, it's working. Don't overthink it."

Files to modify: All 6 detector files in Detectors/, RecommendationEngine.swift
Files to check: Bug.swift (need to pass bug titles to detectors)

### Phase 2: Detection Pipeline Integration
Ensure detectors actually run on a schedule:
- Run DiagnosticEngine.runDiagnostics() after each weekly diagnostic completion
- Run it on app launch if >7 days since last run
- Wire BugLifecycleService regression detection into the pattern pipeline (when regression detected, create a DetectedPattern with type .regression)
- Add a RegressionDetector that creates patterns from BugLifecycleService data, or have BugLifecycleService create DetectedPattern directly

Track last diagnostic run timestamp in UserProfile or a separate mechanism.

Files to modify: TodayViewModel.swift (trigger diagnostics), BugLifecycleService.swift (create patterns on regression), DiagnosticEngine.swift (schedule awareness)
Potentially new: Detectors/RegressionDetector.swift

### Phase 3: Cooldown & Surfacing Polish
Verify and tighten the surfacing rules per CLAUDE.md spec:
- Max one pattern per session (exists — verify it works end-to-end)
- Same pattern type not within 14 days (exists in DiagnosticEngine — verify)
- Priority: alert before fix, insight after fix, observation in Patterns tab only
- Observations should NOT interrupt the daily flow — only show in the Patterns tab
- Add a "last pattern shown" date to prevent overwhelming users on days with lots of data

Test the full flow: detector fires → pattern saved → surfacing service picks it up → shown to user → acknowledged → cooldown starts.

Files to modify: PatternSurfacingService.swift, DiagnosticEngine.swift
Tests: Write integration tests for the full pipeline

### Phase 4: Patterns History View Enhancement
The PatternsView exists but needs more depth:
- Add filtering by bug (show patterns for a specific bug)
- Add filtering by severity (alerts / insights / observations)
- Show pattern count per bug as a summary header
- Show "acknowledged" vs "dismissed" vs "unread" status clearly
- Add a "// No patterns yet. They emerge from data." empty state (already has something — check if tone is right)
- Show the time since each pattern was detected ("3 days ago", "2 weeks ago") instead of raw dates

Files to modify: PatternsView.swift, PatternsViewModel.swift

### Phase 5: Regression Alerts
When BugLifecycleService detects a regression (stable/resolved bug crashing again):
- Create a DetectedPattern with severity .alert and type .regression
- The alert should reference the bug by name: "Need to control crashed again. 3 times in 14 days. It was stable for 6 weeks."
- Show this as a high-priority alert before the daily fix
- Add regression-specific recommendations in RecommendationEngine

Files to modify: BugLifecycleService.swift, RecommendationEngine.swift
Potentially: PatternRepository (verify regression patterns are stored and surfaced)

### Phase 6: Tests & Verification
- Write tests for personal copy generation (verify bug names appear in output)
- Write tests for diagnostic scheduling logic
- Write tests for regression → pattern pipeline
- Write tests for cooldown enforcement
- Write tests for surfacing priority rules
- Run full test suite — all must pass
- Build project — 0 errors

New test files as needed in EgoFixTests/DetectorTests/ and EgoFixTests/ServiceTests/

## Acceptance Criteria
- [ ] All detector output uses personal, specific copy with bug names (not generic "Avoidance Pattern")
- [ ] Recommendation copy matches EgoFix tone (deadpan, not self-help)
- [ ] Diagnostics run after weekly diagnostic and on app launch (with schedule check)
- [ ] Regression detection creates DetectedPattern alerts
- [ ] Cooldowns enforced: 1 per session, 14 days between same type
- [ ] Observations only in Patterns tab, never interrupting daily flow
- [ ] Patterns history has filtering by bug and severity
- [ ] Pattern timestamps show relative time ("3 days ago")
- [ ] All new code uses monospaced fonts, black background, brutalist aesthetic
- [ ] All existing tests still pass
- [ ] New tests cover copy, scheduling, regression pipeline, cooldowns
- [ ] Project builds with 0 errors
