# Architecture Patterns

**Domain:** Turn-based dice grid board game (Godot 4, HTML5/desktop)
**Researched:** 2026-03-11
**Confidence:** MEDIUM — Godot 4 scene/signal patterns are well-established from docs and community; specific board game wiring is based on those established patterns applied to this project's constraints.

---

## Recommended Architecture

The game uses a single-scene architecture with a `GameManager` root that owns all state. The board is a pure display layer; all logic lives in scripts attached to the root or dedicated autoload-free manager nodes. Communication flows exclusively via signals going upward (cells → board → game) and method calls going downward (game → board → cell).

```
Main (Control)
├── GameManager (Node — script-only, holds all state)
│   ├── TurnManager (embedded in GameManager or separate Node)
│   └── ScoreManager (embedded in GameManager or separate Node)
├── BoardView (GridContainer or custom Control)
│   └── CellButton × 100 (Button — one per cell)
├── HUD (VBoxContainer)
│   ├── PlayerPanel (HBoxContainer — shows current player, scores)
│   ├── DicePanel (Control — shows roll result, Roll button)
│   └── GameLog (ScrollContainer > VBoxContainer)
└── SetupScreen (Control — player count selection, shown at start)
```

Two scenes minimum:
- `setup.tscn` — player count picker, launches game
- `game.tscn` — the full game scene above

Optional third scene:
- `game_over.tscn` — winner display with restart button (or handled inline in game.tscn)

---

## Component Boundaries

| Component | Responsibility | Owns | Does NOT own |
|-----------|---------------|------|--------------|
| `GameManager` | State machine (WAIT_ROLL / WAIT_PICK), turn sequencing, win detection, orchestration | `board_numbers[y][x]`, `owner[y][x]`, `players[]`, `current_player`, `current_roll`, `state` | Visual display, input handling |
| `TurnManager` | Advance to next player, detect auto-reroll condition, determine valid cells | Valid move list for current roll | Score calculation, visuals |
| `ScoreManager` | Line detection (4 directions from placed cell), award points | Score mutation | Everything else |
| `BoardView` | Render the 100 cells, highlight valid moves, update cell appearance | References to `CellButton` nodes | Game state, logic |
| `CellButton` | Display cell number and owner color, emit press signal | Its own visual state | Board logic |
| `HUD` | Display current player, scores, roll value, game log | UI labels and log entries | Game state |
| `SetupScreen` | Collect player count, emit to Main | Player count input | Anything game-related |

`GameManager` may be collapsed into the root `Main` node for a project this size — the key constraint is that **no logic lives in `BoardView` or `CellButton`**. Those are pure display.

---

## Data Flow

### Turn cycle — WAIT_ROLL phase

```
Player presses Roll button
  → DicePanel emits roll_pressed signal
  → GameManager.on_roll_pressed()
      → generates roll (1–6), stores current_roll
      → calls TurnManager.get_valid_cells(current_roll, owner)
      → if valid_cells is empty: auto-reroll (repeat)
      → stores valid_cells
      → transitions state → WAIT_PICK
      → calls BoardView.highlight_cells(valid_cells)
      → calls HUD.show_roll(current_roll)
```

### Turn cycle — WAIT_PICK phase

```
Player presses a CellButton
  → CellButton emits cell_pressed(x, y) signal
  → GameManager.on_cell_pressed(x, y)
      → validates (x, y) is in valid_cells, state is WAIT_PICK
      → updates owner[y][x] = current_player
      → calls ScoreManager.check_lines(x, y, current_player, owner)
          → returns true/false (line found)
      → if scored: players[current_player].score += 1
      → calls HUD.update_scores(players)
      → calls HUD.log_event(...)
      → calls BoardView.update_cell(x, y, player_color)
      → calls BoardView.clear_highlights()
      → checks win condition: if score >= 5 → show winner
      → advances current_player (TurnManager.next_player())
      → transitions state → WAIT_ROLL
      → calls HUD.show_current_player(current_player)
```

### Signal registry

