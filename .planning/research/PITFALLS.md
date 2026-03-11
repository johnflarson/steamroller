# Domain Pitfalls

**Domain:** Godot 4 turn-based board game with HTML5 + desktop export
**Project:** Dice Grid Game (10x10, 2-4 players, GDScript, Control nodes)
**Researched:** 2026-03-11
**Confidence note:** Based on training knowledge of Godot 4 (through ~August 2025). Web and official doc access was unavailable during this research run. Flag as MEDIUM confidence; verify HTML5-specific claims against current Godot docs before the export phase.

---

## Critical Pitfalls

Mistakes that cause rewrites or major debugging sessions.

---

### Pitfall 1: State Machine Bypasses via Direct Signal Wiring

**What goes wrong:** Cell buttons are wired directly to a function that both rolls the die and claims the cell. As the game grows, signals from the grid bleed into the wrong phase (e.g., a cell click is processed while still in WAIT_ROLL), producing ghost moves, double-claims, or score miscalculations that are hard to reproduce.

**Why it happens:** Godot's signal system makes it tempting to connect `button_pressed` directly to game logic. Without a gating state machine, every signal fires regardless of game phase.

**Consequences:** Race conditions between UI events and game state. Especially nasty because it works fine in simple linear testing but breaks when players click quickly or when auto-reroll triggers during a pick phase.

**Prevention:**
- Implement the WAIT_ROLL / WAIT_PICK two-phase state machine as a single enum + match block before wiring any signals.
- All cell buttons emit a generic `cell_selected(x, y)` signal. The game controller's handler ignores it unless `current_phase == WAIT_PICK`.
- Disable all cell buttons programmatically when entering WAIT_ROLL. Enable only valid-move cells when entering WAIT_PICK.

**Detection:**
- Players can claim cells without rolling first.
- Score jumps by more than 1 in a single turn.
- Auto-reroll triggers mid-pick.

**Phase:** Address in Phase 1 (core game loop scaffolding) before any UI wiring.

---

### Pitfall 2: Line Detection Off-by-One in Diagonal Directions

**What goes wrong:** The scoring logic checks 4 directions (horizontal, vertical, two diagonals) from the placed cell, but iterates `range(-2, 3)` or similar without correctly handling the "count the placed cell itself once" requirement. Results in lines of 2 reporting as 3, or genuine lines of 3 being missed at board edges.

**Why it happens:** The standard approach — walk in both directions from the placed cell, count owned cells, sum — is easy to mis-implement. A common mistake is counting the origin cell twice (once per direction walk) or using separate pass/fail logic per direction without a unified counter.

**Consequences:** Scores are wrong. Players notice immediately. Hard to debug because it only manifests for specific board positions.

**Prevention:**
- Use a single function `count_line(x, y, dx, dy) -> int` that walks in +direction and -direction from the origin, counting consecutive owned cells belonging to the current player, then returns `positive_run + negative_run + 1` (the placed cell).
- Call this for all four direction pairs: (1,0), (0,1), (1,1), (1,-1).
- Score if any direction returns >= 3.
- Unit test the function with known board states before integrating into the turn loop.

**Detection:**
- Place three cells in a known diagonal line — no point awarded.
- Two cells adjacent — point incorrectly awarded.
- Cells at row 0 or column 0 behave differently from interior cells.

**Phase:** Address in Phase 1 (scoring logic). Write tests immediately.

---

### Pitfall 3: GridContainer Cell Count Mismatch Causing Silent Layout Corruption

**What goes wrong:** A `GridContainer` with `columns = 10` is populated by adding child buttons in a loop. If the loop adds 99 or 101 buttons (off-by-one in a nested loop), the grid silently renders wrong — last row has 9 cells, or an extra cell appears. The bug is invisible at a glance.

**Why it happens:** Nested loop `for y in range(10): for x in range(10)` is correct, but copy-paste errors, range typos (`range(1, 11)` vs `range(10)`), or a stray `break` introduce the off-by-one. GridContainer does not warn when it receives a non-multiple-of-columns count.

**Consequences:** Board positions are misaligned from `board_numbers[y][x]`. Cell at visual position (9,0) maps to data position (8,9). Scoring and claiming operate on the wrong cell data.

