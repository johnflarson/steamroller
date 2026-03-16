# Project Research Summary

**Project:** Steamroller v1.1 — Dice Polish Milestone
**Domain:** Fake-3D dice animation integration in a Godot 4 Control-node UI game
**Researched:** 2026-03-15
**Confidence:** MEDIUM — Godot 4 APIs verified against official docs; animation-in-Control patterns validated through community consensus and confirmed engine behavior

## Executive Summary

Steamroller v1.1 adds a visually polished dice roll experience to an already-shipped v1.0 game: a large centered roll button that transforms into a tumbling fake-3D dice animation before revealing the result. The core technical challenge is that Godot 4's best animation node (`AnimatedSprite2D`) is a `Node2D` subclass, not a `Control`, and the existing game uses an all-Control-node architecture. This mismatch has a well-established solution: place `AnimatedSprite2D` inside a `CanvasLayer` at the scene root and use a zero-size `Control` anchor node to bridge the two coordinate systems. This preserves the project's Control-only layout contract while enabling sprite sheet animation.

The recommended implementation path is `AnimatedSprite2D` + `CanvasLayer` + layout anchor. FEATURES.md and PITFALLS.md suggest an alternative (staying fully in the Control hierarchy using `AnimationPlayer` + `TextureRect`), but ARCHITECTURE.md establishes that the CanvasLayer approach is simpler: one coordinate bridge call (`get_global_rect().get_center()`), standard Godot APIs with no deprecated components, and clean separation between animation rendering and layout. Both paths are valid; the CanvasLayer path requires less scene setup and is the recommendation here — but the team should make a deliberate choice at Phase 1 start before any animation code is written.

The critical risk is the intersection of animation state and game state. The existing two-state machine (`WAIT_ROLL`/`WAIT_PICK`) must gain an `ANIMATING` state before any animation code is written. Without it, fast input during animation creates race conditions that are difficult to reproduce and expensive to fix. All six critical pitfalls identified in research share a single prevention strategy: make architecture decisions — and asset import settings — correct on day one, before any animation logic is implemented. Every pitfall that requires a rewrite is preventable at Phase 1; every pitfall that requires only a 15-minute fix can be safely left to Phase 2 testing.

## Key Findings

### Recommended Stack

The project is already committed to Godot 4 (4.5.1) with GDScript. The v1.1 animation work adds three new engine components — all built-in, no external dependencies. `AnimatedSprite2D` handles frame-by-frame playback via a `SpriteFrames` resource; `Tween` (via `create_tween()`) handles the scale punch and button tactile feedback; `CanvasLayer` provides a rendering layer above the Control UI. One new asset file is required: a PNG sprite sheet with tumble frames and six die face frames.

**Core technologies:**
- `AnimatedSprite2D` (Godot 4.0+): frame-by-frame dice tumble and face display — simplest path from sprite sheet to named animation clips; API stable across all 4.x versions
- `Tween` via `create_tween()` (Godot 4.0+): scale punch on button press and landing bounce — pure GDScript, no scene setup, auto-frees when complete
- `CanvasLayer` (Godot built-in): render layer above Control UI — allows `AnimatedSprite2D` to appear visually inside the sidebar without breaking the Control layout contract
- `SpriteFrames` resource (Godot built-in): named animation clips ("tumble" loop + "face_1" through "face_6" non-loop) — attaches to `AnimatedSprite2D`, previewable in editor before implementation
- PNG sprite sheet (128x128px per frame, power-of-two sheet, lossless import): sole new asset — keep under 512x512 total; import as Lossless (NOT VRAM Compressed)

**What NOT to use:** C# (Mono weight), `AnimatedTexture` on `TextureRect` (deprecated in Godot 4), `SubViewportContainer` (active scaling bug #77149, input passthrough issues on HTML5), `AnimationPlayer` for frame playback (heavier timeline setup than `AnimatedSprite2D` for this use case).

See full detail: `.planning/research/STACK.md`

### Expected Features

The milestone upgrades the roll experience from functional to visceral. The existing `_on_roll_button_pressed()` gains an animation layer; all other game logic (state machine, line detection, scoring) is unchanged.

