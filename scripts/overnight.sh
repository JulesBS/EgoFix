#!/bin/bash
# Overnight runner for EgoFix
# Loops Claude with fresh context each iteration, checkpointing to disk.
#
# Usage:
#   ./scripts/overnight.sh tasks/my-task          # run with defaults
#   ./scripts/overnight.sh tasks/my-task --max 20 # limit iterations
#   ./scripts/overnight.sh tasks/my-task --dry-run # preview prompt only
#   ./scripts/overnight.sh tasks/my-task --model opus
#
# Setup:
#   mkdir -p tasks/my-task
#   # Create plan.md (what to build) and progress.md (checkpoint)
#   # See tasks/TEMPLATE/ for examples

set -euo pipefail

TASK_DIR="${1:?Usage: overnight.sh <task-dir> [--max N] [--dry-run] [--model MODEL]}"
MAX_ITERATIONS=30
DRY_RUN=false
MODEL=""

shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    --max) MAX_ITERATIONS="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --model) MODEL="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# ---------------------------------------------------------------------------
# Validate
# ---------------------------------------------------------------------------
PLAN_FILE="$TASK_DIR/plan.md"
PROGRESS_FILE="$TASK_DIR/progress.md"
LOG_DIR="$TASK_DIR/logs"

if [[ ! -f "$PLAN_FILE" ]]; then
  echo "ERROR: $PLAN_FILE not found."
  echo "Create it with the task description. See tasks/TEMPLATE/plan.md"
  exit 1
fi

if [[ ! -f "$PROGRESS_FILE" ]]; then
  echo "ERROR: $PROGRESS_FILE not found."
  echo "Create it with an initial checkpoint. See tasks/TEMPLATE/progress.md"
  exit 1
fi

mkdir -p "$LOG_DIR"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
parse_checkpoint() {
  local file="$1" field="$2"
  sed -n '/<!-- CHECKPOINT/,/-->/p' "$file" \
    | grep "^${field}:" \
    | sed "s/^${field}: *//" \
    | sed 's/^"//' | sed 's/"$//'
}

timestamp() { date "+%Y-%m-%d %H:%M:%S"; }

# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------
echo "============================================"
echo "  EgoFix Overnight Runner"
echo "  Task: $TASK_DIR"
echo "  Max iterations: $MAX_ITERATIONS"
echo "  Started: $(timestamp)"
echo "============================================"
echo ""

ITERATION=0
CONSECUTIVE_FAILURES=0

while [[ $ITERATION -lt $MAX_ITERATIONS ]]; do
  ITERATION=$((ITERATION + 1))
  ITER_LOG="$LOG_DIR/iteration-$(printf '%03d' $ITERATION).log"

  # Read checkpoint
  PHASE=$(parse_checkpoint "$PROGRESS_FILE" "phase")
  ACTIVE_TASK=$(parse_checkpoint "$PROGRESS_FILE" "active_task")
  LAST_COMPLETED=$(parse_checkpoint "$PROGRESS_FILE" "last_completed")
  NEXT_STEP=$(parse_checkpoint "$PROGRESS_FILE" "next_step")
  BLOCKERS=$(parse_checkpoint "$PROGRESS_FILE" "blockers")

  echo "--- Iteration $ITERATION / $MAX_ITERATIONS ---"
  echo "Phase: $PHASE"
  echo "Active: $ACTIVE_TASK"
  echo "Next: $NEXT_STEP"
  echo ""

  # Done?
  if [[ "$PHASE" == "done" ]]; then
    echo "============================================"
    echo "  Task complete! $(timestamp)"
    echo "  Finished in $ITERATION iterations."
    echo "============================================"
    exit 0
  fi

  # Blocked?
  if [[ "$PHASE" == "blocked" ]]; then
    echo "BLOCKED: $BLOCKERS"
    echo "Needs human input. Exiting."
    exit 2
  fi

  # Build prompt
  PROMPT="You are working on the EgoFix iOS app. Read CLAUDE.md for project context.

Read these files for your current task:
- $PLAN_FILE (what to build)
- $PROGRESS_FILE (where you left off)

CURRENT STATE:
- Phase: $PHASE
- Active task: $ACTIVE_TASK
- Last completed: $LAST_COMPLETED
- Next step: $NEXT_STEP
- Blockers: $BLOCKERS

INSTRUCTIONS:
1. Read the plan to understand full context
2. Execute the next_step described above
3. VERIFY your work:
   - Build the project: use the Xcode MCP build_project tool on EgoFix.xcodeproj
   - Run tests if relevant: use the Xcode MCP run_project_tests tool
   - Fix any errors before moving on
4. After completing AND verifying each task, update $PROGRESS_FILE:
   - Update the CHECKPOINT block (active_task, last_completed, next_step, files_modified)
   - Append a timestamped log entry to the Progress Log section
5. KEEP GOING through the plan. Don't stop after one task.
   Continue until you finish a full phase or hit a blocker.
6. If you complete everything:
   - Run the full test suite
   - Build the project
   - Set phase to 'done' only if everything passes
7. If blocked on something you can't resolve, set phase to 'blocked'

RULES:
- Never mark a task done if the build is broken
- Work on a branch (create one if not already on one)
- Commit after each completed phase
- Keep files_modified accurate in the checkpoint"

  if $DRY_RUN; then
    echo "[DRY RUN] Prompt:"
    echo "$PROMPT"
    exit 0
  fi

  # Run Claude
  echo "Running Claude... (log: $ITER_LOG)"
  MODEL_FLAG=""
  if [[ -n "$MODEL" ]]; then
    MODEL_FLAG="--model $MODEL"
  fi

  set +e
  claude --print --dangerously-skip-permissions $MODEL_FLAG "$PROMPT" 2>&1 | tee "$ITER_LOG"
  EXIT_CODE=${PIPESTATUS[0]}
  set -e

  if [[ $EXIT_CODE -ne 0 ]]; then
    CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
    echo "WARNING: Claude exited with code $EXIT_CODE (failure $CONSECUTIVE_FAILURES/3)"
    if [[ $CONSECUTIVE_FAILURES -ge 3 ]]; then
      echo "ERROR: 3 consecutive failures. Stopping."
      exit 1
    fi
    echo "Retrying in 30s..."
    sleep 30
    continue
  fi

  CONSECUTIVE_FAILURES=0
  echo "Iteration $ITERATION done. Pausing 5s..."
  echo ""
  sleep 5
done

echo "WARNING: Hit max iterations ($MAX_ITERATIONS) without completing."
echo "Check $PROGRESS_FILE for current state."
exit 1
