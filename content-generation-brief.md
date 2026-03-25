# EgoFix Content Generation Brief

> Give this document to an AI instance to batch-produce fixes and micro-education. It contains everything needed: the app's philosophy, the 7 bugs, the 14 interaction types, quality standards, format specs, and examples of great vs weak content.

---

## What Is EgoFix?

An iOS app that treats ego defense mechanisms as bugs in the user's operating system. Users get one daily "fix" (mission) targeting a specific ego pattern. The app surfaces behavioral blind spots through daily challenges, tracks patterns over time, and shows users things about themselves they didn't know.

**Brand voice:** "A smart friend who sees through your shit and likes you anyway." Deadpan, dry, knowing. Never preachy, never gentle, never condescending. Not a wellness app.

**Design metaphor (UI only):** The app's interface uses code language — bugs, fixes, versions, debug log, crashes. But the actual content (fix prompts, education) speaks in plain language that EVERYONE understands. Code metaphors are fine as light seasoning in education ("It's like a background process you never installed") but never the primary language.

---

## The Seven Ego Bugs

Each bug is a distinct ego strategy — a different way the mind protects its sense of self.

### 1. need-to-be-right
**Root mechanism:** Equating being right with being worthy. If I'm wrong, I'm diminished.
**What it looks like:** Correcting others, winning arguments, having the last word, replaying arguments, physical discomfort when someone says something incorrect.

### 2. need-to-impress
**Root mechanism:** Equating achievement with identity. If they don't know what I've done, I don't exist.
**What it looks like:** Name-dropping, steering conversations to expertise, humble-bragging, checking likes/reactions, mentioning credentials unprompted.

### 3. need-to-be-liked
**Root mechanism:** Equating approval with safety. If they don't like me, I'm in danger.
**What it looks like:** Saying yes when meaning no, laughing at unfunny jokes, changing opinions to match the room, over-apologizing, "I'm easy, you choose."

### 4. need-to-control
**Root mechanism:** Equating control with security. If I'm not directing it, it will go wrong.
**What it looks like:** Micromanaging, redoing others' work, giving unsolicited instructions, anxiety when plans change, difficulty delegating.

### 5. need-to-compare
**Root mechanism:** Equating rank with value. I'm only okay if I'm ahead.
**What it looks like:** Checking what peers earn/own/achieved, one-upping stories, feeling stung by friends' success, mentally ranking yourself in every room.

### 6. need-to-deflect
**Root mechanism:** Equating vulnerability with weakness. If they see the real me, they'll have power over me.
**What it looks like:** Making jokes when it gets serious, intellectualizing emotions, changing subjects when personal, never asking for help.

### 7. need-to-narrate
**Root mechanism:** Equating suffering with significance. My story IS me.
**What it looks like:** Rehearsing arguments in your head, telling the same complaint to multiple people, finding fault before finding good, narrating your day as if documenting injustices.

---

## The 14 Interaction Types

| Type | Description | What user does | Config needed |
|------|-------------|---------------|---------------|
| `standard` | Simple behavioral prompt | Go do it, mark applied | None |
| `timed` | Timer must complete | Start timer, sit with it | `{ "timed": { "durationSeconds": N } }` |
| `multiStep` | Sequential steps | Complete 3 steps in order | `{ "multiStep": { "steps": [...] } }` |
| `quiz` | Multiple choice self-assessment | Pick an answer, see insight | `{ "quiz": { "question": "...", "options": [...] } }` |
| `scenario` | Situation + response choices | Read situation, pick response | `{ "scenario": { "situation": "...", "options": [...] } }` |
| `counter` | Track occurrences | Tap +1 each time it happens | `{ "counter": { "counterPrompt": "...", "minTarget": null, "maxTarget": null } }` |
| `observation` | Notice something, report back | Observe, write report | `{ "observation": { "reportPrompt": "..." } }` |
| `abstain` | Don't do X for a period | Resist, mark slips | `{ "abstain": { "durationDescription": "...", "durationSeconds": N or null } }` |
| `substitute` | When urge X, do Y instead | Track urges + swaps | `{ "substitute": { "triggerBehavior": "...", "replacementBehavior": "..." } }` |
| `journal` | Short written reflection | Write 2-3 sentences | None |
| `reversal` | Do the opposite of default | Do it, mark applied | None |
| `predict` | Predict then observe | Write prediction, lock, then observe | `{ "predict": { "predictionPrompt": "...", "observationPrompt": "..." } }` |
| `body` | Notice physical sensation | Select body regions + sensations | `{ "body": { "scanRegions": [...], "sensationDescriptors": [...] } }` |
| `audit` | End-of-day behavior review | Fill in categories | `{ "audit": { "auditPrompt": "...", "categories": [...] } }` |

---

## Fix JSON Format

