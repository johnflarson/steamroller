# Phase 3: Setup and Game Flow - Research

**Researched:** 2026-03-14
**Domain:** Godot 4 GDScript — UI screen management, LineEdit, ButtonGroup, Tween transitions, dynamic player state
**Confidence:** HIGH (core APIs verified via official docs and GitHub source; patterns match existing codebase)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Setup Screen Layout**
- Centered card on dark background — no game title or heading, straight to player count selection
- Card uses same dark panel style as sidebar (SIDEBAR_BG color, rounded corners) for visual consistency
- Board/HUD hidden during setup — same scene, visibility toggled
- Start Game button uses gold accent style (same as Roll button)

**Player Count Selection**
- Three toggle buttons in a row: [2] [3] [4]
- Default selection: 2 players
- Selected button gets gold accent fill; unselected buttons use dark neutral style (like grid cells)
- Changing count shows/hides name fields with slide in/out animation
- Fixed color assignment order always: coral=P1, slate blue=P2, sage=P3, amber=P4 regardless of count
- Names in hidden fields are preserved (switching 4→2→4 keeps P3/P4 names)

**Name Entry**
- Input fields pre-filled with default names ("Player 1", "Player 2", etc.)
- Max 15 characters per name
- Empty fields at game start get a random fun name (adjective+noun style: "Brave Fox", "Lucky Star", "Swift Bear")
- Each name input has a colored border in that player's muted color (coral, slate blue, sage, amber) — consistent with score strip style
- Enter/Return in a name field advances focus to the next field; Enter on the last field starts the game

**Play Again Flow**
- Win overlay shows single "New Game" button (replaces current behavior)
- "New Game" returns to setup screen (satisfies WIN-03)
- Previous names and player count are remembered in setup fields on return
- Quick fade transition (~0.2s) between setup↔game and game-over→setup

### Claude's Discretion

- Exact slide animation duration and easing for name fields
- Random name word lists (adjective and noun pools)
- Fade transition implementation details
- Setup card sizing and padding
- Input field styling details beyond colored border

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SETUP-01 | Player count selection (2-4) at game start | ButtonGroup with toggle_mode; visibility toggling of name field rows |
| SETUP-02 | Player name entry at game start | LineEdit nodes with max_length=15, text_submitted signal, placeholder_text, colored border via StyleBoxFlat wrapping PanelContainer |
| WIN-03 | Play Again returns to player count/name selection | _on_new_game_pressed() rerouted to show setup overlay; game state preserved in setup fields |
</phase_requirements>

---

## Summary

Phase 3 adds a setup screen that gatekeeps gameplay: the player selects 2/3/4 players, enters names, then starts the game. The same single-scene approach used throughout the project applies here — the setup card is a Control node whose visibility is toggled, layered over the hidden game UI. On win/stalemate, "New Game" fades back to this setup screen with prior state intact.

The codebase already has all the primitives needed. `_style_button_gold()`, `SIDEBAR_BG`, `PLAYER_COLORS`, and `_set_cell_color()` are directly reusable. The Tween API already used for score animation handles both the ~0.2s fade transitions and the name field slide animation. The only genuinely new Godot APIs are `LineEdit` (for name entry) and `ButtonGroup` (for exclusive count selection).

The main integration challenges are: (1) re-initializing the `players` array dynamically from setup state when starting a game, (2) avoiding double-fired signals since `_build_grid()` connects signals once at `_ready()` and must never be called again, and (3) rebuilding `score_panels`/`score_labels` when player count changes between games.

**Primary recommendation:** Implement setup as a full-screen `Control` overlay (like `WinOverlay`) added to `main.tscn`, shown at `_ready()` and hidden when Start Game is pressed. This minimizes structural changes to the existing scene.

---

## Standard Stack

