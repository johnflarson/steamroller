# Pitfalls Research

**Domain:** Adding dice sprite animation to an existing Godot 4 Control-node UI game (HTML5 + desktop)
**Project:** Steamroller v1.1 — Dice Polish milestone
**Researched:** 2026-03-15
**Confidence:** MEDIUM — Godot 4 forum threads and GitHub issues verified; some behavior nuances are version-dependent. Flag for validation against current Godot 4.x docs before implementation.

---

## Scope Note

This file covers pitfalls specific to the v1.1 work: adding a fake-3D tumbling dice animation and prominent roll button to the existing single-file Control-node game. The v1.0 pitfalls (state machine, line detection, HTML5 SharedArrayBuffer, etc.) are documented in the v1.0 milestone research and are assumed solved. Pitfalls below are integration-focused: what breaks when you add animation to an already-working Control-node game.

---

## Critical Pitfalls

Mistakes that require rewrites or produce broken behavior on HTML5.

---

### Pitfall 1: Using AnimatedSprite2D as a Direct Child of a Control Node

**What goes wrong:** A developer adds `AnimatedSprite2D` as a child of a `CenterContainer` or other Control node. The sprite renders but ignores the Control layout system entirely. It positions using its own `position` property (world-space offset from parent origin), not Control anchors. At different browser window sizes the dice drifts off-center. The animation plays correctly in the editor at 1920x1080 and fails visually at every other resolution.

**Why it happens:** `AnimatedSprite2D` is a `Node2D`, not a `Control`. Node2D children of Control nodes are not subject to anchors, size flags, or container layout — they float at a 2D world position. The hierarchy looks correct in the scene tree but the layout contract is broken.

**How to avoid:** Use `TextureRect` (a Control node) as the visible dice display, animated via `AnimationPlayer` changing the `texture` or `region_rect` property each frame. This keeps everything in the Control layout tree and respects anchors and resizing. Alternatively, wrap the `AnimatedSprite2D` in a `SubViewportContainer` — but this adds significant complexity (see Pitfall 2).

The recommended approach for this project: a single `TextureRect` inside a `CenterContainer`, with an `AnimationPlayer` that steps through frame regions on a spritesheet using `AtlasTexture` or by swapping individual frame textures. This is pure Control-node territory and scales correctly.

**Warning signs:**
- Dice is perfectly centered in the editor but off-center in the exported HTML5 build.
- Sprite position does not respond to `SIZE_EXPAND_FILL` or anchor changes.
- `get_rect()` returns zero size on the parent container.

**Phase to address:** Phase 1 (dice animation node setup). Choose TextureRect + AnimationPlayer before writing any animation code.

---

### Pitfall 2: SubViewport Workaround Adds Broken Input Passthrough

**What goes wrong:** Some tutorials suggest embedding a `Node2D`-based animated sprite inside a `SubViewportContainer` to get it into the Control layer. This works visually but breaks input: click events on overlapping Control nodes (including the roll button itself) may not reach their targets because the SubViewport intercepts them. On HTML5, pointer event routing through SubViewports has additional quirks.

**Why it happens:** A `SubViewportContainer` with `stretch=true` captures input events for its viewport by default. Transparent areas of the SubViewport still consume click events.

**How to avoid:** Do not use SubViewport for this feature. The dice animation is purely decorative — it requires no physics, no 2D spatial logic, and no input of its own. A `TextureRect` + `AnimationPlayer` approach achieves the same visual result with zero SubViewport complexity. The SubViewport approach is appropriate when you need a full 2D world rendered into a UI surface; a frame-flipping dice does not qualify.

**Warning signs:**
- Roll button stops responding to clicks after adding dice animation.
- Mouse events reach the button only when clicking outside the dice display area.
- Input passthrough works in editor but fails in HTML5.

**Phase to address:** Phase 1 (architecture decision). Discard SubViewport approach at design time, not after implementation.

---

### Pitfall 3: Looping Animation Never Emits `animation_finished`

**What goes wrong:** The tumbling dice animation is set to loop so it spins continuously while the player has not yet rolled. The developer connects `animation_finished` to advance game state. The signal is never emitted — looping animations do not emit `animation_finished` in Godot 4. The game state never advances. On first play, the roll button appears broken.

**Why it happens:** In Godot 4, `AnimationPlayer` only emits `animation_finished` (or `AnimatedSprite2D.animation_finished`) when a **non-looping** animation reaches its final frame. A looping animation has no final frame by definition. This is correct behavior but trips up developers coming from other engines or who conflate "tumble loop" with "tumble-then-land" in a single animation.