| Signal | Emitter | Receiver | Payload |
|--------|---------|---------|---------|
| `roll_pressed` | DicePanel | GameManager | — |
| `cell_pressed(x, y)` | CellButton | GameManager | int, int |
| `setup_confirmed(count)` | SetupScreen | Main | int |

No signal travels from GameManager downward. GameManager calls methods on child nodes directly. This prevents feedback loops and keeps state mutation in one place.

---

## Patterns to Follow

### Pattern 1: Signals Up, Calls Down

**What:** Child nodes emit signals to report events. Parent/manager nodes call methods on children to update display.

**When:** Always. This is the standard Godot scene communication contract.

**Example:**
```gdscript
# CellButton — emits, does not call up
signal cell_pressed(x: int, y: int)

func _on_button_pressed() -> void:
    cell_pressed.emit(col, row)

# GameManager — calls down, never emits to children
func _on_cell_pressed(x: int, y: int) -> void:
    owner[y][x] = current_player
    board_view.update_cell(x, y, players[current_player].color)
```

### Pattern 2: Flat State Machine with Enum Guard

**What:** A single `State` enum on `GameManager`. Every input handler checks state before acting.

**When:** Any time there are two mutually exclusive input modes (rolling vs. picking).

**Example:**
```gdscript
enum State { WAIT_ROLL, WAIT_PICK }
var state: State = State.WAIT_ROLL

func _on_roll_pressed() -> void:
    if state != State.WAIT_ROLL:
        return
    # ... proceed

func _on_cell_pressed(x: int, y: int) -> void:
    if state != State.WAIT_PICK:
        return
    if Vector2i(x, y) not in valid_cells:
        return
    # ... proceed
```

### Pattern 3: Line Detection From Placed Cell Only

**What:** After placing at (x, y), check all 4 directions (±x, ±y, ±diag) from that cell outward. No need to scan the whole board.

**When:** Scoring check after every placement.

**Example:**
```gdscript
func check_lines(x: int, y: int, player: int, owner: Array) -> bool:
    var directions = [Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(1,-1)]
    for dir in directions:
        var count = 1
        for sign in [1, -1]:
            var nx = x + dir.x * sign
            var ny = y + dir.y * sign
            while _in_bounds(nx, ny) and owner[ny][nx] == player:
                count += 1
                nx += dir.x * sign
                ny += dir.y * sign
        if count >= 3:
            return true
    return false
```

### Pattern 4: BoardView Iterates Its Own Children

**What:** `BoardView` creates its 100 `CellButton` children at `_ready()` time and stores them in a `cells[y][x]` array for O(1) access during updates.

**When:** Any time a specific cell needs visual update without a full redraw.

**Example:**
```gdscript
var cells: Array = []  # cells[y][x] -> CellButton

func _ready() -> void:
    cells = []
    for y in 10:
        var row = []
        for x in 10:
            var btn = CellButton.new()
            btn.col = x
            btn.row = y
            btn.cell_pressed.connect(_on_cell_pressed)
            add_child(btn)
            row.append(btn)
        cells.append(row)

func update_cell(x: int, y: int, color: Color) -> void:
    cells[y][x].set_owner_color(color)
```

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Logic in CellButton

**What:** Putting ownership checks, scoring, or state transitions inside `CellButton._on_pressed()`.

**Why bad:** The cell cannot know global state. Logic scattered across 100 nodes is impossible to debug or test. A cell press should only report coordinates.

**Instead:** CellButton emits `cell_pressed(x, y)`. All logic runs in GameManager.

### Anti-Pattern 2: Signals Flowing Down the Tree

**What:** GameManager emitting signals that BoardView or CellButton listens to.

**Why bad:** Creates hidden coupling. When a parent calls a child method directly, the dependency is visible in code. When a parent emits and a child listens, the dependency is invisible until runtime.

**Instead:** GameManager calls `board_view.update_cell(...)` directly. Reserve signals for upward communication.

### Anti-Pattern 3: Board Data Living in BoardView

