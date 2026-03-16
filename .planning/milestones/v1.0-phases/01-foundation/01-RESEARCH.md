# Phase 1: Foundation - Research

**Researched:** 2026-03-11
**Domain:** Godot 4 / GDScript — turn-based grid board game core loop
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Board Generation
- Weighted random distribution: each number (1-6) appears roughly equally (~16-17 times) but with natural variance — not strictly balanced, not pure random
- Count-balanced only — no spatial distribution constraints (same numbers can cluster)
- Fresh random board generated each new game (no seed support)
- All cell numbers visible to players at all times (matches PROJECT.md: "cell buttons show the cell's number")
- Fixed d6 for Phase 1, but data model should use a configurable dice range variable (not hardcoded to 6) for future extensibility
- Grid size stored as configurable rows/cols variables (default 10x10), not hardcoded

#### Stalemate Handling
- If all cells claimed and no player has 5 points: highest score wins
- Ties resolved as shared victory (all tied players win together)
- No near-stalemate warnings or countdown
- Unlimited consecutive auto-rerolls until a valid move is found; each reroll logged

#### Line Detection & Scoring
- Lines of 3, 4, or 5 owned cells all score exactly 1 point (no bonus for longer lines)
- Line detection checks only from the just-placed cell (4 directions: horizontal, vertical, 2 diagonals) — not a full board scan
- Cells that participated in a scored line become "spent" — they cannot contribute to future line scoring
- Data model needs a per-cell "scored" boolean flag to track spent status
- Spent cells remain owned/colored but will be visually distinct in Phase 2

#### Editor-Playable UI (Phase 1 Minimum)
- Functional clickable grid buttons showing cell numbers, changing color when claimed
- Roll button, text labels for current player, roll result, and scores
- In-game log visible in the scene (not just console output) showing rolls, claims, scores, rerolls
- Support 2-4 players with hardcoded names ("Player 1" through "Player 4") — no selection UI
- Basic valid-move highlighting: cells matching the roll visually change when claimable

### Claude's Discretion
- Exact weighted random algorithm for board generation
- GDScript architecture (scene tree structure, node organization)
- State machine implementation details
- Color palette for player ownership (functional, not polished)
- Log formatting and scroll behavior

### Deferred Ideas (OUT OF SCOPE)
- **Board visibility setting**: Toggle between always-visible and revealed-on-roll number modes — user wants this as a game setting (future phase, needs settings UI)
- **Configurable dice range**: d4/d8/d10 variants — data model prepared but not exposed in Phase 1
- **Custom board sizes**: Data model flexible but UI locked to 10x10 for v1
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| LOOP-01 | 10x10 grid with randomly generated cell values (1-6) at game start | Board generation algorithm, GridContainer with 100 Buttons, data arrays |
| LOOP-02 | Player rolls d6 via Roll button | randi_range(1,6), state machine WAIT_ROLL guard, Button signal |
| LOOP-03 | Valid cells (unclaimed, matching roll) highlighted after rolling | Array iteration, StyleBoxFlat or modulate for highlight color |
| LOOP-04 | Player claims a highlighted cell, which becomes owned (colored, disabled) | Button.disabled, StyleBoxFlat bg_color per player, owner array update |
| LOOP-05 | Turn auto-advances to next player after claim | current_player index increment modulo player count |
| LOOP-06 | Auto-reroll when no valid moves exist, with notification in game log | Loop-check function, RichTextLabel append_text log |
| SCOR-01 | +1 point when placement creates 3+ owned cells in a row (any direction) | 4-direction scan from placed cell, "spent" flag, count consecutive owned cells |
| SCOR-02 | Max 1 point per turn regardless of lines formed | Single scored boolean per turn, break after first qualifying line |
| WIN-01 | Game ends when a player reaches 5 points | Score check after each claim, state transition to GAME_OVER, disable all input |
</phase_requirements>

---

## Summary

This phase implements the complete game loop in Godot 4 using GDScript and Control nodes. The project is greenfield — no existing Godot files exist. The architecture follows Godot's recommended pattern of a single main scene with a script that owns all game state, using a simple enum-based state machine (WAIT_ROLL / WAIT_PICK / GAME_OVER).

The board is a GridContainer holding 100 Button nodes, each tracking its grid coordinates via metadata. Game state lives in parallel arrays: `board_numbers[row][col]`, `owner[row][col]` (player index or -1), and `scored[row][col]` (boolean). Player data is an array of dictionaries with name, color, and score.

