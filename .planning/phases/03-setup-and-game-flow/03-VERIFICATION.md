---
phase: 03-setup-and-game-flow
verified: 2026-03-14T00:00:00Z
status: human_needed
score: 7/7 must-haves verified
human_verification:
  - test: "Launch game (F5 in Godot), verify setup screen appears centered on dark background with no board visible, 2 selected (gold), two name fields with colored borders pre-filled with random fun names, and Start Game button in gold"
    expected: "Setup card centered on dark dimmer; board/sidebar not visible; CountBtn2 gold, CountBtn3/4 neutral; NameInput0 coral border, NameInput1 slate-blue border; fun names pre-filled"
    why_human: "Visual layout, color rendering, and Godot scene composition cannot be verified by static grep — requires the Godot renderer"
  - test: "Click 3 on count row — third name field slides in (sage border). Click 2 — it slides out. Click 4 — fields 3 and 4 slide in (sage, amber). Click 2 — both slide out"
    expected: "Slide animation (~0.15s TRANS_SINE) shows/hides rows smoothly; correct player-color borders visible on each field"
    why_human: "Tween animation and field visibility are runtime behaviors; border colors require visual confirmation"
  - test: "Type more than 15 characters in any name field — verify truncation at 15"
    expected: "Input capped at 15 characters; no overflow"
    why_human: "max_length is set in scene and is 15 (verified statically), but interactive input capping needs human confirmation"
  - test: "Press Enter in field 1 — focus moves to field 2. With 3 players selected, press Enter in field 2 — focus moves to field 3. Press Enter in last visible field — game starts"
    expected: "Enter chains focus correctly based on selected count; last visible Enter triggers Start Game"
    why_human: "Focus chaining and interactive keyboard flow require runtime verification"
  - test: "Enter names Alice, Bob, Charlie with 3 players selected, press Start Game. Verify: board appears with fade, score strip shows 3 players with correct names and player colors, game plays normally"
    expected: "setup_overlay fades out (0.2s), hbox_container appears, score strip has 3 colored panels with correct names"
    why_human: "Fade transition visual quality and score strip rebuild require runtime confirmation"
  - test: "Play a full game to a win condition. On win overlay, click New Game — verify fade returns to setup screen with Alice, Bob, Charlie still in fields and 3 selected"
    expected: "Win overlay hides, setup fades in (0.2s), previous names and count preserved in LineEdit.text and ButtonGroup state"
    why_human: "State preservation across game sessions is a runtime behavioral property"
  - test: "On setup screen, clear a name field and press Start Game. Verify a random fun-name (adjective + noun) appears in the score strip instead of blank"
    expected: "Empty field gets a random fun name from ADJECTIVES + NOUNS pools at game start"
    why_human: "Random name generation on empty field requires interactive triggering"
---

# Phase 3: Setup and Game Flow Verification Report

**Phase Goal:** Player count selection, name entry, and complete restart flow
**Verified:** 2026-03-14
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

The phase goal requires: a setup screen at launch, player count/name selection, and a complete setup -> play -> win -> setup loop working without page reload.

### Observable Truths