**What:** Storing `board_numbers` or `owner` arrays on the `BoardView` node.

**Why bad:** GameManager needs both arrays constantly for validation and scoring. If they live in BoardView, GameManager must reach into the display layer for data, coupling logic to rendering.

**Instead:** Both arrays live on `GameManager`. BoardView only holds node references.

### Anti-Pattern 4: Autoloads for Game State

**What:** Putting `players`, `owner`, `state`, etc. into a global autoload singleton.

**Why bad:** Unnecessary for a single-scene game. Autoloads make state lifetime hard to reason about and complicate testing. The game starts fresh every match — a local GameManager is sufficient.

**Instead:** All state on `GameManager`. Pass references or signals where needed. Use autoloads only for truly global concerns (e.g., a settings singleton) if added later.

### Anti-Pattern 5: Rebuilding the Grid on Every Turn

**What:** Calling `queue_free()` on all CellButtons and recreating them each turn.

**Why bad:** Causes flicker, breaks signal connections, kills performance on HTML5.

**Instead:** Create all 100 buttons once at `_ready()`. Update only visual properties (color, disabled state) in place.

---

## Scene File Layout

```
res://
├── scenes/
│   ├── game.tscn          # Main game scene
│   ├── setup.tscn         # Player count selection
│   └── game_over.tscn     # Winner screen (optional)
├── scripts/
│   ├── game_manager.gd    # State machine, orchestration
│   ├── turn_manager.gd    # Valid move calculation, player advance
│   ├── score_manager.gd   # Line detection, scoring
│   ├── board_view.gd      # Grid rendering, highlight management
│   ├── cell_button.gd     # Single cell display + signal
│   └── hud.gd             # Scores, roll display, game log
└── project.godot
```

Scripts are kept separate from `.tscn` files (not embedded). This is the Godot 4 best practice for scenes shared across multiple uses and for keeping diffs readable.

---

## Suggested Build Order

Dependencies determine order. Build from the bottom up — data before display, display before integration.

```
Step 1: CellButton
  - No dependencies
  - Deliverable: Button that shows a number, emits cell_pressed(x, y)

Step 2: BoardView
  - Depends on: CellButton
  - Deliverable: 10x10 grid that can highlight and update cells

Step 3: GameManager (data layer only)
  - Depends on: nothing (pure logic)
  - Deliverable: board_numbers, owner, players arrays; state machine; turn/score logic

Step 4: HUD
  - Depends on: nothing (pure display)
  - Deliverable: Shows current player, scores, roll value, log entries

Step 5: Wire GameManager ↔ BoardView ↔ HUD
  - Depends on: Steps 1–4
  - Deliverable: Full game loop playable without setup screen

Step 6: SetupScreen
  - Depends on: GameManager (needs to pass player count)
  - Deliverable: Player count selection flows into game start

Step 7: Game Over / Win detection
  - Depends on: Full game loop
  - Deliverable: Win state display, restart flow
```

---

## Scalability Considerations

This is a local multiplayer game with a fixed 10x10 board. Scalability concerns are minimal and should not drive decisions.

| Concern | At current scope | If scope expands |
|---------|-----------------|-----------------|
| Board size | Fixed 10x10 — hardcode fine | Parameterize grid dimensions in GameManager |
| Player count | 2–4, array lookup | Array scales trivially to any N |
| Line detection | O(40) per placement (4 dirs × up to 10 cells) | Acceptable for any reasonable board |
| HTML5 performance | 100 Button nodes is trivial | Keep textures lightweight; avoid GDScript loops >1000 iter per frame |

---

## Sources

- Godot 4 official docs — scene organization and best practices (training data, HIGH confidence for established Godot patterns)
- Godot 4 Control node + GridContainer behavior for HTML5 export (training data, HIGH confidence — this is core engine functionality)
- State machine patterns in GDScript — standard community pattern, well-documented (MEDIUM confidence — verified against project's own stated design in PROJECT.md)
- Line detection algorithm — standard board game pattern (HIGH confidence)