Line detection operates only from the just-placed cell, scanning 4 directions (horizontal, vertical, two diagonals) by walking in both directions and counting consecutive owned cells not already scored. The "spent" flag prevents double-scoring.

**Primary recommendation:** Use a single Main.tscn scene with one attached Main.gd script owning all game logic. Keep the UI node references wired via @onready. Use Godot's built-in signals pattern — each cell button emits a signal carrying its (row, col) coordinates to the main script.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Godot Engine | 4.6 (stable, released ~Jan 2026) | Game engine + editor | Project constraint; best HTML5 export |
| GDScript | Built-in to Godot 4.6 | Game logic language | Project constraint; simpler than C# |

### Built-in Nodes Used
| Node | Purpose | Why This Node |
|------|---------|---------------|
| GridContainer | 10x10 button grid layout | Auto-arranges children in columns; columns property = 10 |
| Button | Individual grid cells | Clickable, disableable, text-capable |
| VBoxContainer / HBoxContainer | UI layout panels | Standard Control layout nodes |
| Label | Score, player name, roll result display | Simple text display |
| RichTextLabel | Scrollable game log | Supports append_text/append_bbcode, native scroll |
| ScrollContainer | Wraps RichTextLabel for scroll | Ensures log stays scrollable |

### No External Libraries
This project uses only Godot built-ins. No addons or plugins are needed for Phase 1.

**Godot project creation:**
```
# Use Godot 4.6 editor to create new project at /home/jlarson/code/dicegame/
# OR create project.godot manually — editor creation is required for correct setup
```

---

## Architecture Patterns

### Recommended Project Structure
```
dicegame/
├── project.godot          # Godot project file (created by editor)
├── scenes/
│   └── main.tscn          # The single game scene
├── scripts/
│   └── main.gd            # All game logic
└── .planning/             # (existing)
```

For Phase 1, a single scene + single script is sufficient. No autoloads needed — all state stays in Main.

### Pattern 1: Enum-Based State Machine
**What:** A top-level enum with 3 states (WAIT_ROLL, WAIT_PICK, GAME_OVER). The current state gates which actions are legal.
**When to use:** Ideal for simple turn-based games where each turn has exactly two sequential phases.
**Example:**
```gdscript
# Source: Godot community standard pattern (enum + match)
enum GameState { WAIT_ROLL, WAIT_PICK, GAME_OVER }
var state: GameState = GameState.WAIT_ROLL

func _on_roll_button_pressed() -> void:
    if state != GameState.WAIT_ROLL:
        return
    var result := randi_range(1, dice_faces)
    current_roll = result
    state = GameState.WAIT_PICK
    _highlight_valid_cells(result)
    _log("Player %s rolled a %d" % [players[current_player].name, result])
```

### Pattern 2: Grid Button with Embedded Coordinates
**What:** Each Button node stores its (row, col) as metadata, then emits that data when pressed.
**When to use:** Any time you need 100 buttons to report back their grid position without 100 separate signal handlers.
**Example:**
```gdscript
# Source: Godot docs — set_meta / get_meta pattern, signals with args
func _build_grid() -> void:
    for row in rows:
        for col in cols:
            var btn := Button.new()
            btn.text = str(board_numbers[row][col])
            btn.custom_minimum_size = Vector2(50, 50)
            btn.set_meta("row", row)
            btn.set_meta("col", col)
            btn.pressed.connect(_on_cell_pressed.bind(row, col))
            grid_container.add_child(btn)
            cell_buttons[row][col] = btn

func _on_cell_pressed(row: int, col: int) -> void:
    if state != GameState.WAIT_PICK:
        return
    if owner_grid[row][col] != -1:
        return
    if board_numbers[row][col] != current_roll:
        return
    _claim_cell(row, col)
```

### Pattern 3: Programmatic Button Color via StyleBoxFlat
**What:** Create a StyleBoxFlat per button state and apply it via add_theme_stylebox_override.
**When to use:** When you need the full button background color to change (not just font color).
**Example:**
```gdscript
# Source: Godot docs / community consensus
func _set_cell_color(btn: Button, color: Color) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    btn.add_theme_stylebox_override("normal", style)
    btn.add_theme_stylebox_override("hover", style)
    btn.add_theme_stylebox_override("pressed", style)
    btn.add_theme_stylebox_override("disabled", style)
```
Note: Must override all states (normal, hover, pressed, disabled) or the default theme colors will show through on hover/disabled.

