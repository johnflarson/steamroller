# Architecture Research

**Domain:** Fake-3D dice animation integration — Godot 4 Control-node UI game (v1.1)
**Researched:** 2026-03-15
**Confidence:** HIGH for integration patterns; MEDIUM for spritesheet animation technique specifics (verified against Godot 4 docs and community; AnimatedSprite2D-in-Control is a known friction point with established workarounds)

---

## Context: What Exists

The game is a shipped 911-LOC single-file GDScript application (`scripts/main.gd`) attached to a `PanelContainer` root. The scene tree is all Control nodes. The roll button lives at `$HBoxContainer/Sidebar/SidebarContent/RollButton` — inside a `VBoxContainer` sidebar that also holds the player badge, roll result label, and game log.

The state machine (`WAIT_ROLL → WAIT_PICK → GAME_OVER`) is the gating mechanism. The roll button is enabled only during `WAIT_ROLL`. `_on_roll_button_pressed()` is the single entry point that triggers the roll.

---

## The Core Integration Problem

AnimatedSprite2D is a Node2D. Control nodes (Button, VBoxContainer, etc.) and Node2D nodes use entirely different coordinate and layout systems. A Node2D child inside a Control container does not participate in layout flow — it won't center itself, won't expand/shrink with its parent, and won't receive layout-driven repositioning.

**This rules out placing AnimatedSprite2D as a child of the sidebar VBoxContainer and expecting it to "sit where the button is."**

Two viable patterns exist. One is correct for this project; the other trades simplicity for fragility.

---

## Recommended Architecture: Overlay AnimatedSprite2D on CanvasLayer

### System Overview

```
Main (PanelContainer — root, script-attached)
├── HBoxContainer
│   ├── BoardPanel (VBoxContainer)
│   │   ├── GridContainer          (100 cell buttons)
│   │   └── ScoreStrip
│   └── Sidebar (PanelContainer)
│       └── SidebarContent (VBoxContainer)
│           ├── CurrentPlayerBadge
│           ├── RollResultLabel     ← REMOVE or repurpose
│           ├── RollButton          ← HIDE during animation, SHOW otherwise
│           ├── DiceAnimationAnchor ← NEW: Control, 0×0, invisible layout anchor
│           ├── LogScroll
│           └── RestartButton
├── WinOverlay
├── SetupOverlay
└── DiceLayer (CanvasLayer, layer=10)    ← NEW
    └── DiceSprite (AnimatedSprite2D)    ← NEW
```

The `DiceLayer` sits at the root level alongside `HBoxContainer`, `WinOverlay`, and `SetupOverlay`. As a `CanvasLayer`, it renders above all Control nodes regardless of scene tree position. The `AnimatedSprite2D` inside it uses Node2D screen coordinates.

### How Positioning Works at Runtime

`DiceAnimationAnchor` is a zero-size Control node placed in the VBoxContainer immediately after `RollButton`. At animation time, `main.gd` reads the anchor's screen position:

```gdscript
var anchor_pos: Vector2 = dice_animation_anchor.get_global_rect().get_center()
dice_sprite.global_position = anchor_pos
```

This converts from Control layout coordinates to Node2D global coordinates in one call. `get_global_rect()` on a Control returns screen-space coordinates directly, which is what Node2D `global_position` expects. No manual offset math needed.

---

## Component Responsibilities

| Component | Type | New / Modified | Responsibility |
|-----------|------|----------------|----------------|
| `RollButton` | Button (Control) | Modified | Hidden during animation; re-shown when animation completes. No logic change — still emits `pressed`. |
| `DiceAnimationAnchor` | Control | New | Zero-size invisible spacer. Provides a stable layout-relative position for the CanvasLayer sprite to snap to. Placed where the dice should appear. |
| `DiceLayer` | CanvasLayer | New | Renders above all UI. Owns DiceSprite. |
| `DiceSprite` | AnimatedSprite2D | New | Plays tumble animation, then lands on the rolled face. Emits `animation_finished`. |
| `main.gd` | Script | Modified | Coordinates hide/show of button, triggers animation, awaits `animation_finished` before transitioning to WAIT_PICK. |

---

## Scene Tree Changes

### Add to `scenes/main.tscn`

```
# After SetupOverlay at root level:
[node name="DiceLayer" type="CanvasLayer" parent="."]
layer = 10

[node name="DiceSprite" type="AnimatedSprite2D" parent="DiceLayer"]
visible = false
centered = true
```