### Core
| Library/API | Version | Purpose | Why Standard |
|-------------|---------|---------|--------------|
| `LineEdit` (Godot built-in) | Godot 4.x | Single-line text input for player names | Only Control node designed for text entry in Godot UI |
| `ButtonGroup` (Godot built-in) | Godot 4.x | Exclusive toggle selection for player count [2][3][4] | Built-in radio-button behavior; no custom state tracking needed |
| `Tween` (Godot built-in) | Godot 4.x | Fade transitions and slide animations | Already used in project for score animation; same API |
| `StyleBoxFlat` (Godot built-in) | Godot 4.x | Colored borders on name inputs and setup card | Already used project-wide for all custom styling |

### No New Dependencies

This phase requires zero new dependencies. All required functionality is in the Godot 4 standard library and already used in the existing codebase.

---

## Architecture Patterns

### Recommended Project Structure

No new files are required. All setup logic lives in `scripts/main.gd`. The scene `scenes/main.tscn` gains one new top-level child: `SetupOverlay`.

```
scenes/main.tscn
├── [existing] HBoxContainer   ← hidden during setup
├── [existing] WinOverlay      ← hidden during gameplay
└── [NEW] SetupOverlay         ← shown first, hidden during gameplay
    ├── Dimmer (ColorRect)     ← full-screen dark bg (same as WinOverlay)
    └── SetupCard (PanelContainer)
        └── VBox (VBoxContainer)
            ├── CountRow (HBoxContainer)   ← [2] [3] [4] buttons
            ├── NamesContainer (VBoxContainer) ← one row per player
            │   ├── PlayerRow0 (HBoxContainer)
            │   │   └── NameInput0 (LineEdit)
            │   ├── PlayerRow1 (HBoxContainer)
            │   │   └── NameInput1 (LineEdit)
            │   ├── PlayerRow2 (HBoxContainer)  ← visible only for 3-4 players
            │   │   └── NameInput2 (LineEdit)
            │   └── PlayerRow3 (HBoxContainer)  ← visible only for 4 players
            │       └── NameInput3 (LineEdit)
            └── StartButton (Button)
```

### Pattern 1: Setup Overlay as Full-Screen Control

**What:** A `Control` node with `anchor_right=1.0`, `anchor_bottom=1.0`, `visible=false` in scene file. Shown at game start, hidden when game begins.

**When to use:** When a full-screen UI state needs to overlay or replace the existing game scene without a scene reload.

**Example:**
```gdscript
# In _ready() — show setup instead of going straight to gameplay
func _ready() -> void:
    # ... existing style setup ...
    _init_arrays()
    _generate_board()
    _build_grid()
    # Don't call _setup_score_strip() or _update_ui() yet
    # Hide game UI, show setup
    $HBoxContainer.visible = false
    $SetupOverlay.visible = true
    _init_setup_screen()
```

### Pattern 2: ButtonGroup for Exclusive Count Toggle

**What:** Three `Button` nodes with `toggle_mode = true` assigned to a shared `ButtonGroup`. ButtonGroup enforces that only one is pressed at a time. Style the pressed/unpressed states manually with `add_theme_stylebox_override()` because ButtonGroup does not auto-apply visual styles.

**Key constraint:** `toggle_mode` MUST be `true` on each button, or ButtonGroup behavior is undefined.

**Example:**
```gdscript
# Creating ButtonGroup in code (can also be done in .tscn)
var bg := ButtonGroup.new()
for btn in [count_btn_2, count_btn_3, count_btn_4]:
    btn.toggle_mode = true
    btn.button_group = bg

# Handle selection change
bg.pressed.connect(_on_count_selected)

func _on_count_selected(btn: BaseButton) -> void:
    var count: int = int(btn.text)  # btn.text is "2", "3", or "4"
    _update_count_button_styles()
    _update_name_field_visibility(count)

func _update_count_button_styles() -> void:
    for btn in [count_btn_2, count_btn_3, count_btn_4]:
        if btn.button_pressed:
            _style_button_gold(btn)   # reuse existing helper
        else:
            _style_button_neutral(btn)  # new helper using NEUTRAL_CELL
```

**Source:** ButtonGroup docs confirm `toggle_mode=true` requirement and `pressed(BaseButton)` signal. (docs.godotengine.org/en/stable/classes/class_buttongroup.html)