### Pattern 4: Line Detection from Placed Cell
**What:** For each of 4 directions, walk in both axis directions from the placed cell and count consecutive owned-and-unscored cells belonging to the current player.
**When to use:** SCOR-01 and SCOR-02 requirement — check only from placed cell, not full board scan.
**Example:**
```gdscript
# Source: Standard board game line detection algorithm adapted to Godot
const DIRECTIONS := [
    Vector2i(1, 0),   # horizontal
    Vector2i(0, 1),   # vertical
    Vector2i(1, 1),   # diagonal down-right
    Vector2i(1, -1),  # diagonal down-left
]

func _check_score(row: int, col: int, player_idx: int) -> bool:
    for dir in DIRECTIONS:
        var cells := _collect_line(row, col, dir, player_idx)
        if cells.size() >= 3:
            # Mark all cells in this line as scored (spent)
            for c in cells:
                scored_grid[c.y][c.x] = true
            return true  # Only 1 point max per turn
    return false

func _collect_line(row: int, col: int, dir: Vector2i, player_idx: int) -> Array:
    var cells := [Vector2i(col, row)]
    # Walk forward
    var r := row + dir.y
    var c := col + dir.x
    while _in_bounds(r, c) and owner_grid[r][c] == player_idx and not scored_grid[r][c]:
        cells.append(Vector2i(c, r))
        r += dir.y
        c += dir.x
    # Walk backward
    r = row - dir.y
    c = col - dir.x
    while _in_bounds(r, c) and owner_grid[r][c] == player_idx and not scored_grid[r][c]:
        cells.append(Vector2i(c, r))
        r -= dir.y
        c -= dir.x
    return cells
```

### Pattern 5: Weighted Board Generation (Shuffle Bag)
**What:** Populate an array with exactly the right count per number, then shuffle it.
**When to use:** LOOP-01 — count-balanced but not perfectly uniform. "Weighted random feel."
**Example:**
```gdscript
# Source: Shuffle bag pattern, Godot docs — randi_range, array.shuffle()
func _generate_board() -> void:
    var total_cells := rows * cols  # 100
    var pool: Array[int] = []
    var base_count := total_cells / dice_faces  # 16
    var remainder := total_cells % dice_faces    # 4
    for face in range(1, dice_faces + 1):
        var count := base_count + (1 if face <= remainder else 0)
        for _i in count:
            pool.append(face)
    pool.shuffle()
    var idx := 0
    for r in rows:
        for c in cols:
            board_numbers[r][c] = pool[idx]
            idx += 1
```
This gives natural variance (some numbers slightly more frequent) without strict uniformity.

### Pattern 6: RichTextLabel Game Log
**What:** Append text to a RichTextLabel and auto-scroll to bottom after each entry.
**When to use:** LOOP-06, game event logging visible in scene.
**Example:**
```gdscript
# Source: Godot docs + community (append_text is correct method in Godot 4)
# Note: STATE.md flags append_text vs add_text as needing verification.
# append_text() is confirmed correct for runtime-created nodes in Godot 4.x
# add_text() also exists but is for plain text (no BBCode)
# Do NOT use += on text property — rebuilds entire label

func _log(message: String) -> void:
    log_label.append_text(message + "\n")
    # Auto-scroll to bottom
    await get_tree().process_frame
    log_label.get_v_scroll_bar().value = log_label.get_v_scroll_bar().max_value
```

### Anti-Patterns to Avoid
- **Hiding buttons in GridContainer:** Using `.hide()` on a child causes GridContainer to re-collapse the layout. Use `.modulate = Color(1,1,1,0)` or `visible = false` on a Panel wrapper instead. For this game, disable + color change is the correct approach (keep visible, mark claimed).
- **Direct `text += ""` on RichTextLabel:** Rebuilds entire BBCode from scratch on each append. Use `append_text()` instead.
- **Hardcoding grid size:** All grid dimensions must reference `rows` and `cols` variables.
- **Full board scan for line detection:** The locked decision specifies scanning only from the placed cell. Full board scans would be slower and incorrect for the "spent cell" mechanic.
- **Modifying a shared StyleBoxFlat:** If two buttons share the same StyleBoxFlat resource, changing one changes both. Always create a new `StyleBoxFlat.new()` per button.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Grid layout | Manual position calculation | GridContainer with `columns = 10` | Automatic reflow, no pixel math |
| Scrollable log | Custom scroll implementation | RichTextLabel inside ScrollContainer | Native scroll, works on web |
| Random numbers | Custom random algorithm | `randi_range()` / `array.shuffle()` | Engine-provided, properly seeded |
| Button state colors | Per-frame drawing code | StyleBoxFlat via `add_theme_stylebox_override` | Declarative, no draw calls |
| Signal routing | Global event bus for cell clicks | `.pressed.connect(_handler.bind(row, col))` | Simpler, less indirection for single scene |