```json
{
  "id": "UUID-string",
  "bugSlug": "need-to-be-right",
  "type": "daily",
  "severity": "medium",
  "interactionType": "standard",
  "prompt": "The actual fix text the user sees",
  "validation": "How they know they did it — criteria for marking Applied",
  "inlineComment": "One-sentence reframe that names the mechanism",
  "configuration": null
}
```

**Types for `type` field:** `daily` (standard mission), `quickFix` (after a crash), `weekly` (weekly challenge)

**Severity:** `low` (awareness-building, easy wins), `medium` (behavioral challenge, social risk), `high` (deeply uncomfortable, identity-level)

---

## Micro-Education JSON Format

```json
{
  "id": "me-right-31",
  "bugSlug": "need-to-be-right",
  "trigger": "postApply",
  "body": "Full paragraph — the original education text.",
  "teaser": "1-2 punchy sentences. The hook. Always visible on mission screen.",
  "deepDive": "2-3 paragraphs. The psychology explained simply. What's happening and why. Ends with something to notice going forward."
}
```

**Triggers:** `postApply`, `postSkip`, `postCrash`, `postFailed`, `general`, `duringDiagnostic`, `restDay`

---

## The Five Ingredients (Every Fix Needs All Five)

### 1. SPECIFIC TRIGGER
Name a moment the user can identify in real time.
- Good: "Next time someone asks 'what do you do?' and you feel the urge to elaborate..."
- Bad: "When you feel the need to impress..."

### 2. CONCRETE ACTION
Observable, completable, unambiguous.
- Good: "Give the shortest possible answer. One sentence. Don't elaborate."
- Bad: "Try to be less impressive."

### 3. OBSERVATION HOOK (type-appropriate)
What to notice. This is where self-awareness lives.
- `standard/reversal`: "Notice what the silence feels like after you don't correct them."
- `counter`: "Track how many start with 'Actually...' or 'Well, technically...'"
- `journal`: "Write about the last argument you 'won.' What did winning actually give you?"
- `observation`: "Notice: does your sense of humor change depending on who you're with?"
- `body`: "Scan your jaw, chest, hands. Where does the tension live?" (ONLY for body type)
- `predict`: "Predict what will happen. Then try it. Compare."
- `audit`: "Tonight, list 3 moments where you performed instead of being genuine."

### 4. CONSTRAINT THAT REVEALS
A limitation that makes the pattern visible.
- Good: "Zero corrections until 6pm — in person, in chat, in email."
- Bad: "Try not to correct people."

### 5. INLINE COMMENT THAT REFRAMES
Names the mechanism. Not motivation.
- Good: "The urge to correct isn't about accuracy. It's about status."
- Bad: "You're doing great!" / "Awareness precedes change."

---

## Education Content Rules

### Teasers (1-2 sentences, always visible)
- Must make you want to tap "read more"
- It's a hook, not a summary
- Surprising or reframing: "The urge to correct is a status signal, not an accuracy signal."

### Deep Dives (2-3 paragraphs, expandable)
- **PLAIN LANGUAGE.** Must be understood by everyone — not just developers or psychology students.
- Reference real psychology/neuroscience but explain simply:
  - Good: "Your brain treats being wrong the same way it treats physical threats. The part that fires when you stub your toe also fires when someone challenges your opinion. That's why being corrected feels personal — your nervous system literally can't tell the difference."
  - Bad: "The ACC (anterior cingulate cortex) is your error-monitoring daemon with sensitivity cranked to max."
- Code metaphors as light seasoning only: "It's like a background process you never installed" — fine. "This subroutine fires at 200ms latency in the basal ganglia pipeline" — too much.
- End every deep dive with something the user can actually notice or do going forward.
- Never exceed 3 paragraphs. Trim ruthlessly.

### Trigger-specific tone
- `postApply`: Reinforce without praise. "You didn't correct them. The world continued. That gap between urge and action — that's the rewiring."
- `postSkip`: Treat skip as data, not failure. "Skipping this one often means the pattern is loud right now. The pattern protects itself by avoiding the mirror."
- `postCrash`: Compassionate but clear. "The correction came out before you could catch it. That speed is the pattern's signature — it fires faster than you can think."
- `general`: Timeless insight. Works anytime.
- `restDay`: "No fix today. Rest is part of the process. Notice if the pattern feels relieved."

---

## Examples: GREAT Fixes (Score 5/5)

### need-to-be-right / standard / medium
```json
{
  "prompt": "Someone shares an opinion. Respond with exactly one curious question. No counter-argument.",
  "validation": "Your question must start with 'What', 'How', 'When', or 'Why'. If your response included 'but' or 'actually', mark Failed.",
  "inlineComment": "Curiosity dissolves the need to win."
}
```
Why it works: Specific trigger (someone shares opinion), concrete action (one question), constraint (no counter-argument), observation (notice if 'but' slips out), reframe (curiosity vs winning).