| #   | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1   | At game launch, a setup screen appears with player count toggles and name fields — not the board | VERIFIED | `hbox_container.visible = false` (line 143 main.gd); `SetupOverlay visible=true` (scene line 109); `_init_setup_screen()` called in `_ready()` |
| 2   | Selecting 2/3/4 players shows/hides the correct name fields with slide animation | VERIFIED | `_update_name_field_visibility(count)` called from `_on_count_selected`; `_show_player_row`/`_hide_player_row` use Tween on `custom_minimum_size` + `modulate:a` (0.15s TRANS_SINE); PlayerRow2/3 start `visible=false` in scene |
| 3   | Name fields are pre-filled with defaults, max 15 chars, Enter chains to next field | VERIFIED | `field.text = _random_fun_name()` for all 4 fields (line 192); `max_length = 15` set in scene for all 4 LineEdits; `text_submitted` signals chain fields 0→1→2→3→game via `_on_enter_from_field` |
| 4   | Empty name fields get a random fun name on Start Game | VERIFIED | `_on_start_game_pressed()` checks `name_text.is_empty()` and assigns `_random_fun_name()` (line 324); ADJECTIVES (12) + NOUNS (12) constants defined |
| 5   | Start Game hides setup, shows board configured for the selected player count and entered names | VERIFIED | `_on_start_game_pressed()` reads `_get_selected_count()`, builds `players` array from `name_inputs[i].text`, rebuilds score strip via `queue_free()+clear()+_setup_score_strip()`, resets grids, calls `await _fade_to_game()` then `_update_ui()` |
| 6   | Win overlay New Game button returns to setup screen with previous names and count preserved | VERIFIED | `_on_new_game_pressed()` calls `_fade_to_setup()` only (line 753); `_init_setup_screen()` is never called again after `_ready()` — LineEdit.text and ButtonGroup state persist; `_fade_to_setup()` hides win_overlay and shows setup_overlay |
| 7   | Transitions between setup and game use a quick fade (~0.2s) | VERIFIED | `_fade_to_game()`: Tween `modulate:a` 0.2s TRANS_SINE EASE_IN; `_fade_to_setup()`: Tween `modulate:a` 0.2s TRANS_SINE EASE_OUT |

**Score:** 7/7 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `scenes/main.tscn` | SetupOverlay node tree with Dimmer, SetupCard, CountRow, NamesContainer, PlayerRow0-3, NameInput0-3, StartButton | VERIFIED | All nodes present at correct scene paths; `visible=true` on SetupOverlay; `visible=false` on PlayerRow2/3; `toggle_mode=true` on all 3 count buttons; `max_length=15` on all 4 LineEdits |
| `scripts/main.gd` | Setup screen logic, dynamic player init, Play Again reroute | VERIFIED | 908 lines; all planned functions present: `_init_setup_screen`, `_on_start_game_pressed`, `_on_count_selected`, `_fade_to_setup`, `_fade_to_game`, `_random_fun_name`, `_on_enter_from_field`, `_style_button_neutral`, `_update_name_field_visibility`, `_show_player_row`, `_hide_player_row`, `_get_selected_count` |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `_on_start_game_pressed` | `players array + player_count` | reads LineEdit.text and `_get_selected_count()` to build dynamic players array | WIRED | Line 318: `player_count = _get_selected_count()`; line 322: `name_inputs[i].text.strip_edges()`; line 325: `players.append({"name": name_text, ...})` |
| `_on_new_game_pressed` | `_fade_to_setup` | New Game button routes to setup instead of resetting in place | WIRED | Line 753: `_fade_to_setup()` — entire function body is a single call |
| `_ready` | SetupOverlay visible | `_ready` shows setup overlay, hides HBoxContainer | WIRED | Line 143: `hbox_container.visible = false`; scene line 109: `visible = true` on SetupOverlay; `_init_setup_screen()` called at line 150 |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| SETUP-01 | 03-01-PLAN.md | Player count selection (2-4) at game start | SATISFIED | CountBtn2/3/4 with ButtonGroup exclusive toggle; `_get_selected_count()` drives `player_count` in `_on_start_game_pressed` |
| SETUP-02 | 03-01-PLAN.md | Player name entry at game start | SATISFIED | 4 LineEdit nodes in scene with `max_length=15`; pre-filled with random fun names; `name_inputs[i].text` read on Start Game |
| WIN-03 | 03-01-PLAN.md | Play Again returns to player count/name selection | SATISFIED | `_on_new_game_pressed()` calls `_fade_to_setup()`; setup screen preserves all state since `_init_setup_screen()` is only called once at `_ready()` |

No orphaned requirements: REQUIREMENTS.md maps exactly SETUP-01, SETUP-02, WIN-03 to Phase 3, matching the plan's `requirements:` field exactly.

### Anti-Patterns Found

No anti-patterns detected:
- No TODO/FIXME/HACK/PLACEHOLDER comments in modified files
- No empty implementations (`return null`, `return {}`, `return []`, `=> {}`)
- No stub handlers (form handlers make real API calls / state changes)
- No console-only handlers
- Both commits (44a0204, b4381d3) confirmed present in git log