**Key insight:** Godot's Control node system handles all layout, input routing, and rendering. The game logic (state machine, arrays, scoring) is pure GDScript data manipulation — do not reach for canvas or 2D nodes.

---

## Common Pitfalls

### Pitfall 1: Disabled Button Ignores StyleBoxFlat Overrides
**What goes wrong:** Button is disabled after claiming, but reverts to the default gray disabled appearance, hiding the player color.
**Why it happens:** The "disabled" StyleBoxFlat state overrides "normal". Must explicitly set the "disabled" override to the same player color.
**How to avoid:** Always call `add_theme_stylebox_override("disabled", style)` with the same color as "normal".
**Warning signs:** Claimed cells turn gray instead of player color.

### Pitfall 2: GridContainer with 100 Children Causes Layout Thrash
**What goes wrong:** Adding buttons one at a time in a loop causes repeated layout recalculations.
**Why it happens:** Each `add_child()` triggers a layout pass.
**How to avoid:** No simple workaround in Godot 4 Control system for this. For 100 cells it's acceptable. If performance is an issue, defer with `call_deferred("add_child", btn)` — but for a 10x10 grid this should not be noticeable.
**Warning signs:** Noticeable freeze at scene load.

### Pitfall 3: append_text on Freshly Instanced RichTextLabel
**What goes wrong:** Calling `append_text()` on a RichTextLabel created via `RichTextLabel.new()` in code (not via scene) may not display text.
**Why it happens:** Known Godot issue (GitHub #94630): append_text and add_text may not work on code-instanced labels before they enter the scene tree.
**How to avoid:** Build the RichTextLabel in the .tscn scene (via editor), not via code. Reference it with `@onready`. If you must create it in code, add it to the scene tree first before appending text.
**Warning signs:** Log appears empty even after `append_text()` calls.

### Pitfall 4: Auto-Reroll Infinite Loop Hangs Editor
**What goes wrong:** When all cells are claimed, checking for valid moves and rerolling loops forever.
**Why it happens:** The loop never exits if the board is full — no valid moves will ever appear.
**How to avoid:** Before attempting auto-reroll, check if the board has any unclaimed cells at all. If none, trigger stalemate resolution instead.
**Warning signs:** Editor freezes on a nearly-full board.

### Pitfall 5: Signal Connected Multiple Times
**What goes wrong:** Calling `_build_grid()` again (e.g., for new game) reconnects all button signals, causing `_on_cell_pressed` to fire multiple times per click.
**Why it happens:** `connect()` does not check for existing connections by default.
**How to avoid:** Either (a) free all button children before rebuilding, or (b) use `connect(..., CONNECT_ONE_SHOT)` pattern, or (c) check `is_connected()` before connecting.
**Warning signs:** Claiming one cell claims multiple cells or logs duplicate events.

### Pitfall 6: Spent Flag Not Persisted on New Lines
**What goes wrong:** A cell participates in a scoring line, is marked "spent", but a subsequent turn forms a new line through that cell — the new line counts the spent cell and scores again.
**Why it happens:** Line detection walks the whole chain without checking the `scored` flag per cell.
**How to avoid:** `_collect_line()` must skip cells where `scored_grid[r][c] == true` when building the line.
**Warning signs:** Players score more than 1 point from expected cell layouts.

---

## Code Examples

### Data Model Initialization
```gdscript
# Source: PROJECT.md architecture decisions
const WIN_SCORE := 5
var rows := 10
var cols := 10
var dice_faces := 6  # Configurable per CONTEXT.md decision

var board_numbers: Array = []   # [row][col] -> int 1-6
var owner_grid: Array = []      # [row][col] -> int (-1 = unclaimed, 0..3 = player index)
var scored_grid: Array = []     # [row][col] -> bool (spent/scored cells)
var cell_buttons: Array = []    # [row][col] -> Button node reference

var players: Array = [
    {"name": "Player 1", "color": Color.RED,    "score": 0},
    {"name": "Player 2", "color": Color.BLUE,   "score": 0},
    {"name": "Player 3", "color": Color.GREEN,  "score": 0},
    {"name": "Player 4", "color": Color.YELLOW, "score": 0},
]
var player_count := 4  # Default 4 for testing per CONTEXT.md
var current_player := 0
var current_roll := 0

func _init_arrays() -> void:
    board_numbers = []
    owner_grid = []
    scored_grid = []
    cell_buttons = []
    for r in rows:
        board_numbers.append([])
        owner_grid.append([])
        scored_grid.append([])
        cell_buttons.append([])
        for c in cols:
            board_numbers[r].append(0)
            owner_grid[r].append(-1)
            scored_grid[r].append(false)
            cell_buttons[r].append(null)
```

### Turn Advance
```gdscript
# Source: Standard modulo player rotation
func _advance_turn() -> void:
    current_player = (current_player + 1) % player_count
    state = GameState.WAIT_ROLL
    _clear_highlights()
    _update_ui()
```

### Win / Stalemate Check
```gdscript
func _check_win_or_stalemate() -> bool:
    # Win check
    if players[current_player].score >= WIN_SCORE:
        state = GameState.GAME_OVER
        _log("Game over! %s wins!" % players[current_player].name)
        _disable_all_cells()
        return true
    # Stalemate check
    var any_unclaimed := false
    for r in rows:
        for c in cols:
            if owner_grid[r][c] == -1:
                any_unclaimed = true
                break
        if any_unclaimed:
            break
    if not any_unclaimed:
        state = GameState.GAME_OVER
        _resolve_stalemate()
        return true
    return false
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `emit_signal("signal_name")` | `signal_name.emit()` | Godot 4.0 | New syntax preferred; old still works |
| `connect("pressed", self, "_handler")` | `pressed.connect(_handler)` | Godot 4.0 | Cleaner callable syntax |
| `randomize()` (required) | Auto-seeded in Godot 4 | Godot 4.0 | `randomize()` is now a no-op / unnecessary |
| Godot 4.5.x | Godot 4.6 (stable, ~Jan 2026) | Jan 2026 | Use 4.6 for latest stable features |

**Deprecated / outdated:**
- `yield()`: Replaced by `await` in Godot 4
- `connect(signal, target, method_name_string)`: Old Godot 3 style; use callable syntax in Godot 4
- `randomize()`: Still exists but no longer required — RNG auto-seeds in Godot 4

---

## Open Questions

1. **RichTextLabel method: append_text vs add_text**
   - What we know: Both methods exist in Godot 4. `append_text()` is for BBCode, `add_text()` is for plain text. GitHub issue #94630 documents edge case with code-created labels.
   - What's unclear: Whether Godot 4.6 specifically resolved the code-instanced label issue.
   - Recommendation: Build RichTextLabel in the .tscn scene editor, not via code. This avoids the issue entirely. Use `append_text()` for the log.

2. **Godot project initialization without editor**
   - What we know: `project.godot` must be created before any .tscn or .gd files will be recognized. No existing Godot project files exist in the repo.
   - What's unclear: Whether the planner should include a "create Godot project" step or assume this is a prerequisite.
   - Recommendation: Wave 0 plan must include creating the Godot project via editor as the very first step. All subsequent tasks assume the project file exists.

3. **HTML5 export template in Godot 4.6**
   - What we know: STATE.md notes to "Confirm HTML5 single-threaded export template option name in current Godot version."
   - What's unclear: Exact UI label in Godot 4.6's Export dialog for single-threaded mode.
   - Recommendation: Defer to Phase 4 research as noted in STATE.md. Not relevant for Phase 1.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | GUT (Godot Unit Test) v9.x — designed for Godot 4.x |
| Config file | `res://addons/gut/` after installation via Godot Asset Library |
| Quick run command | Run via Godot editor: Scene > Run specific test scene, or use GUT command line plugin |
| Full suite command | `godot --headless -s addons/gut/gut_cmdln.gd` |

Note: GUT requires Godot project to exist first (Wave 0). It is installed as a Godot addon, not via npm/pip/cargo.

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LOOP-01 | Board generates 100 cells, each with value 1-6, all numbers appear ≥14 times | unit | GUT test: `test_board_generation.gd` | ❌ Wave 0 |
| LOOP-02 | Roll button disabled in WAIT_PICK state; enabled in WAIT_ROLL state | unit | GUT test: `test_state_machine.gd` | ❌ Wave 0 |
| LOOP-03 | After roll, exactly `n` cells highlighted where `n` = unclaimed cells matching roll value | unit | GUT test: `test_highlight.gd` | ❌ Wave 0 |
| LOOP-04 | After claiming cell, owner_grid updated, button disabled, player color applied | unit | GUT test: `test_claim.gd` | ❌ Wave 0 |
| LOOP-05 | After claim, current_player advances to next player (wraps around) | unit | GUT test: `test_turn_advance.gd` | ❌ Wave 0 |
| LOOP-06 | When no valid cells exist for roll, auto-reroll occurs and log entry added | unit | GUT test: `test_auto_reroll.gd` | ❌ Wave 0 |
| SCOR-01 | Placing cell that completes 3-in-a-row awards +1 point; 5-in-a-row also awards only +1 | unit | GUT test: `test_scoring.gd` | ❌ Wave 0 |
| SCOR-02 | Single placement forming two lines simultaneously still awards only 1 point | unit | GUT test: `test_scoring.gd` | ❌ Wave 0 |
| WIN-01 | Game state transitions to GAME_OVER when player reaches 5 points; further input blocked | unit | GUT test: `test_win_condition.gd` | ❌ Wave 0 |

Note: GUT tests for Godot are run in-editor or headless, not via standard CLI. The `godot --headless` approach requires Godot binary to be on PATH. For Phase 1 verification, manual playtest in editor is the primary validation mechanism alongside GUT unit tests for the pure logic functions.

Alternative lightweight approach: Core game logic (board generation, line detection, scoring, state transitions) can be extracted into pure GDScript utility functions with no scene dependencies, making them trivially testable with GUT or even simple test scripts.

### Sampling Rate
- **Per task commit:** Run relevant GUT test file in editor (e.g., `test_scoring.gd` after scoring work)
- **Per wave merge:** Full GUT suite headless: `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/`
- **Phase gate:** All GUT tests green + manual playtest confirms complete game loop before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] Create Godot 4.6 project at `/home/jlarson/code/dicegame/` (editor required — no CLI equivalent)
- [ ] `project.godot` — must exist before any other files
- [ ] Install GUT addon via Godot Asset Library or manual download
- [ ] `tests/` directory with GUT test files (listed in req map above)
- [ ] `scenes/main.tscn` — main scene (empty, created in editor)
- [ ] `scripts/main.gd` — attached to main scene