### need-to-be-liked / timed / high
```json
{
  "prompt": "Sit for 3 minutes with this question: 'What would I do differently today if I wasn't worried about what people think?'",
  "validation": "Did you sit the full 3 minutes without switching to a different thought?",
  "inlineComment": "The distance between who you are and who you perform is where the pattern lives.",
  "configuration": { "timed": { "durationSeconds": 180 } }
}
```
Why it works: Specific constraint (3 min), existential question (forces honesty), inline names the mechanism (performance gap).

### need-to-control / predict / medium
```json
{
  "prompt": "Predict: if you don't follow up on that delegated task for 24 hours, what will happen? Try it. Then compare.",
  "validation": "Write your prediction first. Then wait 24 hours. Then compare.",
  "inlineComment": "The predicted catastrophe almost never arrives.",
  "configuration": { "predict": { "predictionPrompt": "If I don't check on the delegated task for 24 hours, I predict...", "observationPrompt": "24 hours later. What actually happened?" } }
}
```
Why it works: Tests the assumption directly. Most control patterns are maintained by untested beliefs about consequences.

### need-to-deflect / body / medium
```json
{
  "prompt": "When you deflect with humor or a subject change, freeze for a moment. What sensation were you running from?",
  "validation": "Did you catch a deflection and pause? What did you feel physically?",
  "inlineComment": "The joke is the escape hatch. What's in the room you're leaving?",
  "configuration": { "body": { "scanRegions": ["Chest", "Throat", "Stomach", "Face", "Hands", "Shoulders"], "sensationDescriptors": ["Tightness", "Flutter", "Heat", "Constriction", "Restlessness", "Numbness"] } }
}
```
Why it works: Specific trigger (deflection moment), concrete action (freeze + scan), body-type observation, inline reframes the humor as escape.

---

## Examples: WEAK Fixes (Score 1-2/5) — DO NOT WRITE LIKE THESE

### need-to-control / multiStep / medium
```json
{
  "prompt": "Delegate without micromanaging.",
  "validation": "Complete all steps to mark as applied."
}
```
Why it fails: That's the goal, not a fix. No specificity, no observation, no constraint. Could be in any productivity app.

### need-to-be-liked / quiz / low
```json
{
  "prompt": "Self-assessment: Approval Seeking",
  "validation": "Answer honestly."
}
```
Why it fails: A label, not a fix. No question, no options, no insight. This is a placeholder.

### need-to-compare / counter / low
```json
{
  "prompt": "Count: Comparison Thoughts",
  "validation": "Tap the counter."
}
```
Why it fails: What's a "comparison thought"? Too vague. Should be: "Count how many times you check what someone else earned, owns, or achieved today."

---

## Content Targets

### Fix Distribution Per Bug (target: ~45-50 each)
- 8-10 standard
- 4-5 counter
- 3-4 timed, observation, scenario
- 2-3 journal, abstain, quiz, substitute
- 2 reversal, multiStep
- 1-2 predict, body, audit

### Severity Distribution
- ~35% low (awareness-building)
- ~40% medium (behavioral challenge)
- ~25% high (deeply uncomfortable, identity-level)

### Education Per Bug (target: 30 each)
- 5-6 postApply, 5-6 postSkip, 4-5 postCrash, 3-4 postFailed
- 4-5 general, 2 duringDiagnostic, 1 restDay

---

## Output Format

When producing content, output as valid JSON arrays ready to merge into the seed data files.

**Fixes:**
```json
[
  {
    "id": "UUID-format-string",
    "bugSlug": "need-to-be-right",
    "type": "daily",
    "severity": "medium",
    "interactionType": "standard",
    "prompt": "...",
    "validation": "...",
    "inlineComment": "..."
  }
]
```

**Education:**
```json
[
  {
    "id": "me-right-31",
    "bugSlug": "need-to-be-right",
    "trigger": "postApply",
    "body": "Full paragraph text.",
    "teaser": "1-2 sentence hook.",
    "deepDive": "2-3 paragraphs. Plain language. Ends with observation."
  }
]
```

Generate UUIDs for fix IDs. Use `me-{bugShortName}-{number}` for education IDs (continuing from existing numbering — current goes up to 30 per bug).

---

## Self-Check Before Submitting

For each fix, verify:
- [ ] All five ingredients present (trigger, action, observation, constraint, reframe)
- [ ] Inline comment names the mechanism, doesn't motivate
- [ ] Prompt is specific enough that two people would do the same thing
- [ ] Not a goal statement disguised as a fix
- [ ] Configuration included for types that need it (quiz, scenario, counter, etc.)
- [ ] Severity matches the actual discomfort level

For each education entry:
- [ ] Teaser hooks — makes you want to tap "read more"
- [ ] Deep dive is plain language, not jargon
- [ ] Psychology referenced but explained simply
- [ ] Max 3 paragraphs
- [ ] Ends with something to notice going forward
- [ ] Trigger matches the context (postApply reinforces, postSkip treats as data, etc.)