**Prevention:**
- After populating, assert `grid_container.get_child_count() == 100` with a hard crash in debug builds (`assert(grid_container.get_child_count() == 100, "Board cell count mismatch")`).
- Store each cell button reference in a `cells[y][x]` 2D array at creation time. Use that array — never `get_child(y * 10 + x)` — to access cells by coordinate.

**Detection:**
- Visual inspection: last row looks short or has an extra cell.
- Claiming cell (9,9) highlights a different cell than expected.

**Phase:** Address in Phase 1 (board setup). The assertion catches it immediately.

---

### Pitfall 4: HTML5 Export Broken by SharedArrayBuffer / Thread Requirements

**What goes wrong:** Godot 4's default HTML5 export template requires `SharedArrayBuffer`, which browsers only provide when the page is served with specific CORS headers (`Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp`). Without these headers, the game either fails silently or shows a black screen. GitHub Pages and many simple static hosts do not set these headers by default.

**Why it happens:** Godot 4's web export uses threads internally. The threading APIs require `SharedArrayBuffer`, which browsers gate behind these security headers post-Spectre.

**Consequences:** Game works perfectly in the Godot editor's web export preview but fails on the actual hosting platform. Discovered late if web testing isn't done early.

**Prevention:**
- Use the **single-threaded** web export template (`Export > Web > Threads: disabled`). This is available in Godot 4.x and removes the `SharedArrayBuffer` requirement.
- Alternatively, configure the hosting server to emit the required headers. For GitHub Pages, this requires a custom `_headers` file (Netlify) or a Service Worker hack — messy.
- Test the HTML5 build on the actual hosting platform in Phase 1 or early Phase 2, not at the end.

**Detection:**
- Black screen or console error `SharedArrayBuffer is not defined` when opening the hosted build.
- Works in `godot --export-debug` local server but not on host.

**Phase:** Address in Phase 2 (first HTML5 export attempt). Configure single-threaded template from the start.

---

### Pitfall 5: Parallel Data Arrays Desyncing (`board_numbers` vs `owner`)

**What goes wrong:** The game uses two parallel 2D arrays: `board_numbers[y][x]` (1-6) and `owner[y][x]` (-1 or player index). Anywhere the arrays are initialized, reset, or resized independently, they can go out of sync. A reset-on-new-game that clears `owner` but regenerates `board_numbers` in a different loop order leaves stale state.

**Why it happens:** Two mutable arrays tracking the same conceptual object (a cell) is a classic data coherence problem. Every operation that touches one must touch both.

**Consequences:** Claimed cells appear available. Cells show the wrong number. Line detection scores on cleared cells.

**Prevention:**
- Encapsulate both arrays behind a single `BoardData` class (a `RefCounted` or inner class). Expose only `get_cell_number(x, y)`, `get_owner(x, y)`, `claim_cell(x, y, player)`, `reset()`. Never access the raw arrays outside this class.
- `reset()` initializes both arrays atomically in one pass.