### Pattern 3: LineEdit for Name Entry

**What:** `LineEdit` node with `max_length = 15`, `placeholder_text = "Player N"`, and `text = "Player N"` (pre-filled). The `text_submitted` signal fires on Enter/Return. Focus navigation uses `grab_focus()` on the next field.

**Key constraint:** Setting `text` programmatically does NOT emit `text_changed`. This is correct behavior — we want to pre-fill without triggering validation logic.

**Styling bordered inputs:** `LineEdit` does not have a `PanelContainer` wrapper, so colored borders must be applied via `add_theme_stylebox_override("normal", style)` directly on the `LineEdit` itself. The stylebox name is `"normal"` for the default state.

**Example:**
```gdscript
# Setup a name input field
func _setup_name_input(field: LineEdit, player_idx: int) -> void:
    field.max_length = 15
    field.placeholder_text = "Player %d" % (player_idx + 1)
    field.text = "Player %d" % (player_idx + 1)
    # Colored border using player's muted color
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.20, 0.20, 0.25)  # dark input bg
    style.set_border_width_all(2)
    style.border_color = PLAYER_COLORS[player_idx]
    style.set_corner_radius_all(6)
    style.corner_detail = 4
    style.set_content_margin_all(6)
    field.add_theme_stylebox_override("normal", style)
    field.add_theme_stylebox_override("focus", style)  # keep border on focus
    field.add_theme_color_override("font_color", Color.WHITE)
    field.add_theme_color_override("font_placeholder_color", Color(0.6, 0.6, 0.6))

# Chain Enter key through fields
func _connect_name_field_chain() -> void:
    # Enter on field 0 → focus field 1, etc.
    # Enter on last visible field → start game
    name_inputs[0].text_submitted.connect(func(_t): name_inputs[1].grab_focus())
    name_inputs[1].text_submitted.connect(func(_t): _on_enter_from_field(1))
    name_inputs[2].text_submitted.connect(func(_t): _on_enter_from_field(2))
    name_inputs[3].text_submitted.connect(func(_t): _on_start_game_pressed())

func _on_enter_from_field(idx: int) -> void:
    var selected: int = _get_selected_count()
    if idx + 1 < selected:
        name_inputs[idx + 1].grab_focus()
    else:
        _on_start_game_pressed()
```

**Source:** LineEdit XML docs confirm `text_submitted` fires on `ui_text_submit` (Enter/Kp Enter). `grab_focus()` enters edit mode immediately.

### Pattern 4: Fade Transition (~0.2s)

**What:** Tween `modulate:a` on the overlay Control node from 0→1 (fade in) or 1→0 (fade out). Use `await tween.finished` if code must run after the transition completes (e.g., hiding the node after fade out).

**Key constraint:** The node must be `visible = true` before tweening alpha in. After fading out, set `visible = false` to stop input interception. Use `modulate` (not `self_modulate`) so the tween affects all children.

**Example:**
```gdscript
func _fade_to_setup() -> void:
    # Show setup overlay, fade it in
    setup_overlay.modulate.a = 0.0
    setup_overlay.visible = true
    var tw := create_tween()
    tw.tween_property(setup_overlay, "modulate:a", 1.0, 0.2)\
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    # Simultaneously hide game UI
    hbox_container.visible = false

func _fade_to_game() -> void:
    var tw := create_tween()
    tw.tween_property(setup_overlay, "modulate:a", 0.0, 0.2)\
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
    await tw.finished
    setup_overlay.visible = false
    hbox_container.visible = true
    hbox_container.modulate.a = 1.0
```

**Source:** Godot community verified pattern (forum.godotengine.org). `modulate:a` property path confirmed by multiple Godot 4 examples.

### Pattern 5: Name Field Slide Show/Hide

**What:** Show/hide P3 and P4 name rows when count changes. The "slide" effect is achieved by tweening `custom_minimum_size` from `Vector2(0, 0)` to full size, combined with a fade on `modulate:a`.

