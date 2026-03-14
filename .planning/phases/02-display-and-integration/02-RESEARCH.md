# Phase 2: Display and Integration - Research

**Researched:** 2026-03-14
**Domain:** Godot 4 / GDScript — UI polish, Tween animations, StyleBoxFlat theming, RichTextLabel BBCode, HTML5 export
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Visual Theming
- Softer/muted player color palette (e.g., coral, slate blue, sage, amber) replacing raw RED/BLUE/GREEN/YELLOW
- Dark theme background (charcoal/dark gray) as default — muted colors pop against dark
- Cells have rounded corners with subtle 2-3px gaps between them (GridContainer spacing)
- Spent cells (already scored) shown as dimmed/faded version of player color (~50% opacity/saturation)
- Valid-move highlight uses a glowing border/outline (e.g., gold/white) rather than background color fill
- Sidebar has a subtle background panel (slightly different shade, rounded edges) to separate from board

#### Score Line Flash (SCOR-03)
- Scale pop effect: scoring cells briefly enlarge (~1.2x scale) then return to normal
- Quick ~0.3s duration — keeps game pace snappy
- Score updates during the animation (not waiting for animation to complete)
- After pop animation, scored cells immediately transition to dimmed/spent appearance
- Use Godot Tween API for the animation

#### Win Announcement (WIN-02)
- Semi-transparent overlay dims the board, centered panel shows winner info
- Displays winner name prominently + ranked list of all players with final scores
- Overlay header/border tinted with winning player's color
- Stalemate endings use same overlay layout but "Game Over" message instead of "X wins!", showing highest scorer(s)
- Board remains visible underneath overlay