---

## Sources

### Primary (HIGH confidence)
- [Godot 4.6 stable](https://godotengine.org/download/archive/4.6-stable/) — current stable version confirmed
- [Godot docs: GridContainer](https://docs.godotengine.org/en/stable/classes/class_gridcontainer.html) — columns property, layout behavior
- [Godot docs: Scene organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html) — node communication patterns, signal usage
- [Godot docs: Random number generation](https://docs.godotengine.org/en/stable/tutorials/math/random_number_generation.html) — randi_range, shuffle bag pattern
- [Godot docs: Singletons/Autoload](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html) — autoload pattern (determined NOT needed for Phase 1)
- [GUT GitHub](https://github.com/bitwes/Gut) — v9.x for Godot 4.x, installation method

### Secondary (MEDIUM confidence)
- [Godot Forum: RichTextLabel append_text issue](https://github.com/godotengine/godot/issues/94630) — code-instanced label bug; mitigated by using editor-created nodes
- [Godot Forum: Button color via GDScript](https://forum.godotengine.org/t/how-to-change-button-color-via-gdscript/63624) — StyleBoxFlat pattern confirmed by community
- [Godot Forum: GridContainer button sizing](https://forum.godotengine.org/t/gridcontainer-buttons-very-small-tictactoeultimate/87026) — custom_minimum_size workaround

### Tertiary (LOW confidence)
- WebSearch results on state machine patterns — well-established pattern, confirmed consistent across sources

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Godot 4.6 confirmed current stable; all nodes are core engine features
- Architecture: HIGH — single-scene pattern well-supported by Godot docs; patterns are standard GDScript idioms
- Pitfalls: MEDIUM-HIGH — disabled button style override and append_text issue verified from official GitHub/docs; GridContainer behavior verified from forum reports
- Test framework: MEDIUM — GUT v9.x for Godot 4 confirmed; headless CLI syntax needs validation when Godot binary is available

**Research date:** 2026-03-11
**Valid until:** 2026-06-11 (Godot 4.x stable, 90-day estimate; re-verify if Godot 4.7 releases)
