# Technology Stack

**Project:** Dice Grid Game (Steamroller)
**Researched:** 2026-03-15 (v1.1 Dice Polish addendum appended; original: 2026-03-11)
**Confidence:** MEDIUM — Godot 4 is stable and well-understood. v1.1 animation section verified against Godot 4.4/4.5 docs and community sources as of March 2026.

---

## Recommended Stack

### Core Engine

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Godot 4 | 4.5.1 (current stable as of 2025-09; verify at godotengine.org) | Game engine | Chosen in PROJECT.md. HTML5 export is first-class, GDScript is purpose-built for game logic, no licensing cost, small export footprint. |
| GDScript | Built into Godot 4 | Game logic language | Dynamically typed, Python-like syntax, native to Godot's scene/node model. No compilation step during iteration. |

### UI Framework (built-in)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Control nodes (Godot built-in) | Same as engine | All UI — grid, buttons, labels, panels | The project already commits to this approach. Control nodes render identically on HTML5 and desktop, respond to browser zoom/resize via anchors, and don't depend on any external library. |
| GridContainer | Same as engine | 10x10 cell grid layout | Built-in Control node that tiles children in a grid by column count. Set `columns = 10`, add 100 Button children, done. No manual position math needed. |
| VBoxContainer / HBoxContainer | Same as engine | Score panel, turn display, game log | Standard layout containers — stacking UI regions vertically and horizontally without manual rect management. |
| Button | Same as engine | Individual grid cells and roll button | Each cell is a Button. `disabled = true` to prevent re-claiming; `modulate` or `self_modulate` for player color tinting. |
| RichTextLabel | Same as engine | Game log | Supports BBCode for colored player names in log entries. |
| Theme / StyleBox | Same as engine | Visual polish | Godot 4's Theme resource lets you define button appearances project-wide. StyleBoxFlat gives solid color fills with rounded corners. |

### State Management (built-in pattern)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| GDScript enum + match | Built into GDScript | Game phase state machine | Two states (WAIT_ROLL, WAIT_PICK) plus ANIMATING for v1.1. GDScript's `enum` + `match` is the idiomatic Godot pattern. |

### Randomization (built-in)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| RandomNumberGenerator (Godot built-in) | Same as engine | d6 rolls, initial board population | `RandomNumberGenerator.randi_range(1, 6)`. No external library needed. |

---

## v1.1 Dice Polish: Animation Stack

These additions are specific to the fake-3D tumbling dice animation and centered roll button milestone.

### Animation Nodes

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| AnimatedSprite2D | Godot 4 built-in | Frame-by-frame dice tumble animation | The canonical node for sprite sheet playback. Holds a `SpriteFrames` resource with named animation clips, controls FPS, loop, and emits `animation_finished` signal when a one-shot clip ends. Simplest path from sprite sheet to playing animation. |
| Tween (create_tween()) | Godot 4 built-in | Scale punch, button entrance, die landing bounce | Code-driven property interpolation. Use for the "button grows then shrinks" feedback on press and the brief scale pop when the die lands. Tween instances auto-free when complete; no manual cleanup needed. Compose with AnimatedSprite2D (Tween handles scale/position, AnimatedSprite2D handles frame content). |
| SpriteFrames resource | Godot 4 built-in | Holds all animation clips for the die | Attach to AnimatedSprite2D. Define two clips: "tumble" (looping fast rotation sequence, ~8-12 frames at 18-24 fps) and "face_N" per die face (1-6), each a single frame used to freeze on the result. Can be created and populated from code via `SpriteFrames.new()` + `add_frame()`. |

### UI Embedding Approach