**Key constraint:** Direct position tweening on Container children is blocked by the container layout engine. Use `custom_minimum_size` to animate height, or simply toggle `visible` — the container reflowing is acceptable for a 2-count vs 4-count switch. The context grants Claude discretion on slide animation details.

**Simple approach (visibility toggle, no animation):**
```gdscript
func _update_name_field_visibility(count: int) -> void:
    player_rows[2].visible = (count >= 3)
    player_rows[3].visible = (count >= 4)
```

**Animated approach (tween custom_minimum_size):**
```gdscript
func _show_player_row(row: Control) -> void:
    row.visible = true
    row.custom_minimum_size = Vector2(0, 0)
    row.modulate.a = 0.0
    var tw := create_tween()
    tw.set_parallel(true)
    tw.tween_property(row, "custom_minimum_size", Vector2(0, 40), 0.15)\
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    tw.tween_property(row, "modulate:a", 1.0, 0.15)

func _hide_player_row(row: Control) -> void:
    var tw := create_tween()
    tw.set_parallel(true)
    tw.tween_property(row, "custom_minimum_size", Vector2(0, 0), 0.12)\
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
    tw.tween_property(row, "modulate:a", 0.0, 0.12)
    await tw.finished
    row.visible = false
```

**Note:** `set_parallel(true)` runs both tweens simultaneously. `await tw.finished` safely hides after animation completes.

### Pattern 6: Dynamic Player Array Initialization

**What:** When Start Game is pressed, rebuild the `players` array from current setup state before starting gameplay.

**Key constraint:** `players` is currently hardcoded to 4 entries. Phase 3 makes it dynamic. The `player_count` var is already present and used by `_setup_score_strip()`, `_advance_turn()`, `_resolve_stalemate()`, etc. — those all work correctly with any count 2-4.

**Example:**
```gdscript
func _on_start_game_pressed() -> void:
    player_count = _get_selected_count()  # 2, 3, or 4
    players = []
    for i in player_count:
        var name_text: String = name_inputs[i].text.strip_edges()
        if name_text.is_empty():
            name_text = _random_fun_name()
        players.append({"name": name_text, "color": PLAYER_COLORS[i], "score": 0})
    # Rebuild score strip for new player count
    for child in score_strip.get_children():
        child.queue_free()
    score_labels.clear()
    score_panels.clear()
    _setup_score_strip()
    # Reset game state
    current_player = 0
    current_roll = 0
    state = GameState.WAIT_ROLL
    # Reset grids
    for r in rows:
        for c in cols:
            owner_grid[r][c] = -1
            scored_grid[r][c] = false
    _generate_board()
    # Update buttons in place (DO NOT call _build_grid() again)
    for r in rows:
        for c in cols:
            var btn: Button = cell_buttons[r][c]
            btn.text = str(board_numbers[r][c])
            btn.disabled = false
            btn.scale = Vector2.ONE
            _set_cell_color(btn, NEUTRAL_CELL)
    game_log.clear()
    _fade_to_game()
    _update_ui()
```

**CRITICAL:** Never call `_build_grid()` again after `_ready()`. The existing comment in `_claim_cell()` warns about this — signal double-fire. Reuse existing buttons, update their content in place. This pattern is already used in `_on_new_game_pressed()`.

### Anti-Patterns to Avoid