**Must have (table stakes) — P1:**
- Large centered roll button as primary call-to-action — currently sidebar/small; must be unmissable by size, position, and contrast
- Tumbling dice animation (0.8–1.2s) before revealing result — absence reads as unfinished
- Final animation frame matches `current_roll` — deterministic, cosmetic only; RNG resolves before animation starts
- Button disabled during animation — prevents state corruption on double-press
- Auto-reroll plays ONE animation only — suppress per-reroll animations, animate only the final resolved value
- Squash-stretch on button press (~5 GDScript lines via Tween) — immediate tactile feedback at zero asset cost

**Should have (differentiators) — P2:**
- Color pulse on button (active player color) before animation — low effort, reinforces whose turn it is at the moment of action
- Highlight transition from dice result to valid board cells — draws eye from roll result to action zone

**Defer to v2+:**
- Per-player dice skin customization — requires asset pipeline; no benefit until retention is validated
- Animation speed preference toggle — only if duration becomes a complaint with real players
- Sprite sheet with Blender pre-rendered frames — only if Tween-based rotation feels unconvincing after playtesting

**Critical dependency:** `current_roll` must be resolved by `randi_range()` immediately on button press, before animation starts. Auto-reroll conflict: the existing synchronous reroll loop must run silently to resolution; only the final resolved value triggers the animation.

See full detail: `.planning/research/FEATURES.md`

### Architecture Approach

The architecture solution is a CanvasLayer bridge pattern. `DiceLayer` (a `CanvasLayer` at scene root, `layer=10`) owns `DiceSprite` (`AnimatedSprite2D`, `visible=false` by default). `DiceAnimationAnchor` (a zero-width `Control` node, `custom_minimum_size = Vector2(0, 80)`) sits inside the sidebar `VBoxContainer` after `RollButton`. At animation time, `main.gd` reads `dice_animation_anchor.get_global_rect().get_center()` to convert from Control layout coordinates to Node2D global coordinates in one call, then assigns that to `dice_sprite.global_position`. No manual offset math needed.

**Key design decision:** Animation is fire-and-forget — state transitions (`WAIT_ROLL → WAIT_PICK`) and game logic (`_highlight_valid_cells()`) execute synchronously on button press. Animation runs concurrently without blocking via `await`. This prevents `await`-based race conditions and keeps the state machine as the single source of truth.

**Major components (all changes to existing `main.gd` and `main.tscn`):**
1. `DiceAnimationAnchor` (Control, new) — zero-size layout spacer that reserves sidebar space and provides position reference for the CanvasLayer sprite; prevents layout reflow when `RollButton` hides
2. `DiceLayer` + `DiceSprite` (CanvasLayer + AnimatedSprite2D, new) — renders above all UI; plays "tumble" (loop) then "face_N" (non-loop) clips
3. `main.gd` modifications — new `ANIMATING` state in enum; `_start_dice_animation(face)`, `_on_dice_tumble_finished(face)`, `_show_roll_button()` helper functions; `RollButton` hide/show wiring

**Build order:** art assets → SpriteFrames resource → DiceLayer/DiceSprite scene nodes → DiceAnimationAnchor → animation logic → button hide/show wiring → edge case hardening

See full detail: `.planning/research/ARCHITECTURE.md`

### Critical Pitfalls

All six critical pitfalls share a meta-pattern: the wrong decision is easy to make early and expensive to fix late. Architecture and import choices must be locked before implementation begins.

1. **`AnimatedSprite2D` as child of Control node** — appears centered in the Godot editor, drifts off-center at all other resolutions in HTML5 export. Use CanvasLayer + anchor pattern. Recovery cost if discovered post-implementation: HIGH (rebuild dice display node, re-wire all animation code). Prevention phase: Phase 1.

2. **VRAM texture compression breaks sprites in HTML5 export** — sprites render as solid black rectangles in the browser with no JS console error. Confirmed Godot bug #95721. Set spritesheet import to `Lossless` (compress/mode = 0), NOT `VRAM Compressed` (mode = 3), on first import before any HTML5 test. Recovery cost: LOW (15 minutes) — but breaks every HTML5 test until fixed.

