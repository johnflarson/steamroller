# Feature Research

**Domain:** Dice Roll UX — fake-3D animation and roll button polish for a 2D Godot 4 board game
**Researched:** 2026-03-15
**Confidence:** MEDIUM (web search available; Godot-specific claims verified against official docs)

---

## Context

v1.0 shipped with a small, sidebar-positioned roll button that triggers an instant dice result via
`randi_range(1, dice_faces)`. State machine is `WAIT_ROLL → WAIT_PICK`. Auto-reroll is already
built. This milestone (v1.1) adds visual polish: a prominent centered roll button that transforms
into a tumbling fake-3D dice animation before revealing the result.

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features players of digital board games take for granted. Absence reads as unfinished.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Visible dice face showing the rolled number | Players must see the result as a dice face, not just a number label | LOW | Single static TextureRect per face value (1–6), or a large label with die styling |
| Roll animation that hides the result briefly | Without any animation, the result feels arbitrary and unearned | MEDIUM | Even a short 0.5–1.0s tumble loop before landing satisfies this |
| Roll button clearly the primary action | The roll button must be unmissable — size, position, and contrast all signal "press this" | LOW | Large, centered, high-contrast; currently sidebar/small in v1.0 |
| Button disabled during animation | Pressing roll again mid-animation causes state corruption | LOW | `roll_button.disabled = true` during the animation frames, re-enable after |
| Animation terminates on the correct face | The final frame must match `current_roll`; animation cannot land on wrong value | LOW | Sprite frame selection is deterministic after RNG; animation is cosmetic only |
| Reasonable animation duration (0.5–1.5s) | Too fast = no payoff; too slow = frustrating wait between turns | LOW | 0.8s total is a good default. Community consensus: 1s is the sweet spot |

### Differentiators (Competitive Advantage)

Features that elevate the dice roll moment from functional to delightful.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Button-to-dice transformation (single focal point) | Roll button and dice display collapse into one element — no eye travel; cleaner than showing both | MEDIUM | Button hides; dice node appears in same area; reverses after pick is made |
| Fake-3D tumbling effect via sprite sheet | Pre-rendered rotated frames create illusion of a 3D die tumbling — more visceral than a flat spin | MEDIUM | Blender renders ~18–30 frames of a d6 rotating; packed into a single sprite sheet. Alternatively, Godot AnimationPlayer can fake it with rotation + scale tween on a 2D die face. |
| Ease-in fast, ease-out slow landing | Fast initial spin (uncertainty) that slows dramatically before stopping (anticipation) produces measurable excitement; matches physical dice physics | LOW | `Tween.TRANS_CUBIC` ease-in for early frames, `TRANS_EXPO` ease-out for final frames. No extra assets needed if using Tween-based approach. |
| Subtle squash-and-stretch on button press | Button compresses on press (squash), expands on release (stretch) — adds tactile feel without sound | LOW | `tween_property(btn, "scale", Vector2(0.9, 0.9), 0.05)` then bounce back with `TRANS_BOUNCE`. Pure GDScript Tween, no assets. |
| Color pulse on roll button (player color) | Button flashes the active player's color before rolling — reinforces whose turn it is at the moment of action | LOW | One `tween_property` on modulate; uses existing player color palette already in main.gd |
| Highlight transition: dice-to-board | After dice animation ends, the matched cells on the board flash briefly before staying highlighted — draws eye from roll result to valid moves | LOW | Existing valid-cell highlight + a brief flash Tween already exists (line flash pattern); apply same approach here |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| True 3D dice physics (Godot RigidBody3D) | Looks impressive; feels real | Breaks the Control-node-only architecture; HTML5 export becomes unreliable; adds physics engine overhead for a single cosmetic element | Fake-3D sprite sheet or Tween rotation achieves 90% of the visual payoff at 2% of the cost |
| Sound on roll | Enhances tactile feedback | Browser autoplay policies block audio without user interaction; adds file size; explicitly out of scope in PROJECT.md | Visual-only: squash-stretch + color pulse convey the same moment without audio |
| Skippable animation toggle (settings screen) | Power users want fast rolls | Adds a settings UI that doesn't exist; scope creep for a minor concern | Keep total animation under 1s — no player will need to skip something that short |
| Dice rolling physics simulation (bounce, settle) | Looks physically correct | Requires physics simulation or very long sprite sheets; animation length becomes unpredictable; complicates the deterministic state machine | Deterministic timed animation that lands at `current_roll` on a fixed schedule |
| Persistent dice display between turns | Showing the previous roll keeps context visible | Confuses players about whose roll was whose; the current-player indicator already handles context | Clear/hide the dice after the cell is picked; show roll_result_label update instead |