- **Calling `_build_grid()` on New Game:** Double-connects pressed signals on all 100 cell buttons, causing every cell click to fire twice. The existing code comment explicitly warns about this.
- **Rebuilding score strip without clearing children:** `score_strip.add_child()` adds to existing children. Always call `queue_free()` on existing children and `clear()` on `score_labels`/`score_panels` arrays before calling `_setup_score_strip()`.
- **Setting LineEdit `text` via signal handler:** Setting `field.text = "..."` in a `text_changed` callback creates an infinite signal loop.
- **Tweening visibility bool directly:** `visible` is a bool, not tweeneable. Tween `modulate:a` then set `visible = false` after fade.
- **Placing setup overlay below WinOverlay in scene tree:** Node order matters for mouse_filter — ensure SetupOverlay draws above (or is at same level as) WinOverlay, and toggle visibility to manage which is active.
- **Tab key for focus navigation in LineEdit:** Tab inserts a tab character, not focus navigation. Use `text_submitted` signal + `grab_focus()` for Enter-based navigation instead.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Exclusive toggle (radio buttons) | Custom `selected_count` var + manual deselect all | `ButtonGroup` with `toggle_mode=true` | ButtonGroup handles exclusivity automatically; one signal on group |
| Text input | Label + keyboard input_event handler | `LineEdit` | LineEdit handles cursor, selection, backspace, IME, clipboard, all input edge cases |
| Fade animation | Manual `_process()` delta accumulation | `Tween.tween_property(node, "modulate:a", ...)` | Tween is fire-and-forget, handles easing, supports `await finished` |
| Random name generation | External library | Pure GDScript with two static arrays | Trivial to implement inline; no library needed |

**Key insight:** The Godot standard library covers everything Phase 3 needs. No third-party assets or GDScript addons are required.

---

## Common Pitfalls

### Pitfall 1: Score Strip Not Rebuilt on Player Count Change
**What goes wrong:** On "New Game" with a different player count, the old score panels remain, leaving stale colored borders for the wrong number of players.
**Why it happens:** `_setup_score_strip()` appends to `score_strip` without clearing it first.
**How to avoid:** Before calling `_setup_score_strip()`, iterate `score_strip.get_children()` and call `child.queue_free()`, then `score_labels.clear()` and `score_panels.clear()`.
**Warning signs:** Score strip shows 4 panels when only 2 players are active.

### Pitfall 2: setup_overlay Intercepts Clicks During Gameplay
**What goes wrong:** Even with `visible = false`, if `mouse_filter` is not `MOUSE_FILTER_IGNORE`, a Control node can block mouse input.
**Why it happens:** Default `mouse_filter` for Control is `MOUSE_FILTER_STOP`.
**How to avoid:** Either set `visible = false` (which also disables input) — this is sufficient. Do not rely on `modulate.a = 0` alone; an invisible node still passes through input. Always pair fade-out with setting `visible = false` after the tween.
**Warning signs:** Roll button and cell buttons unresponsive during gameplay even though setup card appears invisible.

### Pitfall 3: _build_grid() Signal Double-Fire
**What goes wrong:** Calling `_build_grid()` on New Game connects a second `pressed` handler to each of the 100 cell buttons. Every click fires twice: one claim happens normally, the second fires on the now-owned cell and is silently rejected by the `owner_grid[row][col] != -1` guard — BUT the same cell click counts for two turns worth of state checks.
**Why it happens:** `btn.pressed.connect()` adds another connection; it doesn't replace the existing one.
**How to avoid:** Never call `_build_grid()` after `_ready()`. Update button text/style in place. The existing `_on_new_game_pressed()` already demonstrates the correct pattern.
**Warning signs:** Score events fire twice; turns skip; log shows duplicate entries.

### Pitfall 4: Player Count Mismatch Between Rounds
**What goes wrong:** `players` array has 4 entries from previous game, but `player_count` is set to 2 for new game. `_advance_turn()` uses `player_count` correctly, but other iteration patterns (e.g., `for i in players.size()`) walk all 4 entries.
**Why it happens:** `players` array not rebuilt before game start.
**How to avoid:** Always rebuild `players` array in `_on_start_game_pressed()` to exactly `player_count` entries.
**Warning signs:** Scores appear for Players 3/4 when game is configured for 2 players.

### Pitfall 5: Names Not Preserved on Return to Setup
**What goes wrong:** User plays a game, sees win screen, clicks "New Game", setup screen shows blank/default names instead of the names from the last game.
**Why it happens:** `_on_new_game_pressed()` resets `players` array entries, which clears the names — then setup screen reads stale default names.
**How to avoid:** Setup screen owns the canonical name state (in `LineEdit.text`). The setup screen should NOT be re-initialized on return from win screen. Only call `_init_setup_screen()` once at first `_ready()`. When returning from win screen, just show the overlay — the LineEdit text values persist.
**Warning signs:** Names reset to "Player 1", "Player 2" after each game.