3. **Looping animation never emits `animation_finished`** — `animation_finished` fires only for non-looping animations that reach their final frame. A continuously looping tumble clip has no final frame. Split into two clips: `"tumble"` (loop=true) for anticipation, `"face_N"` (loop=false) for landing. Wire state machine signal to landing clip only. Recovery cost: LOW (5 minutes). Prevention phase: Phase 1 (clip naming).

4. **`await animation_finished` race condition on fast input** — GDScript coroutine suspension during `await` allows other signals to mutate game state while animation is playing. Cells can be claimed before the die lands. Add `ANIMATING` as a new state enum value; disable all cell buttons and roll button in that state; do not rely on `await` for state gating. The v1.0 state machine extends naturally. Recovery cost: MEDIUM. Prevention phase: Phase 1 (first code change).

5. **Layout reflow flash on `hide()`/`show()` transition** — calling `button.hide()` removes the node from layout flow, causing container reflow and a one-frame UI shift visible on HTML5 at reduced framerates. Use `modulate.a = 0.0` to keep nodes in layout flow while invisible, or rely on `DiceAnimationAnchor` to preserve sidebar dimensions so the button hide does not reflow other elements. Recovery cost: LOW. Prevention phase: Phase 2 (test on HTML5 immediately after building transition).

6. **`@onready` type inference (`:=`) breaks HTML5 export** — v1.0 validated lesson: all new `@onready` vars must use explicit type annotations (`var _dice: AnimatedSprite2D`, not `var _dice := $DiceLayer/DiceSprite`). The `:=` inference pattern breaks the HTML5 export. This is project-specific and already known; apply to every new node reference.

See full detail: `.planning/research/PITFALLS.md`

## Implications for Roadmap

The v1.1 work is a contained integration into an existing shipped game. The dependency chain is linear: assets before SpriteFrames resource, nodes before animation logic, state machine extended before button wiring, core transition before edge case hardening. Two parallel tracks exist at the start (art assets creation vs. state machine code changes) but all animation logic waits for both.

### Phase 1: Foundation — Architecture Decisions, Assets, State Machine

**Rationale:** All six critical pitfalls are preventable only at Phase 1. Three architecture decisions are irreversible once animation code is written: the animation node type (CanvasLayer vs. TextureRect approach), the animation clip structure (tumble + land split vs. unified), and the state machine extension (`ANIMATING` state). Asset import settings (VRAM compression) must be correct on first import. This phase produces nothing the player sees, but it eliminates all expensive rewrites.

**Delivers:**
- `ANIMATING` state added to game state enum; all match arms populated (cells and roll button blocked in this state)
- `dice_spritesheet.png` imported with Lossless compression confirmed in `.import` file (compress/mode = 0)
- `SpriteFrames` resource with `"tumble"` (loop=true) and `"face_1"` through `"face_6"` (loop=false) clips verified playing correctly in Godot editor
- `DiceLayer` (CanvasLayer, layer=10) + `DiceSprite` (AnimatedSprite2D, visible=false) added to `main.tscn`
- `DiceAnimationAnchor` (Control, custom_minimum_size = Vector2(0, 80)) added to sidebar VBoxContainer after RollButton

**Addresses:** Foundation for large centered roll button (layout prep), button-disabled-during-animation (ANIMATING state), VRAM bug, looping signal failure, await race condition

**Avoids pitfalls:** 1 (Node2D in Control), 2 (VRAM compression), 3 (looping signal), 4 (await race condition) — all require Phase 1 decisions

### Phase 2: Animation Logic and Button Transformation

**Rationale:** With nodes, assets, state machine, and import settings correct, implement the visible user-facing change: the animation trigger and button-to-dice transformation. The layout reflow pitfall (Pitfall 5) manifests here — test on actual HTML5 export immediately after building the transition, not at the end of the milestone.

**Delivers:**
- `_start_dice_animation(face: int)`: positions DiceSprite via anchor coordinate bridge, plays "tumble", connects one-shot `animation_finished` handler to land on correct face
- `_show_roll_button()`: hides DiceSprite, restores RollButton visibility on turn advance
- RollButton wiring: hides on press, re-shows via `_advance_turn() → _update_ui()`
- Button-to-dice transition tested on HTML5 export at 1280x720 and 1920x1080 (no reflow flash)
- All 6 die faces manually triggered and verified correct in HTML5 export