### Add inside SidebarContent VBoxContainer

```
# After RollButton, before LogScroll:
[node name="DiceAnimationAnchor" type="Control" parent="HBoxContainer/Sidebar/SidebarContent"]
custom_minimum_size = Vector2(0, 80)
visible = true
```

The anchor has a `custom_minimum_size` height matching the dice sprite display height. This reserves layout space during animation so the sidebar does not reflow when the button hides. Width is 0 — it fills horizontal space from `SIZE_EXPAND_FILL` on the parent.

---

## Data Flow: Button-to-Dice Transformation

### Roll Press Flow (Modified)

```
Player presses RollButton
  → _on_roll_button_pressed() fires
      → guard: if state != WAIT_ROLL → return
      → current_roll = randi_range(1, 6)    ← roll happens immediately
      → state = WAIT_PICK                   ← state transitions immediately
      → _start_dice_animation(current_roll) ← visual only, non-blocking fire-and-forget
      → _highlight_valid_cells()            ← happens immediately
      → _log(...)
      → _update_ui()                        ← disables roll button (already hidden)

func _start_dice_animation(face: int) -> void:
    roll_button.visible = false
    dice_animation_anchor.visible = true
    var anchor_pos := dice_animation_anchor.get_global_rect().get_center()
    dice_sprite.global_position = anchor_pos
    dice_sprite.visible = true
    dice_sprite.play("tumble")
    # Connect one-shot to land on the correct face
    dice_sprite.animation_finished.connect(
        func(): _on_dice_tumble_finished(face), CONNECT_ONE_SHOT)

func _on_dice_tumble_finished(face: int) -> void:
    dice_sprite.play("face_%d" % face)   # single-frame "result" animation
    # OR: dice_sprite.frame = face - 1 if using one SpriteFrames resource
```

### Roll Button Restoration (on turn advance)

```
_advance_turn() → _update_ui() → _show_roll_button()

func _show_roll_button() -> void:
    dice_sprite.visible = false
    dice_sprite.stop()
    roll_button.visible = true
```

**Key design decision:** The roll value is computed and state transitions happen synchronously on button press. The animation is purely cosmetic and does not block state. This avoids `await`-based state machine complexity and prevents input handling races during animation playback.

---

## Spritesheet Strategy

### Animation Structure

Two named animations in a single `SpriteFrames` resource:

| Animation name | Frames | Description |
|----------------|--------|-------------|
| `tumble` | 16–24 frames | Fake-3D tumbling sequence, loops during roll, plays once |
| `face_1` … `face_6` | 1 frame each | Static "landed" pose showing the result face |

Alternatively: one `tumble` animation plus separate atlas regions. Separate named animations is simpler to author and call from code.

### SpriteFrames Resource

Store as `res://theme/dice_frames.tres` (or embedded in the scene node). Reference from `DiceSprite.sprite_frames`. This keeps the spritesheet alongside other visual assets in `theme/`.

### Sprite Art

Pre-render a 3D die rotating through ~270 degrees across 16-24 frames. The last frame of `tumble` should not be a clean face (avoid accidental spoiler of the result). Each `face_N` is a clean top-down render of the die showing face N. All frames can live in a single PNG atlas.

### Sizing

Set `DiceSprite.scale` to match the button dimensions. The button's `custom_minimum_size` is `Vector2(0, 0)` currently (auto-sized by VBoxContainer), but visually it fills ~280px wide × ~48–60px tall. The dice display area should be roughly square — set `DiceAnimationAnchor.custom_minimum_size = Vector2(0, 80)` and scale `DiceSprite` to 80×80px. This is larger than the current button, which is intentional — the dice is the prominent focal point.

---

## Architectural Patterns

### Pattern 1: CanvasLayer for Node2D over Control UI

**What:** Place AnimatedSprite2D inside a CanvasLayer at the scene root. Use a zero-size Control anchor in the UI tree to provide layout-relative position. Read anchor's `get_global_rect()` at animation time to position the Node2D.

**When to use:** Any time a Node2D effect (sprite, particles, shader) needs to appear "inside" a Control-based UI layout without breaking layout flow.