### Pitfall 6: LineEdit styled with StyleBox but focus ring obscures border
**What goes wrong:** When a `LineEdit` receives focus, Godot draws the default `focus` StyleBox on top, which may be a bright outline that clashes with the colored player border.
**Why it happens:** The "focus" stylebox is drawn as an overlay on the "normal" stylebox. If not overridden, it uses the theme's default focus ring.
**How to avoid:** Override the "focus" stylebox with the same player-colored StyleBox as "normal", or a slightly brightened version. Use `add_theme_stylebox_override("focus", style)` on the LineEdit.

---

## Code Examples

Verified patterns from official sources and project codebase:

### LineEdit Basic Setup
```gdscript
# Source: Godot 4 LineEdit documentation + GitHub source XML
var field := LineEdit.new()
field.max_length = 15
field.placeholder_text = "Player 1"
field.text = "Player 1"        # pre-fill; does NOT emit text_changed
field.text_submitted.connect(func(t: String): _on_name_submitted(0, t))
```

### ButtonGroup Exclusive Toggle
```gdscript
# Source: Godot 4 ButtonGroup documentation
var group := ButtonGroup.new()
var btn2 := Button.new()
var btn3 := Button.new()
var btn4 := Button.new()
for b in [btn2, btn3, btn4]:
    b.toggle_mode = true
    b.button_group = group
btn2.button_pressed = true   # default selection
group.pressed.connect(_on_count_button_pressed)
```

### Tween Fade In/Out (modulate:a)
```gdscript
# Source: Godot 4 Tween documentation; confirmed in existing project (score flash uses same API)
# Fade in:
node.modulate.a = 0.0
node.visible = true
var tw := create_tween()
tw.tween_property(node, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE)

# Fade out (with await):
var tw := create_tween()
tw.tween_property(node, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
await tw.finished
node.visible = false
```

### Random Fun Name Generator
```gdscript
# No external source needed — pure GDScript, decided by Claude's discretion
const ADJECTIVES := ["Brave", "Lucky", "Swift", "Bold", "Calm", "Fierce",
                      "Jolly", "Keen", "Nimble", "Proud", "Witty", "Zesty"]
const NOUNS := ["Fox", "Bear", "Star", "Wolf", "Hawk", "Lion",
                 "Owl", "Puma", "Rook", "Sage", "Wren", "Lynx"]

func _random_fun_name() -> String:
    return ADJECTIVES[randi() % ADJECTIVES.size()] + " " + NOUNS[randi() % NOUNS.size()]
```