**How to avoid:** Split the dice animation into two named states:
1. `"tumble"` — a looping spin animation played while waiting for roll input.
2. `"land"` — a non-looping animation that plays after the roll value is determined, ends on the correct face frame. Connect `animation_finished` on this animation only to advance game state.

Call `play("land")` when the roll value is known; call `play("tumble")` on loop at all other times. The `animation_finished` signal fires reliably because only `"land"` is non-looping.

**Warning signs:**
- `animation_finished` never fires after connecting it.
- Game state advances immediately (frame 0) instead of after the animation.
- Connecting `animation_finished` causes a call on every loop iteration in some Godot versions — verify behavior in target version.

**Phase to address:** Phase 1 (animation design). Name and structure animation clips correctly before wiring state machine signals.

---

### Pitfall 4: `await animation_finished` Leaving Game State Suspended on Fast Input

**What goes wrong:** The roll button handler uses `await animation_player.animation_finished` to pause until the dice lands. A player (or tester) presses the roll button, then immediately clicks a cell before the animation completes. The cell click is processed because `WAIT_PICK` was set (or not set correctly) while the coroutine was suspended. The turn advances with no animation completion, or the animation finishes after a cell is claimed and the `animation_finished` handler runs on a stale state.

**Why it happens:** GDScript `await` creates a coroutine. The function returns immediately on the first `await`, and the caller (the signal handler) has completed. Any other signal connected while the coroutine is sleeping can fire and mutate game state. This is a concurrency issue in cooperative multitasking.

**How to avoid:** Do not rely solely on `await` for state gating. The state machine is the source of truth. Pattern:
1. On roll button pressed: set state to `ANIMATING` (a new state between `WAIT_ROLL` and `WAIT_PICK`).
2. In the `ANIMATING` state, disable the roll button and disable all cell buttons.
3. Play the land animation.
4. Connect `animation_finished` to a handler (not via `await`) that sets state to `WAIT_PICK` and enables valid cells.

This way, button clicks during the animation cannot reach active handlers because no handlers respond in the `ANIMATING` state. The existing state machine pattern (already validated in v1.0) extends naturally.

**Warning signs:**
- Cells can be claimed before the dice finishes landing.
- Second roll starts while first animation is still playing.
- Game log shows claim events with roll value from a previous turn.

**Phase to address:** Phase 1 (state machine extension). Add the `ANIMATING` state as the first code change before touching any animation nodes.

---

### Pitfall 5: VRAM Texture Compression Breaks Sprites in Web Export