**Why this over SubViewportContainer:** SubViewportContainer works but adds a render texture, a separate viewport update cycle, and complicates input handling. For a simple sprite overlay that doesn't need to respond to layout in real time, CanvasLayer + anchor is cheaper and simpler.

**Example:**
```gdscript
# In _start_dice_animation():
var screen_center: Vector2 = dice_animation_anchor.get_global_rect().get_center()
dice_sprite.global_position = screen_center
dice_sprite.visible = true
dice_sprite.play("tumble")
```

### Pattern 2: Fire-and-Forget Animation (Non-blocking State)

**What:** State transitions and game logic execute synchronously on button press. Animation runs in parallel without blocking the state machine via `await`.

**When to use:** When the animation is cosmetic — the game result is already determined. Use `await` only if the player needs to see the result before interacting (which is not the case here since cells are highlighted simultaneously).

**Trade-off:** Cells become highlightable while dice is still tumbling. This is acceptable — it reinforces that the roll is resolved, and a player fast enough to click before the animation ends gets a valid click.

**Example:**
```gdscript
func _on_roll_button_pressed() -> void:
    if state != GameState.WAIT_ROLL:
        return
    current_roll = randi_range(1, dice_faces)
    state = GameState.WAIT_PICK
    _start_dice_animation(current_roll)   # fire and forget
    _highlight_valid_cells()              # board responds immediately
    _log(...)
    _update_ui()
```

### Pattern 3: Layout Anchor for Stable Positioning

**What:** A zero- or fixed-size Control node (`DiceAnimationAnchor`) sits in the VBoxContainer where the dice should appear. Its presence preserves layout space during the hide/show transition of the button.

**When to use:** Whenever hiding a Control node would cause the container to reflow and shift other UI elements.

**Trade-off:** Adds one extra scene node. Negligible.

---

## Integration Points

### Nodes Modified

| Node | Path | Change |
|------|------|--------|
| `RollButton` | `$HBoxContainer/Sidebar/SidebarContent/RollButton` | Add `visible = false` / `visible = true` calls around animation |
| `_on_roll_button_pressed()` | `scripts/main.gd` | Call `_start_dice_animation()`, no other logic changes |
| `_advance_turn()` → `_update_ui()` | `scripts/main.gd` | Add `_show_roll_button()` call |
| `_on_new_game_pressed()` | `scripts/main.gd` | Ensure dice sprite is hidden / stopped on game reset |

### Nodes Added

| Node | Parent | Type |
|------|--------|------|
| `DiceAnimationAnchor` | `HBoxContainer/Sidebar/SidebarContent` | Control |
| `DiceLayer` | `.` (root) | CanvasLayer |
| `DiceSprite` | `DiceLayer` | AnimatedSprite2D |

### New @onready vars in main.gd

```gdscript
@onready var dice_animation_anchor: Control = $HBoxContainer/Sidebar/SidebarContent/DiceAnimationAnchor
@onready var dice_layer: CanvasLayer = $DiceLayer
@onready var dice_sprite: AnimatedSprite2D = $DiceLayer/DiceSprite
```

### New helper functions in main.gd

```gdscript
func _start_dice_animation(face: int) -> void
func _on_dice_tumble_finished(face: int) -> void
func _show_roll_button() -> void
```

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: AnimatedSprite2D as Child of VBoxContainer

**What:** Adding `AnimatedSprite2D` directly inside the sidebar `VBoxContainer` expecting it to participate in layout.

**Why bad:** Node2D does not implement the Control interface. It will not expand/shrink, will not center, and will draw at world position (0,0) unless manually positioned. It will also not respect the container's padding or alignment.

**Instead:** Use CanvasLayer + anchor pattern described above.

### Anti-Pattern 2: Awaiting Animation Before State Transition

**What:** `await dice_sprite.animation_finished` before setting `state = WAIT_PICK` or calling `_highlight_valid_cells()`.

**Why bad:** Creates a window where the game state is `WAIT_ROLL` but the button is hidden. If any other code path triggers `_update_ui()` during this window (e.g., auto-reroll logic), it will try to re-enable a hidden button. Also adds complexity to the state machine for a purely cosmetic delay.

**Instead:** Transition state immediately. Let the animation play concurrently. The visual and the logic are decoupled.

### Anti-Pattern 3: Storing roll_result in the dice animation

**What:** Having `_on_dice_tumble_finished()` read the roll result from a signal payload or sprite frame index to drive game logic.