### Score Strip Rebuild for New Player Count
```gdscript
# Safe pattern for count-changing New Game
func _rebuild_score_strip() -> void:
    for child in score_strip.get_children():
        child.queue_free()
    score_labels.clear()
    score_panels.clear()
    _setup_score_strip()   # existing function, now correct count
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hardcoded `players` array (4 entries) | Dynamic `players` built from setup state | Phase 3 | Enables 2/3/4 player selection |
| `_on_new_game_pressed()` resets in-place | Routes to setup screen instead | Phase 3 | Satisfies WIN-03 |
| `_ready()` goes straight to gameplay | `_ready()` shows setup overlay first | Phase 3 | Satisfies SETUP-01, SETUP-02 |
| `player_count` defaults to 4 | Set by setup screen selection | Phase 3 | Game adapts to chosen player count |

**No deprecated approaches:** The Tween API and StyleBoxFlat patterns established in Phase 2 are the current standard — no changes needed.

---

## Open Questions

1. **LineEdit "focus" stylebox exact behavior**
   - What we know: "focus" stylebox is drawn as overlay on "normal"; must be overridden to preserve colored border on focus
   - What's unclear: Whether the default focus ring is fully replaced or composited — may require testing
   - Recommendation: Override both "normal" and "focus" with the same StyleBoxFlat; if the focus ring still appears, additionally override with a transparent StyleBoxFlat

2. **`queue_free()` on score strip children timing**
   - What we know: `queue_free()` defers deletion to end of frame; children still visible for one frame after call
   - What's unclear: Whether this causes a one-frame flash of old panels before new ones appear
   - Recommendation: Call `queue_free()` and immediately clear the arrays, then add new children in the same frame — Godot processes `queue_free()` after all current frame logic, so new children appear first

3. **Name field Enter key on last VISIBLE field**
   - What we know: Enter in last field should start game; which field is "last" depends on current count selection
   - What's unclear: Signal connection needs to be dynamic (not static index 3 always being last)
   - Recommendation: Use the `_on_enter_from_field(idx)` pattern shown above — check `player_count` at runtime to determine if the field is last

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None — Godot GDScript has no standard unit test runner in this project |
| Config file | none |
| Quick run command | Open `project.godot` in Godot 4 editor, press F5 (Play) |
| Full suite command | Manual play-through: start game, configure 2/3/4 players, verify all flows |

Godot 4 does have the GUT (Godot Unit Test) addon, but it is not installed in this project and is not needed for a single-scene game of this scope. Validation is done manually by running the game in the Godot editor.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Verification Method | Exists? |
|--------|----------|-----------|---------------------|---------|
| SETUP-01 | Player count [2][3][4] selectable at game start | manual-smoke | Run game: verify count buttons appear, selection changes visible name fields, default is 2 | Wave 0 |
| SETUP-02 | Player name entry pre-filled, max 15 chars, Enter chains fields | manual-smoke | Run game: verify pre-fill, type 16+ chars (truncates), Enter advances, Enter on last starts | Wave 0 |
| WIN-03 | New Game from win overlay returns to setup with prior state | manual-smoke | Play to win, click New Game: verify setup screen shown, previous names present | Wave 0 |

**All tests are manual-smoke (play in editor).** No automated test framework exists or is needed for this project.

### Sampling Rate
- **Per task commit:** Run game in editor (F5), verify the specific task's behavior
- **Per wave merge:** Full play-through: select players, enter names, play to win, return to setup
- **Phase gate:** All three requirements verified manually before `/gsd:verify-work`

### Wave 0 Gaps
None — no test infrastructure needs to be created. Manual testing via Godot editor is the established project standard.

---

## Sources

### Primary (HIGH confidence)
- Godot 4 LineEdit XML source (raw.githubusercontent.com/godotengine/godot/master/doc/classes/LineEdit.xml) — `max_length`, `text_submitted`, `placeholder_text`, `grab_focus`, `text` property behavior
- ButtonGroup documentation (docs.godotengine.org/en/stable/classes/class_buttongroup.html) — `toggle_mode` requirement, `pressed` signal, `get_pressed_button()`
- Existing project `scripts/main.gd` — Tween API usage, StyleBoxFlat patterns, `_style_button_gold()`, `_set_cell_color()`, `_on_new_game_pressed()` pattern

### Secondary (MEDIUM confidence)
- Godot community forums — fade via `modulate:a` Tween pattern confirmed by multiple independent sources
- Godot community forums — `custom_minimum_size` tween for container child animation (forum.godotengine.org)
- WebSearch: LineEdit `text_submitted` signal fires on Enter/Kp Enter by default

### Tertiary (LOW confidence)
- LineEdit "focus" stylebox overlay behavior — inferred from docs description; exact compositing behavior requires in-editor verification

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Godot built-ins, verified APIs, no third-party dependencies
- Architecture: HIGH — patterns directly derived from existing codebase; overlay approach already proven by `WinOverlay`
- Pitfalls: HIGH — signal double-fire documented in existing code comment; score strip clearing is a mechanical consequence of `add_child()` semantics; others verified by project history
- LineEdit stylebox theming: MEDIUM — `normal`/`focus` names confirmed by search; exact focus ring behavior requires testing

**Research date:** 2026-03-14
**Valid until:** 2026-09-14 (stable Godot 4 APIs; LOW churn expected)