---

## Feature Dependencies

```
Existing: _on_roll_button_pressed()
    └── sets current_roll (RNG)
    └── sets state = WAIT_PICK
    └── calls _update_ui()
    └── calls _highlight_valid_cells()

New: Roll animation layer wraps _on_roll_button_pressed()

Roll button pressed
    └──requires──> Button disabled immediately (prevent double-press)
    └──requires──> Dice animation starts (tumble loop)
                       └──requires──> RNG already resolved (current_roll known before animation)
                       └──requires──> Animation ends on correct face
                                          └──triggers──> state = WAIT_PICK
                                          └──triggers──> _highlight_valid_cells()
                                          └──triggers──> Button re-enables (or hides until next turn)

Button-to-dice transformation
    └──requires──> Roll button and DiceDisplay in same screen region (layout change needed)
    └──enhances──> Single focal point UX (no eye travel)

Auto-reroll (existing)
    └──conflicts with──> Multi-step dice animation per reroll
    └──resolution──> Auto-reroll should NOT trigger per-reroll animation;
                     only the final resolved roll animates (otherwise players
                     watch 3–5 animations before they can act)

Squash-stretch on button press
    └──requires──> Button is a visible non-disabled node at press time
    └──no conflict with──> Tween-based approach (pure GDScript, no AnimationPlayer conflict)
```

### Dependency Notes

- **RNG before animation:** Resolve `current_roll = randi_range(1, dice_faces)` immediately on button press, then play animation. This keeps the state machine correct and avoids needing to communicate the roll value into the animation asynchronously.
- **Auto-reroll conflict:** The existing auto-reroll loop resolves synchronously inside `_on_roll_button_pressed()`. If each reroll triggers a full animation, a player with no valid moves watches 3-5 full animations back-to-back. Solution: run auto-reroll logic silently (no animation per-reroll), play ONE animation at the end for the final resolved value.
- **AnimatedSprite2D vs Control nodes:** The project uses Control-node-only architecture. `AnimatedSprite2D` is a Node2D subclass and does not participate in Control layout. Use `AnimationPlayer` + `TextureRect` (swap `texture` each frame), or a Tween-based rotation on a `TextureRect`, to stay in the Control hierarchy and keep HTML5 export clean. A community-maintained `AnimatedTextureRect` script exists as an alternative.

---

## MVP Definition

### Launch With (v1.1)

Minimum set to make the roll feel meaningfully better than v1.0.

- [ ] Large, centered roll button as unmissable call-to-action — size, position, contrast all updated
- [ ] Squash-stretch on button press (pure Tween, ~5 lines, immediate tactile feedback)
- [ ] Fake-3D tumbling dice animation using Tween: rotate + scale TextureRect over 0.8s, land on correct face
- [ ] Button disabled during animation, re-enabled (or hidden) after pick is complete
- [ ] Auto-reroll plays ONE animation only (suppress per-reroll animation, animate final result)

### Add After Validation (v1.x)

- [ ] Sprite sheet approach (Blender-rendered pre-rendered frames) — only if Tween rotation feels unconvincing after playtesting
- [ ] Color pulse on button (player color flash before animation) — low effort, add if button visual needs more energy
- [ ] Highlight transition (dice-to-board eye guide) — add if playtesters don't notice valid cells after roll

### Future Consideration (v2+)

- [ ] Per-player dice skin customization — requires asset pipeline, no benefit until player retention is validated
- [ ] Animation speed preference — only if animation duration becomes a complaint with actual players

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Large centered roll button | HIGH | LOW (layout change + style) | P1 |
| Squash-stretch button press | HIGH | LOW (Tween, ~5 lines GDScript) | P1 |
| Tumbling dice animation (Tween-based) | HIGH | MEDIUM (TextureRect + AnimationPlayer or Tween, face textures needed) | P1 |
| Button disabled during animation | HIGH | LOW (one line, prevents bugs) | P1 |
| Auto-reroll: single animation only | HIGH | LOW (move RNG resolution before animation gate) | P1 |
| Color pulse on button | MEDIUM | LOW | P2 |
| Dice-to-board highlight transition | MEDIUM | LOW | P2 |
| Sprite sheet (Blender pre-rendered) | MEDIUM | HIGH (3D render pipeline) | P3 |