**Detection:**
- After starting a new game, some cells appear pre-claimed.
- Clicking a visually empty cell has no effect (it's still marked claimed from the previous game).

**Phase:** Address in Phase 1 (data model design). Encapsulate before writing any game logic.

---

## Moderate Pitfalls

---

### Pitfall 6: Auto-Reroll Infinite Loop

**What goes wrong:** The auto-reroll requirement (reroll when no valid moves exist for the current roll) is implemented as a recursive call or a `while` loop. If the board is nearly full and no number has unclaimed cells, the loop spins indefinitely, hanging the game.

**Why it happens:** Developers test auto-reroll with a mostly empty board where it quickly resolves. The edge case — board almost full — is not considered.

**Prevention:**
- Before rerolling, check if ANY unclaimed cell exists. If none, the game should end or declare a special outcome rather than rerolling.
- The "first to 5 points wins" condition means the game usually ends before the board fills, but add the check regardless.
- Limit reroll attempts to a max of 6 (one per die face) and if all faces have no valid cells, trigger end-of-game.

**Detection:**
- Game freezes when the board is nearly full.
- Editor shows high CPU usage with no visible activity.

**Phase:** Address in Phase 1 (turn flow logic).

---

### Pitfall 7: Valid Move Highlighting Left Active After Turn Ends

**What goes wrong:** After a player claims a cell, the highlight state (color/border indicating valid moves) is not cleared before the next player's WAIT_ROLL phase. The next player sees highlighted cells that match the previous player's roll.

**Why it happens:** Highlighting is applied to cell buttons on entering WAIT_PICK. Developers remember to highlight on entry but forget to clear on exit (claiming or rerolling).

**Prevention:**
- Create a dedicated `clear_highlights()` function called at the start of `_enter_wait_roll()` and after any cell claim.
- The state machine's `_exit_wait_pick()` always calls `clear_highlights()`.

**Detection:**
- After claiming a cell, some cell buttons retain a highlight color.
- Two consecutive players see the same highlighted cells.

**Phase:** Address in Phase 1 (UI state management).

---

### Pitfall 8: Player Color Collision with Cell Number Text

**What goes wrong:** Player colors are chosen that work well against a neutral background but become illegible when used as a cell background color with dark text showing the cell number (1-6). E.g., a dark blue player color with dark text makes the number unreadable.

**Why it happens:** Colors are picked for board appearance (bright, distinct) without considering text contrast on that background.

**Prevention:**
- Choose player colors from a palette with known good contrast against white or light text: e.g., a medium-dark red, medium-dark blue, dark green, medium purple. Test all 4 against both white and dark text.
- Use white text on all claimed cells (`label.add_theme_color_override("font_color", Color.WHITE)`).
- Pre-validate the 4 player colors in the project before building the UI.

**Detection:**
- Cell number is hard to read after claiming.
- Colors look fine in the color picker but not on the actual button.

**Phase:** Address in Phase 1 (visual design, before building the cell button scene).

---

### Pitfall 9: Turn Order Skipping in Player Array Logic

**What goes wrong:** Advancing to the next player uses `current_player = (current_player + 1) % player_count`. This works for 2 and 4 players but is incorrect for 3 players when the `players` array size changes mid-game (it shouldn't, but if `player_count` is read from the wrong variable, it produces index errors or skipped turns).

**Why it happens:** Two sources of truth: `players.size()` and a separate `player_count` variable. If they ever diverge, the modulo uses the wrong value.

**Prevention:**
- Derive player count exclusively from `players.size()`. Delete any separate `player_count` variable.
- `current_player = (current_player + 1) % players.size()`.

**Detection:**
- 3-player game skips Player 2 entirely after Player 1.
- Array index out of bounds error in the console when accessing `players[current_player]`.

**Phase:** Address in Phase 1 (player setup).

---

### Pitfall 10: Game Log Growing Without Bounds

**What goes wrong:** The game log (`RichTextLabel` or similar in a `ScrollContainer`) accumulates every roll, claim, and score event for the entire game. For a long game this is fine, but if the log is naively rebuilt (cleared and repopulated) on every update, it causes noticeable UI stutter. If not cleared between games, the second game's log contains the first game's history.

**Why it happens:** Appending to a `RichTextLabel` is easy but reset logic is often omitted or called at the wrong time.

**Prevention:**
- Use `RichTextLabel.append_text()` to add entries incrementally. Never rebuild the full log.
- Call `RichTextLabel.clear()` in the new-game initialization path, explicitly.
- Limit visible log entries to the last N (e.g., 20) if performance becomes a concern — but for this game scope it likely won't.

**Detection:**
- Starting a new game still shows the previous game's events.
- Log scrolls many pages for a long game.

**Phase:** Address in Phase 2 (game log implementation).

---

### Pitfall 11: GridContainer Not Scaling Correctly at Different Viewport Sizes

**What goes wrong:** A `GridContainer` with fixed pixel sizes for cell buttons looks correct at 1080p but overflows its container at 768p (common on smaller laptop screens or constrained browser windows). Because Control nodes use pixel-based sizing by default, the grid either clips or forces a scrollbar.

**Why it happens:** Cell button sizes are hardcoded (e.g., `custom_minimum_size = Vector2(50, 50)`) without considering that the container might be smaller than `10 * 50 = 500px`.

**Prevention:**
- Use a `GridContainer` inside a `AspectRatioContainer` or constrain it to a percentage of the viewport via anchors.
- Use `custom_minimum_size` only as a floor, not a fixed size. Let the grid fill available space.
- Alternatively, compute cell size dynamically: `cell_size = floor(grid_container.size.x / 10)` and apply it at `_ready()` and on `resized` signal.
- Test at 1280x720 and 1920x1080 minimum.

**Detection:**
- At smaller window sizes, cells are cut off or a scrollbar appears on the board.
- Browser window resize causes visual artifacts.

**Phase:** Address in Phase 2 (layout and responsiveness). Design for it in Phase 1.

---

## Minor Pitfalls

---

### Pitfall 12: Forgetting `queue_free()` on Orphaned Nodes Between Games

**What goes wrong:** If cells are dynamically instantiated (not static scene children), starting a new game that re-instantiates cells without freeing the old ones causes duplicate nodes. The old cells remain in the scene tree, invisible but active, consuming memory and potentially receiving signals.

**Prevention:**
- If cells are dynamic: call `grid_container.queue_free_children()` (or loop `for child in grid_container.get_children(): child.queue_free()`) before regenerating.
- Prefer a static scene where the 100 cells exist as permanent children and are only reset, not recreated.

**Phase:** Address in Phase 1 (cell instantiation strategy decision).

---

### Pitfall 13: `randi() % 6` Produces Biased Results

**What goes wrong:** `randi() % 6` does not produce a perfectly uniform distribution if `RAND_MAX` is not a multiple of 6 (which it isn't). In practice for a d6, the bias is negligible (< 0.001%), but `randi_range(1, 6)` is the idiomatic Godot 4 function and avoids any concern.

**Prevention:**
- Use `randi_range(1, 6)` for all die rolls and board initialization.

**Phase:** Address in Phase 1 (any randomization code).

---

### Pitfall 14: Input Event Handling on Disabled Buttons

**What goes wrong:** Setting `button.disabled = true` prevents normal press events, but mouse-over and focus events still fire. If hover styling is applied via signals (not theme overrides), disabled cells may show hover highlights, confusing players about which cells are valid.

**Prevention:**
- Use `mouse_filter = Control.MOUSE_FILTER_IGNORE` on disabled cells if hover behavior is completely unwanted.
- Or rely entirely on Godot's built-in disabled state + theme styling (`disabled` StyleBox in the theme) rather than signal-based hover logic.

**Phase:** Address in Phase 2 (UI polish).

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Board data setup | Parallel array desync (#5) | Encapsulate in a BoardData class from day one |
| Scoring logic | Off-by-one in diagonal line detection (#2) | Write and test `count_line()` in isolation before integrating |
| State machine wiring | Signal bypass (#1) | Build state enum before wiring any button signals |
| Turn loop | Auto-reroll infinite loop (#6) | Add "any unclaimed cells exist?" guard before reroll logic |
| GridContainer population | Cell count mismatch (#3) | Assert child count == 100 after population |
| First HTML5 build | SharedArrayBuffer failure (#4) | Use single-threaded export template; test on real host early |
| UI scaling | Grid overflow at small viewports (#11) | Anchor grid to viewport percentage; test at 1280x720 |
| New game flow | Orphaned nodes (#12), stale log (#10) | Explicit reset/free paths for all persistent UI |

---

## Sources

- Training knowledge of Godot 4.x (GDScript, Control nodes, HTML5 export), assessed through ~August 2025. Confidence: MEDIUM.
- HTML5 SharedArrayBuffer requirement is a well-documented browser security policy (post-Spectre, 2021+). Confidence: HIGH for the browser policy itself; MEDIUM for exact Godot export template naming (verify in current Godot 4 export docs).
- Line detection off-by-one is a recurring pattern in Godot board game community posts and general game dev forums. Confidence: HIGH (domain-general, not Godot-specific).
- GridContainer behavior is based on Godot 4 Control node documentation patterns. Confidence: HIGH.
- Flag: All HTML5-specific claims should be verified against https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html before the export phase.
