---
phase: 03-setup-and-game-flow
plan: 01
subsystem: ui
tags: [godot, gdscript, setup-screen, player-selection, tween, linedit, buttongroup]

# Dependency graph
requires:
  - phase: 02-display-and-integration
    provides: dark theme, HUD sidebar, win overlay, score animation, cell button grid
provides:
  - Setup screen (player count toggles, name entry) at game launch
  - Dynamic player initialization from setup state
  - Fade transitions between setup and game states
  - Win overlay New Game routes back to setup (preserves names and count)
  - Random fun name generation for player name fields
affects: [04-distribution]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - ButtonGroup with toggle_mode for exclusive count selection
    - Tween slide animation on custom_minimum_size + modulate:a for show/hide rows
    - queue_free() on score strip children + clear arrays + _setup_score_strip() for rebuild
    - _init_setup_screen() called once at _ready() — never again (preserves state on New Game)

key-files:
  created: []
  modified:
    - scenes/main.tscn
    - scripts/main.gd

key-decisions:
  - "Setup screen initialized once at _ready() — _fade_to_setup() just shows it, preserving all LineEdit.text values and ButtonGroup state across games"
  - "Name fields pre-filled with random fun names (e.g. Brave Fox) from ADJECTIVES/NOUNS pools at startup so players get interesting defaults without typing"
  - "Empty field fallback in _on_start_game_pressed() still handles manual clears with a new random name"
  - "Score strip rebuilt via queue_free() on children + array clear + _setup_score_strip() when player count changes between games"
  - "Slide animation uses Tween on custom_minimum_size + modulate:a per Research Pattern 5 (0.15s TRANS_SINE)"

patterns-established:
  - "Setup screen: one-time init in _ready(), show/hide via visibility + fade tween, never re-init"
  - "Slide show/hide: set visible=true + tween custom_minimum_size Vector2(0,0)->Vector2(0,40) + modulate.a 0->1; reverse for hide with await tw.finished before visible=false"
  - "Dynamic score strip rebuild: for child in strip.get_children(): child.queue_free(); arrays.clear(); _setup_score_strip()"

requirements-completed: [SETUP-01, SETUP-02, WIN-03]

# Metrics
duration: 20min
completed: 2026-03-14
---

# Phase 3 Plan 01: Setup and Game Flow Summary

**Player count selection (2/3/4) and name entry setup screen with animated field visibility, random fun name defaults, and fade transitions wiring the full setup -> play -> win -> setup loop**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-03-14
- **Completed:** 2026-03-14
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments
- Setup screen appears at game launch (not the board) with player count toggles, name fields with player-colored borders, and Start Game button
- Count toggle (2/3/4) shows/hides name fields with slide animation; Enter key chains between fields
- Name fields pre-filled with random fun names (e.g. "Brave Fox", "Lucky Star") by default instead of generic "Player N"
- Start Game reads setup state, builds dynamic players array, rebuilds score strip, and fades to gameplay
- Win overlay "New Game" button fades back to setup screen with previous names and count preserved

## Task Commits

Each task was committed atomically:

1. **Task 1+2: Add SetupOverlay scene nodes and setup screen logic** - `44a0204` (feat)
2. **Task 3: Pre-fill name fields with random fun names** - `b4381d3` (feat)

## Files Created/Modified
- `scenes/main.tscn` - Added SetupOverlay node tree (Dimmer, SetupCard, CountRow, NamesContainer, PlayerRow0-3, NameInput0-3, StartButton); removed hardcoded "Player N" text from name fields
- `scripts/main.gd` - Added _init_setup_screen(), _on_count_selected(), _on_enter_from_field(), _style_button_neutral(), _update_name_field_visibility(), _show_player_row(), _hide_player_row(), _get_selected_count(), _random_fun_name(), _on_start_game_pressed(), _fade_to_game(), _fade_to_setup(); modified _ready() and _on_new_game_pressed()

## Decisions Made
- Setup screen initialized once at `_ready()` — `_fade_to_setup()` shows it without re-initializing, preserving all LineEdit text and ButtonGroup state between games
- Name fields pre-filled with random fun names at startup so players get fun defaults without any action required; empty field fallback still handles manual clears
- Score strip rebuilds between games via `queue_free()` on existing children rather than scene reload, keeping all 100 cell button signals intact

## Deviations from Plan

### User-requested changes

**1. Pre-fill name fields with random fun names (user feedback during Task 3 verification)**
- **Found during:** Task 3 (human-verify checkpoint)
- **Issue:** Name fields defaulted to "Player 1"/"Player 2" which felt generic; user wanted fun random names instead
- **Fix:** Removed hardcoded `text = "Player N"` from scene file; added `field.text = _random_fun_name()` in `_init_setup_screen()` for all 4 fields
- **Files modified:** scenes/main.tscn, scripts/main.gd
- **Committed in:** b4381d3

---

**Total deviations:** 1 user-requested enhancement
**Impact on plan:** Minor UX improvement, no scope creep. Plan truth "Name fields are pre-filled with defaults" is now satisfied with fun names instead of "Player N".

## Issues Encountered
None - implementation proceeded as planned.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Complete player-facing experience: setup -> play -> win -> setup loop works end-to-end
- Ready for Phase 4: Distribution (HTML5 export, desktop export, packaging)
- No blockers

---
*Phase: 03-setup-and-game-flow*
*Completed: 2026-03-14*