**Priority key:**
- P1: Must have for v1.1 launch
- P2: Add if implementation slot allows
- P3: Future consideration

---

## Implementation Notes

### Technique: Tween-Based Fake-3D (Recommended)

No sprite sheet required. Pure GDScript. Works in Control hierarchy.

1. On button press: squash-stretch button, disable button, compute `current_roll`.
2. Show a `TextureRect` (or Panel) with dice-face textures. Set initial texture to a "neutral" face.
3. Tween the `TextureRect.rotation_degrees` from 0 to ~720 over 0.8s with `TRANS_CUBIC / EASE_IN` for the first half, then `TRANS_EXPO / EASE_OUT` for the last half (fast then slow landing).
4. At animation end: swap texture to the `current_roll` face, emit signal or call `_post_roll_animation()`.
5. State machine proceeds as before (`WAIT_PICK`, highlight valid cells).

For a face-flip illusion: tween `scale.x` from 1.0 → 0.0 (half-rotation), swap texture, tween `scale.x` 0.0 → 1.0. Looks like the die turned. No rotation math needed.

### Technique: Sprite Sheet (Alternative)

Use only if Tween approach feels insufficient after playtesting.

1. Render 18–24 frames of a d6 rotating in Blender (or use an existing OGA/itch.io asset).
2. Use `AnimationPlayer` + code-driven `TextureRect.texture` swap to cycle frames.
3. Since `AnimatedSprite2D` is Node2D, avoid it. Use `AnimationPlayer` animating `TextureRect`'s `texture` property, or an `AnimatedTextureRect` script.
4. Create 6 named animations (`roll_to_1` through `roll_to_6`); each ends on the correct face frame.

### Godot 4 Constraint: Control Hierarchy

`AnimatedSprite2D` is a Node2D subclass — do NOT use it inside a Control-only layout. It will not
participate in anchoring, container sizing, or HTML5 layout. Use one of:
- `AnimationPlayer` animating a `TextureRect`'s `texture` property (officially supported)
- A Tween on `TextureRect` rotation/scale (pure GDScript, no scene setup needed)
- The community `AnimatedTextureRect` script (GitHub: Gabnixe/AnimatedTextureRect)

---

## Sources

- [Godot 4 AnimatedSprite2D official docs](https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html) — confirmed Node2D subclass (not Control)
- [Godot 4 Tween official docs](https://docs.godotengine.org/en/stable/classes/class_tween.html) — transition/ease types confirmed
- [AnimatedTextureRect community implementation](https://github.com/Gabnixe/AnimatedTextureRect) — workaround for Control-layer sprite animation
- [Godot Forum: AnimationSprite2d in Control node](https://forum.godotengine.org/t/animationsprite2d-in-control-node/111601) — confirms layout mismatch issue
- [Godot 2D sprite animation tutorial](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html) — sprite sheet setup reference
- [BoardGameGeek blog: Designing the dice UI](https://boardgamegeek.com/blog/12669/blogpost/150134/iv-designing-the-user-interface-focus-on-dice) — dice UX design patterns for digital board games
- [UX Planet: Dice Cubes app design](https://uxplanet.org/dice-cubes-launching-my-first-app-358eefd25eb2) — shake gesture and animation-before-reveal as expected UX
- [Animation easing fundamentals](https://easings.net/) — easing curve reference
- [OpenGameArt D20 rolling animations](https://opengameart.org/content/d20-rolling-animations) — sprite sheet technique reference
- [2D dice in Godot (Codeberg)](https://codeberg.org/sosasees/2d-dice-in-godot) — Godot-specific dice implementation reference
- PROJECT.md (authoritative project constraints — Control-only, no audio, no physics)
- scripts/main.gd (existing roll logic: `_on_roll_button_pressed`, auto-reroll, state machine)

---
*Feature research for: Dice animation UX — Steamroller v1.1*
*Researched: 2026-03-15*