**Why bad:** The roll result is already in `current_roll`. Animation callbacks should not be the source of truth for game state.

**Instead:** Pass `face` as a parameter to `_start_dice_animation(face)` for the cosmetic landing frame. Game state reads `current_roll` directly.

### Anti-Pattern 4: Using AnimatedTexture on TextureRect

**What:** Setting `TextureRect.texture` to an `AnimatedTexture` resource to keep everything in the Control tree.

**Why bad:** `AnimatedTexture` is deprecated in Godot 4 and the implementation is inefficient. It does not support SpriteFrames-style named animations. This approach trades one problem (Node2D in Control tree) for a worse one (deprecated API with no animation control).

**Instead:** AnimatedSprite2D on CanvasLayer.

---

## Suggested Build Order

Dependencies determine order. All new work integrates into the existing single-file architecture.

```
Step 1: Art assets — spritesheet PNG
  - No code dependencies
  - Deliverable: dice_spritesheet.png in res://theme/ with tumble frames + 6 face frames
  - Validation: visually review frames in an image viewer before importing

Step 2: SpriteFrames resource
  - Depends on: Step 1
  - Deliverable: dice_frames.tres (or in-editor SpriteFrames) with "tumble" and "face_1"–"face_6" animations
  - Validation: Preview all animations play correctly in Godot editor AnimatedSprite2D preview

Step 3: DiceLayer + DiceSprite scene nodes
  - Depends on: Step 2
  - Deliverable: CanvasLayer + AnimatedSprite2D added to main.tscn, sprite_frames assigned, visible=false
  - Validation: In editor, temporarily set visible=true and press Play — sprite appears, no layout disruption

Step 4: DiceAnimationAnchor Control node
  - Depends on: Nothing (pure scene node)
  - Deliverable: Control node added to SidebarContent VBoxContainer after RollButton
  - Validation: Run game — sidebar layout identical to v1.0 (anchor is invisible, zero-width)

Step 5: _start_dice_animation() + positioning logic
  - Depends on: Steps 3, 4
  - Deliverable: Animation triggers, sprite snaps to anchor position, tumble plays
  - Validation: Press Roll — dice appears over anchor position, tumbles, lands on rolled face

Step 6: Button hide/show wiring
  - Depends on: Step 5
  - Deliverable: RollButton hides on press, re-appears on _advance_turn()
  - Validation: Full turn cycle — button disappears, dice plays, button returns for next player's turn

Step 7: Edge case hardening
  - Depends on: Step 6
  - Covers: New Game resets sprite state, auto-reroll hides button correctly, win overlay hides sprite
  - Validation: Play through to win condition, trigger auto-reroll scenario
```

---

## Scalability Considerations

This is a local single-session game. Animation scalability is not a concern. The only relevant "scale" question is HTML5 performance.

| Concern | Assessment |
|---------|------------|
| HTML5 export | CanvasLayer + AnimatedSprite2D is standard Godot and exports cleanly to HTML5. No known issues. |
| Frame count | 16-24 frames at ~80×80px is negligible texture memory even in WebGL. |
| Layout stability | The anchor node ensures no layout reflow during animation, preventing any flicker on resize. |

---

## Sources

- Godot 4 official docs — AnimatedSprite2D class (HIGH confidence, standard API)
- Godot 4 official docs — CanvasLayer class (HIGH confidence, standard API)
- Godot forum: "Possible to use AnimatedSprite2D in Control Node?" — confirms Node2D does not participate in Control layout (MEDIUM confidence — community verification of known engine behavior)
- Godot forum: "What's the CORRECT way of having a sprite I can animate on the GUI layer?" — CanvasLayer is the community consensus answer (MEDIUM confidence)
- Godot proposals #1754, #1999 — AnimatedTextureRect proposals confirm no native animated Control exists and AnimatedTexture is deprecated (MEDIUM confidence — official issue tracker)
- codeberg.org/sosasees/2d-dice-in-godot — practical 2D dice implementation in Godot confirming AnimatedSprite2D + SpriteFrames approach (LOW confidence — single community project, used only for validation)
- Existing `scripts/main.gd` and `scenes/main.tscn` — primary source for integration constraints (HIGH confidence — direct code inspection)

---

*Architecture research for: Steamroller v1.1 — Dice Animation Integration*
*Researched: 2026-03-15*