**Addresses:** Tumbling dice animation (P1), animation terminates on correct face (P1), button-to-dice transformation, button disabled during animation

**Avoids pitfalls:** 5 (layout reflow flash) — test `modulate.a` vs `hide()` on HTML5 immediately after building transition

### Phase 3: Polish and Edge Case Hardening

**Rationale:** P1 features are verified. P2 polish (squash-stretch, color pulse) and edge cases (new game reset, win during animation, auto-reroll single-animation) complete the milestone. These are low-risk additions on a stable base, but each must be verified on HTML5 export before the milestone closes.

**Delivers:**
- Squash-stretch Tween on button press (~5 lines, no assets)
- Auto-reroll confirmed: single animation for final resolved value; intermediate rerolls run silently
- New game reset: dice sprite hidden and stopped on `_on_new_game_pressed()`
- Win condition during animation: win overlay appears correctly; no orphaned animation coroutines
- Full "Looks Done But Isn't" checklist from PITFALLS.md verified (all 8 items)

**Addresses:** Squash-stretch (P1), auto-reroll single animation (P1), game lifecycle edge cases

### Phase Ordering Rationale

- Architecture before implementation: the CanvasLayer vs. TextureRect decision and the `ANIMATING` state addition cannot be retrofitted cleanly once animation code references specific node types and state names
- Import settings before first HTML5 test: VRAM compression produces misleading black-texture failures that obscure other bugs; setting it correctly on first import eliminates a false failure mode
- `ANIMATING` state before button wiring: wiring button signals before the state exists creates race conditions that require controlled reproduction to diagnose
- HTML5 test in Phase 2, not Phase 3: the transition is the most browser-sensitive new behavior; testing it when it is first built gives time to address issues before polish is layered on top

### Research Flags

Phases with standard patterns (skip additional research-phase):
- **Phase 1 (state machine extension):** The `ANIMATING` state pattern is standard Godot FSM practice; `main.gd`'s existing state machine is the direct model. ARCHITECTURE.md provides the exact enum addition and match arm structure.
- **Phase 2 (animation logic):** ARCHITECTURE.md provides exact code patterns including the `get_global_rect().get_center()` coordinate bridge, the `_start_dice_animation()` implementation skeleton, and the `_show_roll_button()` restoration function.
- **Phase 3 (edge cases):** PITFALLS.md "Looks Done But Isn't" checklist fully specifies what to verify and how.

Phases that may need targeted research during execution:
- **Phase 1 (sprite sheet creation):** If creating the sprite sheet from scratch in Blender, frame export settings and atlas packing are not covered in detail. STACK.md specifies format requirements (128x128px, power-of-two, 8-24 frames) but not the Blender workflow. If using a found/purchased asset, no additional research is needed.
- **Phase 2 (HTML5 layout reflow):** The `modulate.a` recommendation over `hide()` is from community sources (MEDIUM confidence). If the reflow flash materializes in HTML5 testing and `modulate.a` does not resolve it, investigate `CanvasItem.visibility_layer` or overlapping-nodes-same-position approaches.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | `AnimatedSprite2D`, `Tween`, `CanvasLayer` verified against official Godot 4.4 docs; API stability confirmed across all 4.x versions; VRAM bug confirmed in Godot issue tracker |
| Features | MEDIUM | P1/P2/P3 prioritization is reasoned from board game UX research and project constraints, not from Steamroller-specific playtesting; may need adjustment after first real session |
| Architecture | HIGH | CanvasLayer + anchor pattern confirmed via multiple community sources and direct inspection of existing `main.gd`; coordinate bridge (`get_global_rect().get_center()`) is the documented pattern |
| Pitfalls | MEDIUM-HIGH | Pitfalls 1, 2, 3 are verified against official Godot issue tracker and docs (HIGH); Pitfalls 4, 5, 6 are from community sources and v1.0 project lessons (MEDIUM) |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address