#### HUD & Sidebar
- Current player shown as colored name badge (player's muted color as background, like a tag/chip)
- Dice roll result displayed as large prominent number (48px+ font), unmissable
- Scores displayed as compact horizontal bar (all scores in one strip, like a sports ticker)
- Game log entries color-coded by acting player using RichTextLabel BBCode — score events get bold/highlight emphasis
- Roll button styled as prominent accent button (larger, distinct accent/gold color), visually disabled during pick phase

### Claude's Discretion
- Exact muted color hex values for each player
- Dark theme exact background shades
- Font choices and sizes (beyond roll result being large)
- Exact glow/outline thickness and color for valid-move highlight
- Sidebar panel corner radius and padding
- Game log formatting details beyond color-coding
- HTML5 export configuration specifics

### Deferred Ideas (OUT OF SCOPE)
- **Light/dark theme toggle**: User wants players to select between light and dark themes — needs settings UI, deferred to future phase
- **Board visibility setting** (from Phase 1): Toggle between always-visible and revealed-on-roll number modes
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SCOR-03 | Line flash animation briefly highlights the scoring cells | Tween.tween_property on "scale", pivot_offset centering, TRANS_BACK/EASE_OUT pattern |
| WIN-02 | Win announcement screen with final scores | ColorRect semi-transparent overlay, Panel/VBoxContainer centered, MOUSE_FILTER_STOP to block board input |
| UI-01 | Current player clearly indicated (name + color) | Colored Panel badge via StyleBoxFlat bg_color, Label child for name text |
| UI-02 | Roll result prominently displayed | Label with add_theme_font_size_override or large fixed size, updated in _update_ui() |
| UI-03 | All player scores visible at all times | HBoxContainer score strip, one Label per player, updated in _update_ui() |
| UI-04 | Scrollable game log showing rolls, claims, scores, and auto-rerolls | RichTextLabel with BBCode [color=hex] tags, enhanced _log() accepting player_idx |
| UI-05 | Responsive layout that works in browser and desktop windows | Control node anchors, SIZE_EXPAND_FILL flags, HTML5 export test with serve.py |
</phase_requirements>

---

## Summary

Phase 2 builds on the functional Phase 1 game loop to make every game event visible and the layout polished. The work falls into four distinct areas: (1) visual theming of cells and UI panels using StyleBoxFlat properties, (2) the Tween-based scale pop animation for scoring lines, (3) the win/stalemate overlay panel, and (4) HTML5 export verification.

All the building blocks are already in place from Phase 1: `_set_cell_color()` extends cleanly to support rounded corners and border outlines, `RichTextLabel` with `bbcode_enabled` is ready for color-coded log entries, the `GAME_OVER` state controls overlay visibility, and `_check_score()` returns the scoring cells the animation needs. The main new technical areas are the Tween API (straightforward in Godot 4) and the HTML5 local test server setup.

The HTML5 export requires either a custom Python server script (`serve.py` from Godot's repo) that sends the required `Cross-Origin-Embedder-Policy` and `Cross-Origin-Opener-Policy` headers, or exporting with the single-threaded template which relaxes the SharedArrayBuffer requirement.

**Primary recommendation:** Implement theming and UI polish in early tasks, animation second, win overlay third, and reserve a dedicated task for the HTML5 export verification smoke test.

---

## Standard Stack

### Core
| Library / API | Version | Purpose | Why Standard |
|---------------|---------|---------|--------------|
| Godot 4 Tween | 4.x built-in | Property animation (scale pop, modulate fade) | Native node method `create_tween()` — zero dependencies, integrates with scene tree lifetime |
| StyleBoxFlat | 4.x built-in | Cell rounded corners, border highlights, panel backgrounds | Already used in Phase 1 `_set_cell_color()`; supports all needed properties in pure GDScript |
| RichTextLabel BBCode | 4.x built-in | Color-coded log entries | Already wired in scene (`bbcode_enabled = true`); `append_text()` confirmed working pattern from Phase 1 |
| Control anchors + SIZE_EXPAND_FILL | 4.x built-in | Responsive layout | Godot's native layout system — correct approach for browser resize |

### Supporting
| Library / API | Version | Purpose | When to Use |
|---------------|---------|---------|-------------|
| Godot `serve.py` | Godot repo | Local HTTP server with correct CORS headers for HTML5 export test | Use for the HTML5 smoke-test task; download once from godotengine/godot |
| ColorRect | 4.x built-in | Semi-transparent overlay background | Win/stalemate overlay dim layer |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Tween scale pop | AnimationPlayer | AnimationPlayer is better for complex reusable animations; for a one-shot 0.3s scale pop on dynamic cells, Tween in code is simpler and avoids scene-coupling |
| StyleBoxFlat border for highlight | modulate color tint | modulate is simpler but can't draw a border outside the cell background; StyleBoxFlat border is the correct approach for an outline-only highlight |
| serve.py | Itch.io upload + test | Itch upload is valid for final acceptance but adds friction to iteration; serve.py enables instant local testing |

**No new package installations required.** Everything is built into Godot 4.

---

## Architecture Patterns

### Recommended Project Structure
No new files needed for Phase 2. All changes are in-place modifications to `scripts/main.gd` and `scenes/main.tscn`, plus adding theme nodes/resources.

```
res://
├── scenes/
│   └── main.tscn          # Add: WinOverlay subtree, score strip nodes
├── scripts/
│   └── main.gd            # Modify: _set_cell_color, _log, _update_ui,
│                          #   _check_score (add animation),
│                          #   _check_win_or_stalemate (add overlay show)
└── (no new theme/ dir needed — StyleBoxFlat created in code)
```

### Pattern 1: Extended StyleBoxFlat for Rounded Cell Theming

**What:** Replace the bare `_set_cell_color()` with one that also sets corner radius and border. All four button states must be overridden to avoid Godot reverting to default on hover/press/disabled.

**When to use:** Every cell color update — neutral, player-owned, highlight (valid-move border), and spent (dimmed).

```gdscript
# Source: Godot 4 StyleBoxFlat API (docs.godotengine.org/en/stable/classes/class_styleboxflat.html)
func _make_cell_style(bg: Color, border_color: Color = Color.TRANSPARENT,
                      border_px: int = 0) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = bg
    s.set_corner_radius_all(6)   # ~6px for a 50x50 button gives a pleasant rounded tile look
    s.corner_detail = 4          # Sufficient for radius < 10
    if border_px > 0:
        s.set_border_width_all(border_px)
        s.border_color = border_color
        s.draw_center = true     # Keep bg color; border is additive
    s.anti_aliasing = true
    return s

func _set_cell_color(btn: Button, bg: Color, border_color: Color = Color.TRANSPARENT,
                     border_px: int = 0) -> void:
    var s := _make_cell_style(bg, border_color, border_px)
    btn.add_theme_stylebox_override("normal",   s)
    btn.add_theme_stylebox_override("hover",    s)
    btn.add_theme_stylebox_override("pressed",  s)
    btn.add_theme_stylebox_override("disabled", s)
```

**Valid-move highlight:** Call with `border_px = 3` and a gold border, keeping the neutral dark background. This satisfies the "glowing border/outline rather than background fill" decision.

**Spent cell:** Pass a desaturated/alpha-reduced version of the player color. Use `Color(player_color.r, player_color.g, player_color.b, 0.45)` or `player_color.darkened(0.5)`.

### Pattern 2: Tween Scale Pop on Button Nodes

**What:** Scale a Button to 1.2x then back to 1.0x, centered on the cell. Godot 4 Control nodes scale from their `pivot_offset`, which defaults to (0,0) — the top-left corner. Must set `pivot_offset` to half the button's size before tweening.

**Critical pitfall:** `btn.size` may not be valid until after the first layout frame. Read `btn.size` at animation time (inside `_check_score` after layout is complete), not at `_ready()`.

**When to use:** Only after `_check_score()` returns true. Fire-and-forget: score updates immediately, animation runs asynchronously.

```gdscript
# Source: Godot Forum (forum.godotengine.org/t/tween-scale-animation-doesnt-stay-centered)
# and Godot 4 Tween API (docs.godotengine.org/en/stable/classes/class_tween.html)
func _animate_score_cells(cells: Array) -> void:
    for cell_vec in cells:          # cell_vec is Vector2i(col, row) per _collect_line convention
        var btn: Button = cell_buttons[cell_vec.y][cell_vec.x]
        # Center the scale pivot before animating
        btn.pivot_offset = btn.size / 2.0
        var tw := create_tween()
        tw.set_parallel(true)
        # Pop to 1.2x
        tw.tween_property(btn, "scale", Vector2(1.2, 1.2), 0.15)\
          .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        # Return to 1.0x after the pop (sequential, not parallel)
        tw.set_parallel(false)
        tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15)\
          .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
```

**Score update timing:** Award the point and update UI immediately (before or after spawning the tween). The user decision is explicit: "Score updates during the animation (not waiting for animation to complete)." Do NOT `await tw.finished` before scoring.

**Spent appearance after pop:** Apply the dimmed StyleBoxFlat immediately in `_check_score()`, and let the tween play over the already-dimmed button. Alternatively, apply dimming in a `tween_callback` at the start of the return portion — either is acceptable.

### Pattern 3: RichTextLabel BBCode Color-Coded Log

**What:** Enhance `_log()` to accept a player index and wrap entries in `[color=#hex]...[/color]` tags. Score events get additional `[b]...[/b]` emphasis.

**Key limitation:** `[b]` (bold) requires a font that has a bold variant loaded. The default Godot font does not support bold via BBCode alone. Use a different color or `[wave]` or just a larger color instead of bold for score events, unless a custom font is loaded.

**When to use:** All game events — rolls, claims, scores, auto-rerolls, game over.

```gdscript
# Source: Godot 4 BBCode docs (docs.godotengine.org/en/stable/tutorials/ui/bbcode_in_richtextlabel.html)
# and confirmed working pattern from Phase 1 (append_text avoids issue #94630)

# Recommended muted player colors as hex strings for BBCode:
const PLAYER_HEX := ["#E07060", "#6080C8", "#70A870", "#D4A040"]
# Matching Color values for StyleBoxFlat bg_color:
const PLAYER_COLORS := [
    Color(0.878, 0.439, 0.376),   # Coral
    Color(0.376, 0.502, 0.784),   # Slate blue
    Color(0.439, 0.659, 0.439),   # Sage green
    Color(0.831, 0.627, 0.251),   # Amber
]

func _log(message: String, player_idx: int = -1) -> void:
    if player_idx >= 0 and player_idx < player_count:
        game_log.append_text("[color=%s]%s[/color]\n" % [PLAYER_HEX[player_idx], message])
    else:
        game_log.append_text(message + "\n")  # System messages: neutral white

func _log_score(message: String, player_idx: int) -> void:
    # Score events: colored + visually distinct (size tag is safe without custom fonts)
    game_log.append_text("[color=%s][font_size=16]%s[/font_size][/color]\n" % [PLAYER_HEX[player_idx], message])
```

### Pattern 4: Win/Stalemate Overlay

**What:** A full-scene Control node (initially hidden) with `MOUSE_FILTER_STOP` that covers the game, containing a semi-transparent `ColorRect` background and a centered `VBoxContainer` panel with the winner text and scores.

**When to use:** Triggered from `_check_win_or_stalemate()` when `state == GAME_OVER`.

**Scene structure addition to `main.tscn`:**
```
[node name="WinOverlay" type="Control" parent="."]
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 0       # MOUSE_FILTER_STOP — blocks all input to board
visible = false        # Hidden until game over

  [node name="Dimmer" type="ColorRect" parent="WinOverlay"]
  anchor_right = 1.0
  anchor_bottom = 1.0
  color = Color(0, 0, 0, 0.65)   # Semi-transparent dark overlay

  [node name="Panel" type="PanelContainer" parent="WinOverlay"]
  anchor_left = 0.25
  anchor_top = 0.2
  anchor_right = 0.75
  anchor_bottom = 0.8

    [node name="VBox" type="VBoxContainer" parent="WinOverlay/Panel"]
      [node name="TitleLabel" type="Label"]
      [node name="ScoresLabel" type="Label"]
```

**GDScript trigger:**
```gdscript
@onready var win_overlay: Control = $WinOverlay
@onready var win_title_label: Label = $WinOverlay/Panel/VBox/TitleLabel
@onready var win_scores_label: Label = $WinOverlay/Panel/VBox/ScoresLabel

func _show_win_overlay(winner_idx: int) -> void:
    win_title_label.text = "%s Wins!" % players[winner_idx].name
    # Tint the panel border with winner's color via StyleBoxFlat
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color(0.15, 0.15, 0.18)
    panel_style.set_border_width_all(4)
    panel_style.border_color = PLAYER_COLORS[winner_idx]
    panel_style.set_corner_radius_all(10)
    $WinOverlay/Panel.add_theme_stylebox_override("panel", panel_style)
    # Build scores text
    var lines := ""
    for i in player_count:
        lines += "%s: %d pts\n" % [players[i].name, players[i].score]
    win_scores_label.text = lines.strip_edges()
    win_overlay.visible = true

func _show_stalemate_overlay() -> void:
    win_title_label.text = "Game Over!"
    # ... same structure, no winner color tint
    win_overlay.visible = true
```

### Pattern 5: Dark Theme Background and GridContainer Gaps

**What:** Apply a dark background color to the root Control and set GridContainer's `theme_override_constants/h_separation` and `v_separation` for cell gaps.

**In scene file or via code:**
```gdscript
# Root node background — set in _ready() or via theme
func _apply_dark_theme() -> void:
    # Dark background on root Control via add_theme_stylebox_override
    var root_style := StyleBoxFlat.new()
    root_style.bg_color = Color(0.13, 0.13, 0.16)  # Charcoal
    add_theme_stylebox_override("panel", root_style)  # Only works if root is PanelContainer

    # GridContainer gaps (2-3px between cells)
    grid_container.add_theme_constant_override("h_separation", 3)
    grid_container.add_theme_constant_override("v_separation", 3)
```

**Simpler alternative:** Set `CanvasItem.modulate` or use a `ColorRect` behind the HBoxContainer as a background fill. The most Godot-idiomatic way is to change the root Control to `PanelContainer` and override the "panel" stylebox.

### Anti-Patterns to Avoid

- **Rebuilding all 100 cell StyleBoxFlat objects on every `_update_ui()` call**: `_update_ui()` runs every turn. Only recreate styles when a cell's visual state actually changes (in `_set_cell_color`, `_highlight_valid_cells`, `_clear_highlights`, `_check_score`).
- **`await tween.finished` before scoring**: The user decision explicitly states score updates during animation. Awaiting the tween blocks the turn flow.
- **Using `bbcode_text +=` operator**: Causes full text replacement and performance issues. Always use `append_text()`.
- **Forgetting `MOUSE_FILTER_STOP` on the win overlay**: Without it, clicking "through" the overlay to cells underneath is possible.
- **Setting `btn.pivot_offset` at `_ready()`**: Button sizes are not finalized until after the first layout pass. Set pivot_offset immediately before tweening.
- **Using `[b]` BBCode without a custom font**: Default Godot font has no bold variant — `[b]` silently does nothing. Use font size, color, or an icon prefix instead.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Property animation | Custom `_process()` lerp loop | `Tween.tween_property()` | Tween handles delta time, easing curves, parallel/sequential chaining, and auto-cleanup |
| Semi-transparent overlay blocking input | Invisible Button covering screen | `Control` with `MOUSE_FILTER_STOP` + `ColorRect` child | Correct Godot idiom; MOUSE_FILTER_STOP on a Control node consumes all input events in its rect |
| BBCode rich text | Manual Label pool with color modulate | `RichTextLabel` with `append_text()` | Already integrated; supports inline color, size, and any future formatting |
| Cell gap/spacing | Pixel offsets on each button | `GridContainer` `h_separation`/`v_separation` constants | Layout system handles it; no manual math needed |
| Centered scale pivot | Position offset tweens | `btn.pivot_offset = btn.size / 2.0` | One line; no position compensation needed |

---

## Common Pitfalls

### Pitfall 1: Button Size Not Available at _ready()
**What goes wrong:** `btn.size` returns `Vector2(0, 0)` when read during `_ready()` before the layout pass. If `pivot_offset` is set here, the scale pop appears to originate from the top-left corner.
**Why it happens:** Godot's layout system runs after `_ready()`, so sizes are computed on the first frame.
**How to avoid:** Set `btn.pivot_offset = btn.size / 2.0` immediately before starting the tween (inside `_animate_score_cells()`), which runs after layout is complete.
**Warning signs:** Scale pop looks off-center during the animation.

### Pitfall 2: Stale Tween Reference on Repeated Scoring
**What goes wrong:** If a cell is animated and then somehow animated again (edge case), the old tween may be running and fight the new one, leaving `scale != Vector2(1,1)`.
**Why it happens:** Godot 4 Tweens created with `create_tween()` are independent and not automatically cancelled when a new one starts on the same object.
**How to avoid:** Since `scored_grid` prevents re-scoring a spent cell, this shouldn't occur in practice. Defensive option: reset `btn.scale = Vector2.ONE` at the start of `_animate_score_cells()` before creating the tween.
**Warning signs:** Cell button appears visually scaled up after a turn.

### Pitfall 3: HTML5 Export SharedArrayBuffer Error in Browser
**What goes wrong:** The exported HTML5 game shows "Missing features" error in Chrome/Firefox when served from a standard `python -m http.server`.
**Why it happens:** Godot's multi-threaded web export requires `Cross-Origin-Embedder-Policy: require-corp` and `Cross-Origin-Opener-Policy: same-origin` response headers, which standard Python http.server does not send.
**How to avoid:** Use Godot's official `serve.py` (from godotengine/godot repo, `platform/web/serve.py`) or export with threads disabled (single-threaded template). For this game (no audio, no heavy compute), single-threaded export is ideal and removes the header requirement entirely.
**Warning signs:** "SharedArrayBuffer is not defined" or "Couldn't find a feature..." in browser console.

### Pitfall 4: BBCode [b] Bold Tag Has No Effect
**What goes wrong:** Score events wrapped in `[b]...[/b]` look identical to normal text.
**Why it happens:** Godot's default built-in font does not include a bold variant. The BBCode bold tag requires a font resource with a bold face loaded into the RichTextLabel's theme.
**How to avoid:** For Phase 2, use `[font_size=N]...[/font_size]` for emphasis, or rely on player color contrast alone. Bold can be enabled in a future phase if a custom font is added.
**Warning signs:** `[b]` wrapped text looks the same as unwrapped text.

### Pitfall 5: Win Overlay Doesn't Block Board Clicks
**What goes wrong:** After win overlay appears, clicking on board cells still fires `_on_cell_pressed` because the overlay doesn't consume mouse events.
**Why it happens:** A `Control` node with default `MOUSE_FILTER_PASS` passes events to children below it in the scene tree.
**How to avoid:** Set the WinOverlay Control's `mouse_filter` to `MOUSE_FILTER_STOP` (value 0 in the scene file). Additionally, `_disable_all_cells()` already runs on GAME_OVER, so buttons are already disabled — the overlay is belt-and-suspenders.
**Warning signs:** Clicking on the overlay triggers cell press sounds or state changes.

### Pitfall 6: RichTextLabel Horizontal Scrollbar Appears
**What goes wrong:** The game log develops a horizontal scrollbar when a log entry is very long.
**Why it happens:** `RichTextLabel` with `fit_content = true` can cause the parent `ScrollContainer` to show both axes.
**How to avoid:** Set `scroll_horizontal_enabled = false` on the `ScrollContainer` (or the `RichTextLabel`), and ensure long log messages wrap. The `size_flags_horizontal = SIZE_EXPAND_FILL` on the RichTextLabel handles wrapping.
**Warning signs:** Horizontal scrollbar appears in the log panel.

---

## Code Examples

Verified patterns from official sources and existing Phase 1 code:

### Muted Player Color Palette (Claude's Discretion)
```gdscript
# Muted palette that pops on dark backgrounds — hex values for BBCode, Color for StyleBoxFlat
const PLAYER_HEX := ["#E07060", "#6080C8", "#70A870", "#D4A040"]
const PLAYER_COLORS := [
    Color(0.878, 0.439, 0.376),   # Coral       — Player 1
    Color(0.376, 0.502, 0.784),   # Slate blue  — Player 2
    Color(0.439, 0.659, 0.439),   # Sage green  — Player 3
    Color(0.831, 0.627, 0.251),   # Amber       — Player 4
]
const DARK_BG := Color(0.13, 0.13, 0.16)         # Charcoal background
const SIDEBAR_BG := Color(0.17, 0.17, 0.21)      # Slightly lighter sidebar panel
const ACCENT_GOLD := Color(0.90, 0.75, 0.25)     # Roll button accent + highlight border
const NEUTRAL_CELL := Color(0.22, 0.22, 0.27)    # Unclaimed cell background on dark theme
const SPENT_ALPHA := 0.40                         # Opacity for spent/scored cells
```

### Scale Pop Tween (SCOR-03)
```gdscript
# Source: Godot 4 Tween API + pivot_offset centering pattern
# (forum.godotengine.org/t/tween-scale-animation-doesnt-stay-centered)
func _animate_score_cells(cells: Array) -> void:
    for cell_vec in cells:
        var btn: Button = cell_buttons[cell_vec.y][cell_vec.x]
        btn.pivot_offset = btn.size / 2.0          # Must set at animation time, not _ready()
        var tw := create_tween()
        tw.tween_property(btn, "scale", Vector2(1.2, 1.2), 0.15)\
          .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15)\
          .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        # No await — score already updated before this call
```

### Spent Cell Visual (dimmed player color)
```gdscript
# Source: Phase 1 _set_cell_color pattern extended
func _set_cell_spent(row: int, col: int) -> void:
    var player_idx := owner_grid[row][col]
    var base_color := PLAYER_COLORS[player_idx]
    var spent_color := Color(base_color.r, base_color.g, base_color.b, SPENT_ALPHA)
    _set_cell_color(cell_buttons[row][col], spent_color)
```

### Valid-Move Border Highlight
```gdscript
# Source: StyleBoxFlat API — border on top of neutral bg
func _highlight_cell(btn: Button) -> void:
    var s := StyleBoxFlat.new()
    s.bg_color = NEUTRAL_CELL
    s.set_corner_radius_all(6)
    s.corner_detail = 4
    s.set_border_width_all(3)
    s.border_color = ACCENT_GOLD
    s.anti_aliasing = true
    btn.add_theme_stylebox_override("normal",   s)
    btn.add_theme_stylebox_override("hover",    s)
    btn.add_theme_stylebox_override("pressed",  s)
    btn.add_theme_stylebox_override("disabled", s)
```

### BBCode Color-Coded Log Entry
```gdscript
# Source: Godot 4 BBCode docs (docs.godotengine.org/en/stable/tutorials/ui/bbcode_in_richtextlabel.html)
# append_text() confirmed correct (avoids issue #94630, Phase 1 finding)
func _log(message: String, player_idx: int = -1) -> void:
    if player_idx >= 0 and player_idx < player_count:
        game_log.append_text("[color=%s]%s[/color]\n" % [PLAYER_HEX[player_idx], message])
    else:
        game_log.append_text(message + "\n")

# Score events — larger font for visual emphasis (bold requires custom font, avoid)
func _log_score_event(message: String, player_idx: int) -> void:
    game_log.append_text("[color=%s][font_size=16]%s[/font_size][/color]\n" \
        % [PLAYER_HEX[player_idx], message])
```

### HTML5 Export Test — Local Server
```bash
# Download serve.py from Godot repo (one-time setup)
# https://raw.githubusercontent.com/godotengine/godot/master/platform/web/serve.py

# Run from the HTML5 export directory:
python3 serve.py -r /path/to/export/directory
# Game available at http://localhost:8000

# Required headers serve.py adds automatically:
# Cross-Origin-Embedder-Policy: require-corp
# Cross-Origin-Opener-Policy: same-origin
```

**Alternative (simpler for this project):** Export using the single-threaded web template. This game has no threading, no audio streams, and no heavy computation — single-threaded export works perfectly and requires no special server headers. Export preset option: uncheck "Thread Support" in the Web export settings.

### Current Player Badge (UI-01)
```gdscript
# Colored panel badge for current player — Panel node with StyleBoxFlat override
func _update_player_badge() -> void:
    var badge_style := StyleBoxFlat.new()
    badge_style.bg_color = PLAYER_COLORS[current_player]
    badge_style.set_corner_radius_all(8)
    badge_style.corner_detail = 4
    current_player_panel.add_theme_stylebox_override("panel", badge_style)
    current_player_label.text = players[current_player].name
```

### Score Strip (UI-03) — HBoxContainer approach
```gdscript
# Score strip: one Label per player, colored, updated each turn
# Labels created once at _ready() and updated in _update_ui()
func _update_score_strip() -> void:
    for i in player_count:
        score_labels[i].text = "%s: %d" % [players[i].name, players[i].score]
        score_labels[i].add_theme_color_override("font_color", PLAYER_COLORS[i])
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Tween as node in scene tree (Godot 3) | `create_tween()` on any node (Godot 4) | Godot 4.0 | No scene pollution; tween lifetime tied to owning node |
| HTML5 multi-threaded by default | Single-threaded default since Godot 4.3 | Godot 4.3 | Simpler export; no SharedArrayBuffer headers needed with single-thread template |
| RichTextLabel `bbcode_text +=` | `append_text()` | Godot 4.x | Avoids full text replacement performance regression |

**Deprecated/outdated:**
- `Tween` as an `add_child()` node: Old Godot 3 pattern. In Godot 4, use `create_tween()` which creates a managed tween scoped to the node.
- HTML5 "Use Threads" being required: As of Godot 4.3+, single-threaded export is the default and preferred for maximum browser compatibility.

---

## Open Questions

1. **GridContainer cell sizing with gaps on small browser windows**
   - What we know: `custom_minimum_size = Vector2(50, 50)` on each button from Phase 1. At minimum browser window (320px wide), 10 columns × 50px + gaps may overflow.
   - What's unclear: Whether `SIZE_EXPAND_FILL` without minimum size constraint causes cells to shrink below readable size, or whether the sidebar forces minimum width.
   - Recommendation: Test at 800px wide (common minimum). If cells shrink unacceptably, set `grid_container.custom_minimum_size.x` to `cols * 40 + (cols-1)*3` as a floor, and let it scroll horizontally at extreme sizes. Deferred to the UI-05 HTML5 test task.

2. **PanelContainer vs plain Control for dark background**
   - What we know: A `PanelContainer` accepts a "panel" StyleBoxFlat override that fills the background. A plain `Control` does not paint a background by default.
   - What's unclear: The current root node in main.tscn is `Control`, not `PanelContainer`. Changing to PanelContainer is a one-line scene edit but changes how children are laid out (PanelContainer adds its own padding).
   - Recommendation: Convert root node to `PanelContainer` for clean dark background, or add a full-size `ColorRect` as the first child of the HBoxContainer. Either works; the planner should pick one approach.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Godot 4 built-in scene runner (no external test framework in project) |
| Config file | none — validated via Godot editor Play + HTML5 export smoke test |
| Quick run command | Open Godot editor, press F5 (Play Scene) |
| Full suite command | F5 play + HTML5 export + open in browser via serve.py |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SCOR-03 | Scoring cells briefly scale to 1.2x then return | Visual/manual | F5, play to a score event | ✅ main.gd |
| WIN-02 | Win overlay appears with winner name + ranked scores | Visual/manual | F5, reach 5 points | ✅ main.gd |
| UI-01 | Current player name+color badge visible | Visual/manual | F5, observe sidebar | ✅ main.gd |
| UI-02 | Roll result shown in large font | Visual/manual | F5, press Roll | ✅ main.gd |
| UI-03 | All player scores always visible | Visual/manual | F5, observe score strip | ✅ main.gd |
| UI-04 | Game log color-coded by player | Visual/manual | F5, observe log entries | ✅ main.gd |
| UI-05 | Layout works in browser | Smoke test | HTML5 export + serve.py + open in Chrome | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** F5 play, verify the specific requirement changed in that task
- **Per wave merge:** Full visual check of all 7 requirements + HTML5 smoke test
- **Phase gate:** All requirements visually confirmed + HTML5 export loads and plays in browser before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] HTML5 export preset configured in Godot (Web export with threads disabled) — covers UI-05
- [ ] `serve.py` downloaded to project root or a dev tools location for local testing

---

## Sources

### Primary (HIGH confidence)
- Godot 4 Tween class docs (docs.godotengine.org/en/stable/classes/class_tween.html) — tween_property, set_trans, set_ease, create_tween pattern
- Godot 4 StyleBoxFlat class docs (docs.godotengine.org/en/stable/classes/class_styleboxflat.html) — corner_radius, border_width, bg_color, set_corner_radius_all, set_border_width_all
- Godot 4 BBCode in RichTextLabel docs (docs.godotengine.org/en/stable/tutorials/ui/bbcode_in_richtextlabel.html) — [color], [font_size], append_text usage
- Phase 1 RESEARCH.md and STATE.md — confirmed append_text pattern, scored_grid boolean, _set_cell_color pattern, RichTextLabel issue #94630 workaround
- Existing main.gd — confirmed _check_score returns after first line, _collect_line returns Array of Vector2i

### Secondary (MEDIUM confidence)
- Godot forum: tween-scale-animation-doesnt-stay-centered — pivot_offset = btn.size / 2.0 workaround, verified against create_tween docs
- WebSearch: Godot 4.3 single-threaded HTML5 export default — confirmed by multiple sources including godotengine.org article "Web Export in 4.3"
- serve.py from godotengine/godot repo (platform/web/serve.py) — confirmed Cross-Origin-Embedder-Policy and Cross-Origin-Opener-Policy headers

### Tertiary (LOW confidence)
- Exact hex color values for muted palette — recommended values are Claude's discretion per CONTEXT.md; not from any official source
- `[font_size=16]` as bold substitute — derived from known limitation of default Godot font + BBCode docs; not verified with a live test

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all APIs are Godot 4 built-ins used in Phase 1 or well-documented
- Architecture: HIGH — patterns extend directly from Phase 1 established code; no new paradigms
- Animation (Tween): HIGH — tween_property API is stable Godot 4; pivot_offset pattern verified from forum + docs
- HTML5 export: MEDIUM — Godot 4.3 single-thread default confirmed; exact export UI steps need in-editor verification
- Pitfalls: HIGH — pivot_offset issue, [b] BBCode limitation, SharedArrayBuffer headers all have multiple source confirmation

**Research date:** 2026-03-14
**Valid until:** 2026-04-14 (Godot 4 stable APIs; StyleBoxFlat and Tween are mature)
