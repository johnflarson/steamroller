---
phase: 01-foundation
plan: 02
subsystem: ui
tags: [godot4, gdscript, state-machine, highlighting, turn-loop, auto-reroll]

# Dependency graph
requires:
  - phase: 01-01
    provides: Data model (owner_grid, board_numbers, cell_buttons), state machine, _set_cell_color, _build_grid, roll handler stubs
provides:
  - Cell highlighting: unclaimed cells matching roll shown in light yellow, non-matching cells dimmed/disabled
  - Cell claiming: _claim_cell() updates owner_grid, applies player color, disables button, logs
  - Turn advance: _advance_turn() wraps player index, resets current_roll to 0, returns to WAIT_ROLL
  - Auto-reroll: _check_and_handle_no_moves() loops until valid move found, logs each reroll attempt
  - Stalemate guard: _has_unclaimed_cells() prevents infinite reroll when board is full
  - Safety cap: 100-reroll limit with GAME_OVER fallback prevents editor hang in any edge case
affects:
  - 01-03 (scoring — Plan 03: _check_score and _check_win_or_stalemate hooks are commented into _claim_cell, ready to uncomment)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Loop-based auto-reroll with stalemate guard (no recursion — iterative while loop, safe in GDScript)
    - remove_theme_stylebox_override() to reset unclaimed cells to default appearance without a style object
    - Three-guard _on_cell_pressed(): state check, ownership check, roll-value check — then claim

key-files:
  created: []
  modified:
    - scripts/main.gd

key-decisions:
  - "Auto-reroll is iterative (while loop), not recursive — avoids GDScript call stack issues on pathological boards"
  - "Unclaimed non-matching cells are disabled during WAIT_PICK — prevents misclick on wrong cell before highlights clear"
  - "_clear_highlights() re-enables all unclaimed cells so they can be highlighted on the next roll"
  - "_advance_turn() no longer calls _clear_highlights() — _claim_cell() calls it first, then advances turn"
  - "Plan 03 hooks left as comments in _claim_cell() at exact call sites, not scattered"

patterns-established:
  - "Pattern 5: Guard triple in cell handler — state, then ownership, then roll-value match"
  - "Pattern 6: Iterative auto-reroll with unclaimed-cell guard before rerolling"

requirements-completed:
  - LOOP-03
  - LOOP-04
  - LOOP-05
  - LOOP-06

# Metrics
duration: 2min
completed: 2026-03-14
---

# Phase 1 Plan 02: Cell Interaction and Turn Loop Summary

**Interactive turn loop with light-yellow cell highlighting, player-color claiming, auto-reroll on no valid moves, and board-full stalemate detection**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-14T01:56:28Z
- **Completed:** 2026-03-14T01:57:44Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Full WAIT_PICK interaction: roll reveals highlighted valid cells (light yellow), clicking one claims it with player color, turn advances immediately
- Three-guard _on_cell_pressed() prevents invalid claims (wrong state, already claimed, wrong number)
- Auto-reroll loop fires when no unclaimed cell matches roll value, logging each attempt until a valid roll lands
- _has_unclaimed_cells() stalemate guard checked before every reroll cycle — board-full state exits cleanly to _resolve_stalemate() without looping
- 100-reroll safety cap guards against any impossible edge case that could hang the Godot editor

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement highlighting, cell claiming, and turn advance** - `3f8828f` (feat)
2. **Task 2: Implement auto-reroll with stalemate guard** - `26a038d` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `scripts/main.gd` — Added HIGHLIGHT_COLOR constant, implemented _highlight_valid_cells(), _clear_highlights(), _on_cell_pressed(), _claim_cell(); added _has_unclaimed_cells(), _check_and_handle_no_moves(); updated _advance_turn() to reset current_roll = 0

## Decisions Made

- Auto-reroll implemented as an iterative while loop rather than recursively calling _highlight_valid_cells() — cleaner stack, easier to reason about, safety cap fits naturally
- Unclaimed non-matching cells are disabled during WAIT_PICK to prevent accidental clicks during the claim window; _clear_highlights() re-enables them on turn end
- Plan 03 scoring and win/stalemate hooks are left as comments at exact call sites within _claim_cell() rather than removed or scattered elsewhere

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Switched auto-reroll from recursive to iterative**
- **Found during:** Task 2 implementation
- **Issue:** Plan specified calling _highlight_valid_cells() recursively from _check_and_handle_no_moves(). GDScript handles recursion but an iterative loop is cleaner, avoids any theoretical stack depth concern, and makes the 100-reroll safety cap trivial to add
- **Fix:** Implemented _check_and_handle_no_moves() as a while loop that checks for a valid move after each reroll, then calls _highlight_valid_cells() exactly once when a match is found
- **Files modified:** scripts/main.gd
- **Verification:** All automated greps pass; logic is equivalent to the recursive approach
- **Committed in:** 26a038d (Task 2 commit)

**2. [Rule 1 - Bug] Removed redundant _clear_highlights() call from _advance_turn()**
- **Found during:** Task 1 review
- **Issue:** The existing _advance_turn() from Plan 01 called _clear_highlights(); but _claim_cell() already calls _clear_highlights() before calling _advance_turn(), making it a double-clear no-op
- **Fix:** Removed _clear_highlights() from _advance_turn() (which now only wraps player, resets roll, sets state, calls _update_ui)
- **Files modified:** scripts/main.gd
- **Verification:** _clear_highlights() is called once by _claim_cell() at the correct moment
- **Committed in:** 3f8828f (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 - Bug)
**Impact on plan:** Both fixes improve correctness and clarity. No scope creep. Behavior matches plan intent exactly.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 03 (scoring) can immediately uncomment the two hook comments in _claim_cell() and wire up _check_score() and _check_win_or_stalemate()
- _collect_line(), _check_score(), scored_grid, and _check_win_or_stalemate() are all implemented from Plan 01 and ready to activate
- The turn loop is complete: roll -> highlight -> claim -> advance -> repeat works end-to-end

## Self-Check: PASSED

Files verified: scripts/main.gd exists and contains all required functions
Commits verified: 3f8828f (Task 1), 26a038d (Task 2)

---
*Phase: 01-foundation*
*Completed: 2026-03-14*