**What goes wrong:** The dice spritesheet PNG is imported with VRAM compression enabled (Godot's default for many texture types). In the editor and desktop export the sprites look correct. In the HTML5 export they render as solid black rectangles or are completely invisible. This is a documented Godot 4 bug affecting VRAM-compressed textures in WebGL2.

**Why it happens:** Godot 4's VRAM compression formats (S3TC/DXT, BPTC/BC7) require GPU extensions that WebGL2 does not guarantee. When the browser does not have the extension and the texture was pre-compressed for VRAM, Godot cannot decompress it at runtime in the browser, resulting in black textures. This is a confirmed issue tracked in godotengine/godot#95721.

**How to avoid:** When importing the dice spritesheet, explicitly set the compression mode to `Lossless` (PNG) or `Lossy` (WebP). Do **not** use `VRAM Compressed`. For a small dice spritesheet (a few hundred pixels square), lossless is fine and the file size difference is negligible. Set this on import before the first web export test — changing it later requires re-exporting.

**Warning signs:**
- Dice sprite appears as black rectangle in browser, works fine in desktop build.
- No JS console errors — the texture loads, it just renders black.
- Issue only manifests in the HTML5 export, not in the editor's "Run in Browser" preview served locally.

**Phase to address:** Phase 1 (texture import configuration). Set import settings when adding the spritesheet asset, before any HTML5 test.

---

### Pitfall 6: Button-to-Dice Transition Using `hide()`/`show()` Causes Layout Reflow Flash

**What goes wrong:** The roll button is hidden with `button.hide()` and the dice `TextureRect` is shown with `dice_rect.show()` in the same frame. On HTML5, this can cause a one-frame layout reflow visible as a flash or jump, because Control nodes that change visibility force a container layout recalculation. On slower browsers (mobile, low-end hardware) this is a full-frame stutter.

**Why it happens:** `hide()` removes the node from layout flow (equivalent to CSS `display: none`). The container reflows without the button, repositioning other elements, then reflows again with the dice rect. Two layout passes in one frame.

**How to avoid:** Use `modulate.a = 0.0` (fully transparent) instead of `hide()` to make elements invisible while keeping them in layout flow. Or use `visible = false` only for elements that genuinely should not occupy space (dice rect before the first roll). Better yet, lay out the button and dice rect in the same `CenterContainer` position, overlapping, and toggle visibility using `modulate` so layout never changes — only compositing does.

**Warning signs:**
- Roll button disappearing causes other UI elements to shift briefly.
- Dice appears in a slightly different position than the button was.
- Transition looks fine in the editor at 60fps but flashes on the web build.

**Phase to address:** Phase 2 (button-to-dice transition implementation). Test transition on actual HTML5 export immediately after building it.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Hard-code animation duration in a timer instead of connecting `animation_finished` | Quick workaround for signal issues | Breaks silently if animation FPS is changed; timing drifts on slow hardware | Never — use the signal |
| Use `AnimatedSprite2D` as Node2D child of Control | Familiar API, easy to set up | Layout breaks at all non-development resolutions | Never for this project |
| Single animation clip with "land on 6" hard-coded, swap frames in code | Avoids creating 6 animation variants | Any animation change requires both asset and code changes | Only for rapid prototype; remove before shipping |
| Skip the `ANIMATING` state, use `await` + boolean flag | Fewer states to manage | Coroutine suspension allows race conditions on fast input | Never — state machine already exists, extend it |
| Import spritesheet with default VRAM compression | Zero extra steps | Black texture on every HTML5 test | Never — set compression on first import |

---

## Integration Gotchas

Common mistakes when connecting animation to the existing v1.0 system.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| State machine extension | Adding animation logic inside the existing `WAIT_ROLL` handler | Add a new `ANIMATING` state; keep states single-purpose |
| Auto-reroll mechanic | Playing land animation with auto-reroll value, then immediately triggering another reroll before animation ends | Auto-reroll must wait until current land animation finishes; `ANIMATING` state blocks it |
| Roll button layout | Moving roll button from HUD sidebar to center without updating all layout references in main.gd | Audit all node path references (`$HUD/RollButton` style paths) before moving the button in the scene tree |
| AnimationPlayer node path | Referencing animation player with hard-coded path that breaks when scene structure changes | Use `@onready var _dice_anim: AnimationPlayer = $DiceArea/AnimationPlayer` with explicit type annotation (required for HTML5 export — see v1.0 lesson) |
| Spritesheet frame count | Spritesheet has 24 frames but AnimationPlayer track uses 20 — extra frames show garbage data | Verify frame count in both the texture import settings and the AnimationPlayer track before testing |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Large uncompressed spritesheet in HTML5 | Initial page load stalls 3-5 seconds; animation pop-in on first play | Keep spritesheet under 512x512 for a simple 6-face dice; use lossless WebP if size is a concern | Any spritesheet over ~1MB uncompressed |
| Per-frame texture swapping from separate PNG files | Framerate drop during animation on mobile browsers | Use a single spritesheet with `AtlasTexture` region updates — one draw call, one texture bind | 12+ frames as individual textures |
| AnimationPlayer with many keyframes on a Control node tree | Main thread stall during scene load on web | Keep animation clips short (< 1 second, < 30 keyframes); bake complex animations into spritesheet frames | Not a concern for a simple dice animation — note only if scope creeps |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Animation plays but game state doesn't obviously change after it | Players don't know when to click a cell | Flash or highlight valid cells immediately when land animation ends — use `animation_finished` handler to trigger existing highlight logic |
| Auto-reroll plays the land animation, pauses, then immediately replays it | Confusing — looks like a bug | On auto-reroll, display a brief "No moves! Re-rolling..." message (already in game log) and skip the land animation, or play it immediately without pause |
| Roll button disappears during animation with no replacement indicator | Players lose sense of what to do next | During `ANIMATING` state, show the dice display in place of the button — the spinning dice IS the feedback, no gap |
| Landing animation always ends on face 6 regardless of roll value | Players notice the dice never matches their roll value | Ensure the land animation targets the correct face for each of the 6 roll values — parameterize by roll result |

---

## "Looks Done But Isn't" Checklist

Things that appear complete in the editor but have missing pieces.

- [ ] **Dice centers correctly:** Test in HTML5 at 1280x720, 1920x1080, and a narrow browser window. Centering in the editor does not guarantee centering on web.
- [ ] **All 6 faces work:** Manually trigger each roll value (1-6) and verify the land animation ends on the correct face. Easy to test only face 6 during development.
- [ ] **Auto-reroll doesn't break animation:** Force an auto-reroll scenario (manually claim all cells of one value) and verify the animation sequence is sensible and does not double-play.
- [ ] **Texture compression set correctly:** Check the spritesheet `.import` file — confirm `compress/mode` is NOT `3` (VRAM Compressed). Should be `0` (Lossless) or `1` (Lossy).
- [ ] **Explicit type annotation on all new `@onready` vars:** Every new node reference added for v1.1 must use explicit typing (`var _dice: TextureRect`, not `var _dice := $Dice`). The v1.0 export proved `:=` inference breaks HTML5.
- [ ] **`ANIMATING` state blocks cell clicks:** During dice animation, click every cell on the board and confirm nothing is claimed.
- [ ] **Roll button re-enabled after animation:** After the land animation ends and valid cells are highlighted, confirm the HUD state is correct and the roll button will re-appear on the next turn.
- [ ] **Win condition during animation:** Win a game such that the last claim happens while dice animation would normally be playing — confirm win screen appears correctly and no orphaned animation coroutines run.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| AnimatedSprite2D layout breaks discovered post-implementation | HIGH | Rebuild dice display as TextureRect; re-wire AnimationPlayer tracks; re-test all 6 faces |
| VRAM compression black texture on web | LOW | Change import setting, re-import, re-export — 15 minutes |
| `animation_finished` never fires (looping animation) | LOW | Rename animation, uncheck loop flag — 5 minutes |
| Race condition from missing `ANIMATING` state | MEDIUM | Add state enum value, add match arms in all button handlers, test all transition paths |
| Layout reflow flash from `hide()`/`show()` | LOW | Replace with `modulate.a` toggling; test transition timing |

---

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| AnimatedSprite2D in Control node (#1) | Phase 1 — architecture decision | Confirm `TextureRect` is the dice display node type in scene before any animation code |
| SubViewport complexity (#2) | Phase 1 — architecture decision | SubViewport does not appear anywhere in the scene tree |
| Looping animation never emits finished signal (#3) | Phase 1 — animation clip design | Two named clips exist: `"tumble"` (loop) and `"land"` (no loop); verified in AnimationPlayer |
| `await` race condition on fast input (#4) | Phase 1 — state machine extension | `ANIMATING` state added to enum; cell buttons confirmed disabled in that state |
| VRAM texture compression on web (#5) | Phase 1 — asset import setup | `.import` file for spritesheet confirms non-VRAM compression before first web test |
| Layout reflow flash (#6) | Phase 2 — transition implementation | Transition tested on actual HTML5 export, no flash at 60fps and throttled CPU |

---

## Sources

- Godot Forum: [Possible to use AnimatedSprite2D in Control Node?](https://forum.godotengine.org/t/possible-to-use-animatedsprite2d-in-control-node/96054) — MEDIUM confidence
- Godot Forum: [What's the CORRECT way of having a sprite I can animate on the GUI layer?](https://forum.godotengine.org/t/whats-the-correct-way-of-having-a-sprite-i-can-animate-on-the-gui-layer/59868) — MEDIUM confidence
- GitHub: [VRAM compressed textures not rendered in web — Issue #95721](https://github.com/godotengine/godot/issues/95721) — HIGH confidence (confirmed bug report)
- Godot Forum: [Animation finished signal not triggering](https://forum.godotengine.org/t/animation-finished-signal-not-triggering/108320) — MEDIUM confidence
- Godot Forum: [AnimationPlayer not finishing and not calling animation_finished](https://forum.godotengine.org/t/animationplayer-not-finishing-and-not-calling-animation-finished/75737) — MEDIUM confidence
- GitHub: [Possible race condition with animated sprites — Issue #99076](https://github.com/godotengine/godot/issues/99076) — MEDIUM confidence
- Godot Forum: [How to use Node2Ds in a Control?](https://forum.godotengine.org/t/how-to-use-node2ds-in-a-control/101437) — MEDIUM confidence
- Godot 4 docs: [AnimatedSprite2D](https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html) — HIGH confidence
- Godot 4 docs: [Exporting for the Web](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html) — HIGH confidence
- v1.0 project lesson: GDScript `:=` type inference breaks HTML5 export — HIGH confidence (validated in this project)

---
*Pitfalls research for: Steamroller v1.1 — dice sprite animation in Control-node Godot 4 game*
*Researched: 2026-03-15*