### Human Verification Required

Automated static checks pass on all 7 truths and all key links. The following items require runtime verification in Godot 4:

#### 1. Setup Screen Visual Appearance

**Test:** Launch game (F5 in Godot editor). Verify setup screen appears centered on dark background with no board visible.
**Expected:** Dark dimmer behind setup card; board/sidebar hidden; CountBtn2 gold-styled, CountBtn3/4 neutral-styled; NameInput0 has coral border, NameInput1 has slate-blue border; both pre-filled with random fun names (adjective + noun, not "Player 1"/"Player 2"); Start Game button is gold.
**Why human:** Visual styling (StyleBoxFlat color rendering, border visibility, card centering via anchors) requires the Godot renderer.

#### 2. Count Toggle Animation

**Test:** Click 3 — third name field slides in. Click 2 — it slides out. Click 4 — fields 3 and 4 slide in. Click 2 — both slide out.
**Expected:** Smooth ~0.15s TRANS_SINE slide animation; correct player-color borders on revealed fields (sage for Player 3, amber for Player 4).
**Why human:** Tween animation quality and dynamic row visibility are runtime behaviors.

#### 3. Name Field Character Limit

**Test:** Type more than 15 characters in any name field.
**Expected:** Input is capped at 15 characters.
**Why human:** `max_length=15` is set in scene (verified), but interactive capping needs confirmation.

#### 4. Enter Key Field Chaining

**Test:** With 3 players selected, press Enter in field 1 → focus moves to field 2; Enter in field 2 → focus moves to field 3; Enter in field 3 → game starts. With 2 players, Enter in field 1 → focus to field 2; Enter in field 2 → game starts.
**Expected:** Chaining respects selected count at the time Enter is pressed.
**Why human:** Focus management and keyboard event handling require interactive testing.

#### 5. Start Game Transition and Score Strip

**Test:** Enter names "Alice", "Bob", "Charlie" with 3 players selected, press Start Game.
**Expected:** setup_overlay fades out over ~0.2s, game board and sidebar appear, score strip shows 3 panels with "Alice: 0", "Bob: 0", "Charlie: 0" in player colors (coral, slate-blue, sage).
**Why human:** Fade transition quality and score strip dynamic rebuild require runtime confirmation.

#### 6. New Game Returns to Setup with State Preserved

**Test:** Play to a win. Click New Game on win overlay. Verify: win overlay disappears, setup fades in, "Alice"/"Bob"/"Charlie" are still in fields 1/2/3, and "3" is still selected (gold).
**Expected:** Full round-trip with state preservation.
**Why human:** Session state persistence (LineEdit text, ButtonGroup selection) across transitions is a runtime behavioral property.

#### 7. Random Fun Name on Empty Field

**Test:** On setup screen, clear a name field (e.g., delete all text from field 1), press Start Game.
**Expected:** Score strip shows a randomly generated name (adjective + space + noun, e.g., "Brave Fox") instead of blank or "Player 1".
**Why human:** Random name generation on empty-field detection requires interactive triggering.

### Summary

All 7 observable truths are verified statically. The implementation in `scripts/main.gd` and `scenes/main.tscn` fully matches the plan's must-haves:

- SetupOverlay node tree is complete and correctly structured in the scene file
- All planned functions are implemented with substantive logic (not stubs)
- All 3 key links are wired: start-game reads setup state to build dynamic players array, new-game routes to setup rather than resetting in-place, and `_ready()` hides the game board and shows the setup overlay
- All 3 requirements (SETUP-01, SETUP-02, WIN-03) have clear implementation evidence
- Commits 44a0204 and b4381d3 are present in git history

The 7 human verification items above cover visual appearance, animation quality, and interactive keyboard/click behaviors that cannot be confirmed by static analysis. No blockers were found in the automated checks.

---

_Verified: 2026-03-14_
_Verifier: Claude (gsd-verifier)_