| Approach | Verdict | Notes |
|----------|---------|-------|
| AnimatedSprite2D as direct child of Control | USE THIS — with manual position | AnimatedSprite2D is Node2D-derived, not Control. It does not participate in Container layout and will not auto-size or anchor. However, it can be added as a child of a Control node and positioned manually (set `position` to the Control's `size / 2` to center it). This is the standard pattern for dice/character animations within a UI panel. |
| SubViewport + SubViewportContainer | AVOID for this use case | Adds a full secondary render pass and a separate viewport context. Known scaling bug with CanvasItems project scale mode (issue #77149 — unresolved as of 4.4). Intended for rendering 3D inside 2D or picture-in-picture effects, not for simple sprite-in-UI. Over-engineered for a dice animation. |
| AnimatedTexture on TextureRect | AVOID | Deprecated in Godot 4. The class is marked as inefficient and may be removed in a future version. No replacement is built-in yet. |
| Community AnimatedTextureRect plugin | AVOID for now | Third-party plugin (github.com/Gabnixe/AnimatedTextureRect). Adds a dependency and potential version drift. The manual-position approach with AnimatedSprite2D is simpler and has no external dependency. |

**Recommended embedding pattern:**
```
CenterContainer (Control)
  └── Panel (or MarginContainer) — the roll button area
        ├── Button ("Roll") — visible in WAIT_ROLL state, hidden during animation
        └── AnimatedSprite2D — visible only during animation, hidden otherwise
```
Position AnimatedSprite2D at `panel.size / 2` after `_ready()` or in `_on_resized()`. Use `show()` / `hide()` to swap between Button and sprite.

### Sprite Sheet Format

| Property | Recommendation | Rationale |
|----------|---------------|-----------|
| File format | PNG with transparency | Native Godot import, lossless, alpha channel for non-square die faces |
| Sheet layout | Single horizontal strip OR uniform grid | Godot's SpriteFrames editor auto-slices uniform grids; horizontal strip is simplest for a single animation |
| Frame size | 128×128 px per frame | Large enough to look sharp on desktop and web at typical button sizes (100-200px rendered); small enough to import fast |
| Tumble frame count | 8-12 frames | Sufficient for believable rotation illusion at 18-24 fps. The 2d-dice-in-godot reference project uses 30 fps with spritesheet slices. More frames (>16) add file size with diminishing visual returns for a dice tumble. |
| Face frames | 6 frames (one per die value) | Can be separate images or the last 6 frames in the same sheet. Using the same sheet keeps import count low. |
| Power-of-two sheet size | 256×128 (8 frames of 128×128) or 512×128 (12 frames) | Power-of-two dimensions maximize GPU texture cache compatibility, especially for HTML5/WebGL export |
| Texture filter | Nearest (pixel art) OR Linear (smooth) | If dice faces are drawn crisply (pixel art style), use Nearest. If pre-rendered with smooth shading, Linear. Set per-texture in import settings. |

### Signal / Await Pattern for Animation Completion

AnimatedSprite2D emits `animation_finished` when a non-looping animation ends. Use `await` in GDScript to gate game logic:

```gdscript
# In main.gd — play tumble, then show result
func _do_roll_animation(result: int) -> void:
    _roll_button.hide()
    _dice_sprite.show()
    _dice_sprite.play("tumble")          # looping: true
    await get_tree().create_timer(1.2).timeout   # tumble for ~1.2 seconds
    _dice_sprite.play("face_" + str(result))     # single-frame, non-looping
    # No await needed here — face frame is instant
    _on_roll_animation_complete(result)
```

**Caution:** Godot 4 has a known edge case (issue #84250) where `animation_finished` may not fire reliably for very short animations or when animation is replayed rapidly. Using a `Timer`-based gate (as shown above) is more robust than `await animation_finished` for the tumble phase.

### Export Targets (no changes from v1.0)

| Target | Notes |
|--------|-------|
| HTML5 / Web | AnimatedSprite2D and Tween both work in HTML5 export without any additional configuration. PNG sprite sheets import identically. |
| Desktop (Windows, Linux) | No changes from v1.0 setup. |

---

## What NOT to Use

| Category | Avoid | Why | Use Instead |
|----------|-------|-----|-------------|
| Language | C# / .NET | Adds Mono runtime weight, complicates HTML5 export | GDScript |
| Rendering | Node2D for board grid | Control nodes handle layout automatically | GridContainer + Button |
| Physics | RigidBody2D / 3D dice physics | Out of scope per PROJECT.md | Sprite sheet animation |
| Sprite embedding | SubViewport + SubViewportContainer | Secondary render pass overhead; active scaling bug with UI scale mode | AnimatedSprite2D as direct child, manually positioned |
| Texture animation | AnimatedTexture on TextureRect | Deprecated, may be removed | AnimatedSprite2D |
| Animation node | AnimationPlayer (for this use case) | Heavier setup — requires timeline editing per property. Only needed if animating multiple node properties in sync. For simple frame playback, AnimatedSprite2D is simpler | AnimatedSprite2D + Tween |
| State | LimboAI or FSM plugins | Two/three-state machine doesn't justify a plugin dependency | GDScript enum + match |
| Audio | AudioStreamPlayer | Out of scope for v1 per PROJECT.md | — |

---

## Project Structure (Updated for v1.1)

```
res://
├── project.godot
├── scenes/
│   └── main.tscn              # Single scene (existing pattern)
├── scripts/
│   └── main.gd                # 911 LOC baseline; dice animation adds ~100-150 LOC
└── assets/
    └── dice_sheet.png         # NEW: sprite sheet for tumble + face frames
```

The project uses a single-scene, single-script architecture established in v1.0. The dice animation adds:
- One `AnimatedSprite2D` node to the scene (child of the roll button's parent Container)
- One `SpriteFrames` resource (either inline in the .tscn or loaded from a .tres file)
- One `dice_sheet.png` asset
- ~100-150 additional GDScript lines in `main.gd`

No new scenes, no new autoloads, no new scripts — consistent with the existing minimal architecture.

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Animation approach | AnimatedSprite2D + Tween | AnimationPlayer | AnimationPlayer is better when you need synchronized multi-property timelines. For frame playback + simple scale punch, AnimatedSprite2D + Tween requires less editor setup and fewer lines of code. |
| UI embedding | Direct child with manual position | SubViewport | SubViewport adds render overhead and has an active scaling bug (issue #77149). Not justified for a single dice sprite. |
| Tumble timing gate | create_timer().timeout | await animation_finished | Known signal reliability issue in Godot 4 (issue #84250). Timer is deterministic. |
| Sprite sheet | Pre-rendered PNG frames | Procedural shader | Shader would produce no asset files but requires GLSL authoring knowledge. Pre-rendered frames are simpler, more portable, and easier to iterate on. |

---

## Version Compatibility

| Component | Compatible With | Notes |
|-----------|-----------------|-------|
| AnimatedSprite2D | Godot 4.0+ | API stable across 4.x. `play()`, `stop()`, `animation_finished` signal unchanged. |
| Tween (create_tween()) | Godot 4.0+ | Godot 4 Tween API was redesigned from Godot 3; the 4.x API is stable. |
| SpriteFrames | Godot 4.0+ | Resource format stable across 4.x. |
| HTML5 export + AnimatedSprite2D | Godot 4.4+ (verified) | Works without additional configuration. PNG sprite sheets supported in WebGL export. |

---

## Sources

- [AnimatedSprite2D — Godot 4.4 docs](https://docs.godotengine.org/en/4.4/classes/class_animatedsprite2d.html) — class API, SpriteFrames, signals (HIGH confidence)
- [2D sprite animation — Godot stable docs](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html) — spritesheet setup, animation workflow (HIGH confidence)
- [SubViewportContainer — Godot 4.4 docs](https://docs.godotengine.org/en/4.4/classes/class_subviewportcontainer.html) — confirmed overhead and scope (HIGH confidence)
- [Godot issue #77149](https://github.com/godotengine/godot/issues/77149) — SubViewportContainer scaling bug with CanvasItems mode (HIGH confidence — open issue)
- [Godot issue #84250](https://github.com/godotengine/godot/issues/84250) — animation_finished reliability edge case (HIGH confidence — documented issue)
- [Possible to use AnimatedSprite2D in Control Node? — Godot Forum](https://forum.godotengine.org/t/possible-to-use-animatedsprite2d-in-control-node/96054) — community patterns for embedding (MEDIUM confidence)
- [AnimatedTextureRect — GitHub (community plugin)](https://github.com/Gabnixe/AnimatedTextureRect) — why avoided (MEDIUM confidence)
- [2d-dice-in-godot — Codeberg](https://codeberg.org/sosasees/2d-dice-in-godot) — reference implementation for spritesheet dice at 30fps (MEDIUM confidence)
- [Godot 4.5 release notes — Godot Engine itch.io](https://godotengine.itch.io/godot/devlog/1088820/maintenance-release-godot-451) — version verification (HIGH confidence)
- [AnimationSprite2D in Control node — Godot Forum](https://forum.godotengine.org/t/animationsprite2d-in-control-node/111601) — HBoxContainer scaling behavior (MEDIUM confidence)
- [Godot Engine Wikipedia](https://en.wikipedia.org/wiki/Godot_(game_engine)) — 4.4 release date March 2025, 4.5 release September 2025 (MEDIUM confidence)

---

*Stack research for: Steamroller — Godot 4 turn-based dice board game*
*Original research: 2026-03-11 | v1.1 Dice Polish addendum: 2026-03-15*