- **FEATURES.md vs. ARCHITECTURE.md conflict:** FEATURES.md recommends `TextureRect` + `AnimationPlayer` to stay entirely in the Control hierarchy; ARCHITECTURE.md recommends `AnimatedSprite2D` + `CanvasLayer`. This summary recommends the CanvasLayer path, but the implementation team should make a deliberate choice before Phase 1 begins. If the team prefers `AnimationPlayer` timeline authoring over `SpriteFrames`, the TextureRect approach is equally valid — but it must be chosen before any animation code is written.

- **Sprite sheet sourcing:** Research assumes an 8–24 frame PNG sprite sheet will be available. Neither research file addresses creation workflow (Blender, Aseprite, or found asset). This is the only v1.1 deliverable requiring non-code work and has no technical dependency — it can proceed in parallel with the state machine extension in Phase 1.

- **`modulate.a` behavior in Godot 4.5.1:** The recommendation to use `modulate.a = 0.0` instead of `hide()` to prevent layout reflow is from community sources. Validate on actual HTML5 export in Phase 2. If it does not resolve the flash, investigate overlapping-nodes approaches or `DiceAnimationAnchor` dimension preservation.

- **Auto-reroll animation integration point:** The fire-and-forget architecture means `_start_dice_animation()` is called once after all rerolls resolve. The exact modification to the existing auto-reroll loop in `_on_roll_button_pressed()` — where to insert the animation call after silent rerolls exhaust — needs to be worked out in Phase 2 implementation.

## Sources

### Primary (HIGH confidence)
- [AnimatedSprite2D — Godot 4.4 docs](https://docs.godotengine.org/en/4.4/classes/class_animatedsprite2d.html) — class API, SpriteFrames, `animation_finished` signal
- [CanvasLayer — Godot 4 docs](https://docs.godotengine.org/en/stable/classes/class_canvaslayer.html) — layer rendering above Control UI
- [Tween — Godot 4 docs](https://docs.godotengine.org/en/stable/classes/class_tween.html) — `create_tween()`, transition/ease types
- [GitHub #95721 — VRAM compressed textures not rendered in web](https://github.com/godotengine/godot/issues/95721) — confirmed VRAM compression bug in HTML5 export
- [GitHub #77149 — SubViewportContainer scaling bug](https://github.com/godotengine/godot/issues/77149) — why SubViewport approach is avoided
- [Godot 4 docs: Exporting for the Web](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html) — HTML5 export constraints
- Existing `scripts/main.gd` and `scenes/main.tscn` — integration constraints, state machine, node paths
- v1.0 project lesson (validated): GDScript `:=` type inference breaks HTML5 export; explicit type annotations required

### Secondary (MEDIUM confidence)
- [Godot Forum: Possible to use AnimatedSprite2D in Control Node?](https://forum.godotengine.org/t/possible-to-use-animatedsprite2d-in-control-node/96054) — confirms Node2D layout mismatch in Control tree
- [Godot Forum: What's the CORRECT way of having a sprite I can animate on the GUI layer?](https://forum.godotengine.org/t/whats-the-correct-way-of-having-a-sprite-i-can-animate-on-the-gui-layer/59868) — CanvasLayer as community consensus answer
- [Godot Forum: Animation finished signal not triggering](https://forum.godotengine.org/t/animation-finished-signal-not-triggering/108320) — looping animation signal failure behavior
- [GitHub #84250 — animation_finished reliability edge case](https://github.com/godotengine/godot/issues/84250) — why Timer gate is preferred over `await animation_finished` for tumble timing
- [BoardGameGeek blog: Designing the dice UI](https://boardgamegeek.com/blog/12669/blogpost/150134/iv-designing-the-user-interface-focus-on-dice) — dice UX design patterns for digital board games
- [2d-dice-in-godot — Codeberg](https://codeberg.org/sosasees/2d-dice-in-godot) — Godot-specific dice sprite sheet reference implementation

### Tertiary (LOW confidence)
- [AnimatedTextureRect — GitHub (community plugin)](https://github.com/Gabnixe/AnimatedTextureRect) — why avoided; community plugin with potential version drift
- [UX Planet: Dice Cubes app design](https://uxplanet.org/dice-cubes-launching-my-first-app-358eefd25eb2) — animation-before-reveal as expected UX pattern

---
*Research completed: 2026-03-15*
*Ready for roadmap: yes*
