# Project Research Summary

**Project:** Dice Grid Game
**Domain:** Turn-based dice/grid board game (local multiplayer, 2D, HTML5 + desktop)
**Researched:** 2026-03-11
**Confidence:** MEDIUM

## Executive Summary

This is a compact turn-based board game: 2-4 players take turns rolling a d6, claiming matching-numbered cells on a 10x10 grid, and scoring points when they form lines of 3+ consecutive owned cells in any direction. The recommended approach is a pure Godot 4 implementation using Control nodes throughout — no custom rendering, no external libraries, no physics. The engine's built-in primitives (GridContainer, Button, RichTextLabel, GDScript enum) are exactly right for this project at this scale. The key architectural commitment is a strict signals-up / method-calls-down pattern with all game state centralized in a single GameManager node, keeping the 100 CellButton nodes as dumb display leaves.

The recommended build order mirrors the dependency chain: CellButton and BoardData first (pure display and pure data), then GameManager's state machine, then HUD wiring, then integration, then setup/win screens. This "bottom up, data before display" sequence prevents the most damaging pitfall in this type of project: wiring signals before the state machine exists, which causes hard-to-reproduce ghost-move bugs. The project is correctly scoped for v1 — no persistence, no audio, no AI, no networking — and those anti-features should stay out of scope.

The main technical risks are concentrated in Phase 1: line detection off-by-one errors in diagonal scoring, parallel array desync between `board_numbers` and `owner`, state machine bypasses via premature signal wiring, and auto-reroll infinite loop on a near-full board. All are preventable through upfront encapsulation and one isolated test before integrating scoring into the turn loop. The HTML5 export has one known platform-specific risk (SharedArrayBuffer / CORS headers) that is easily avoided by selecting the single-threaded export template from the start.

---

## Key Findings

### Recommended Stack

Godot 4 with GDScript is the correct and already-committed engine choice. Its HTML5 export is first-class, GDScript is purpose-built for game logic, and the built-in Control node system handles all layout without any external UI library. No package manager, no build toolchain, no dependencies — the entire project is a Godot project folder. The single significant version consideration is to verify the current stable release at godotengine.org before starting; 4.3 was current as of the training cutoff and 4.4+ may now be available.

**Core technologies:**
- **Godot 4 (GDScript):** Game engine and language — avoids C# Mono weight, provides native HTML5 export, no licensing cost
- **Control nodes (GridContainer, Button, VBoxContainer):** All UI and board rendering — handles resize/anchor logic automatically for HTML5
- **GDScript enum + match:** Two-phase state machine (WAIT_ROLL / WAIT_PICK) — idiomatic Godot pattern, no FSM plugin needed
- **RandomNumberGenerator.randi_range(1, 6):** Dice rolls and board initialization — correct uniform distribution, no bias
- **RichTextLabel + BBCode:** Game log with per-player colored names — built-in, no external text library needed
- **StyleBoxFlat / Theme resource:** Visual polish — solid-color cells with rounded corners, no image assets required

### Expected Features

The feature research confirms the scope in PROJECT.md is well-calibrated. All table-stakes features are already in spec. The game log is the one differentiator worth including in v1 because it resolves player disputes about scores and roll history without adding meaningful complexity.

**Must have (table stakes):**
- Current-player indication (color + label) — players must always know whose turn it is
- Roll result prominently displayed — must be visible before cell selection
- Valid move highlighting — cells matching the roll must be visually obvious
- Cell ownership color — who owns what must be readable at a glance
- Score display for all players — always visible, not in a menu
- Win condition announcement — block input, show winner clearly
- Disabled claimed cells — no re-claiming, visual + interaction confirmation
- Automatic turn advance — no manual "end turn" button
- Game restart without page reload — "Play Again" returns to setup screen
- Auto-reroll with notification — when no valid moves exist, log explains why

**Should have (v1 differentiators):**
- Game log (roll/claim/score history) — low complexity, high UX value, resolves disputes
- Line flash animation — briefly highlight the scored line before awarding the point
- Animated dice roll — cosmetic; defer until after core loop is stable

**Defer (v2+):**
- Per-player color customization — default palette is sufficient for v1
- Turn timer — not in scope; revisit if playtesting shows analysis paralysis
- AI opponents, online multiplayer, save/load, audio — all explicitly out of scope

### Architecture Approach

The architecture is a single-scene game with one `GameManager` node that owns all state. Communication is strictly one-directional: child nodes (CellButton, DicePanel) emit signals upward; GameManager calls methods downward on display nodes (BoardView, HUD). No game logic lives in display nodes. This pattern prevents the most common bugs in Godot board games — scattered logic across 100 cell nodes, hidden signal dependencies flowing downward, and board data living in the display layer where the logic layer must reach in to read it.

**Major components:**
1. **GameManager** — state machine (WAIT_ROLL / WAIT_PICK), turn sequencing, win detection, orchestration; owns all game arrays
2. **BoardData (inner class or RefCounted)** — encapsulates `board_numbers[y][x]` and `owner[y][x]` behind a single API; prevents array desync
3. **BoardView** — creates and owns 100 CellButton children at `_ready()`; exposes `highlight_cells()`, `update_cell()`, `clear_highlights()`; pure display
4. **CellButton** — shows number and owner color; emits `cell_pressed(x, y)`; contains zero game logic
5. **HUD** — displays current player, all scores, roll value, and game log; pure display
6. **SetupScreen** — player count selection; emits `setup_confirmed(count)` to Main
7. **ScoreManager** — line detection in 4 directions using `count_line(x, y, dx, dy)` isolated function; returns point award boolean

### Critical Pitfalls

1. **State machine bypasses via premature signal wiring** — Build the WAIT_ROLL / WAIT_PICK enum and input guards *before* wiring any button signals. Disable all cell buttons during WAIT_ROLL; enable only valid-move cells during WAIT_PICK. Skipping this causes ghost moves and double-claims that are nearly impossible to reproduce reliably.

2. **Line detection off-by-one in diagonal directions** — Implement `count_line(x, y, dx, dy) -> int` as a standalone function that walks both directions from the origin and returns `positive_run + negative_run + 1`. Test it with known board states (three in a known diagonal, two adjacent) before integrating into the turn loop. Off-by-one here produces visibly wrong scores that players notice immediately.

3. **Parallel array desync (`board_numbers` vs `owner`)** — Encapsulate both arrays in a `BoardData` class from day one. Expose only `get_cell_number()`, `get_owner()`, `claim_cell()`, and `reset()`. Never access raw arrays outside this class. Failure to do this causes stale state across games.

4. **HTML5 SharedArrayBuffer failure** — Select the single-threaded web export template (`Threads: disabled`) before the first HTML5 export. Do not test HTML5 only at the end; run a build on the actual hosting platform in Phase 2. GitHub Pages does not set the required CORS headers by default.

5. **Auto-reroll infinite loop on a near-full board** — Before triggering a reroll, check whether any unclaimed cell exists. If all cells are claimed, transition to end-game rather than rerolling. Cap reroll attempts at 6 as a secondary guard.

---

## Implications for Roadmap

Based on research, the dependency chain is clear and prescribes the phase order. Data structures must precede logic; logic must precede wiring; wiring must precede setup and polish.

### Phase 1: Foundation — Data, State Machine, Core Loop

**Rationale:** The three most critical pitfalls (array desync, state machine bypasses, line detection bugs) must be addressed before any display work. Building the data model and state machine first means display can be added on a correct foundation rather than retrofitting correctness into a broken one.

**Delivers:** A playable game loop in the Godot editor — roll, highlight valid cells, claim a cell, score a line, advance turn, detect win. No visual polish required; correctness matters.

**Addresses features:** Turn flow, roll mechanics, valid move calculation, cell claiming, line detection (4 directions), score tracking, win condition, auto-reroll with guard

**Avoids pitfalls:**
- Pitfall #1 (state machine bypass): Build enum + guards first
- Pitfall #2 (line detection off-by-one): Implement and test `count_line()` in isolation
- Pitfall #3 (array desync): Encapsulate BoardData before any other logic
- Pitfall #5 (auto-reroll infinite loop): Add "any unclaimed cells?" guard from the start
- Pitfall #9 (player count variable duplication): Derive from `players.size()` exclusively
- Pitfall #13 (biased randomization): Use `randi_range(1, 6)` from the start

### Phase 2: Display and Integration

**Rationale:** With game logic correct, the display layer can be built and wired without risking logic regressions. BoardView and HUD are pure display — they receive calls from GameManager and emit signals upward. This phase connects the working logic to a working UI.

**Delivers:** A fully playable game with all visual feedback — cell colors, valid move highlighting, score display, game log, current player indication, win announcement. Also includes the first HTML5 export test.

**Addresses features:** Cell ownership color, valid move highlighting, score display, game log, current player indication, win announcement, disabled claimed cells

**Avoids pitfalls:**
- Pitfall #4 (HTML5 SharedArrayBuffer): Configure single-threaded export template now; test on real host
- Pitfall #6 (stale highlights): Implement `clear_highlights()` called by both `_enter_wait_roll()` and post-claim
- Pitfall #7 (player color contrast): Pre-validate 4 player colors against white text before building cell buttons
- Pitfall #10 (game log rebuild): Use `append_text()` not full rebuild; call `clear()` on new game
- Pitfall #11 (grid overflow at small viewports): Anchor grid to viewport percentage; test at 1280x720 and 1920x1080
- Pitfall #14 (disabled button hover): Use `MOUSE_FILTER_IGNORE` or theme-based disabled styling

### Phase 3: Setup Flow and Game Restart

**Rationale:** Player count selection and game restart are isolated from the core loop. Building them after the core loop is verified means the setup screen flows into a known-working game. The restart path exercises the full reset flow, catching stale state bugs.

**Delivers:** Complete game flow — player count selection at start, "Play Again" returns to setup screen without page reload, game log cleared on new game, all board state reset correctly.

**Addresses features:** Player count selection (2-4), game restart without page reload, auto-reroll notification in log

**Avoids pitfalls:**
- Pitfall #3 (array desync on reset): `BoardData.reset()` is the single atomic reset point
- Pitfall #10 (stale log on new game): `RichTextLabel.clear()` called explicitly in reset path
- Pitfall #12 (orphaned nodes): Prefer static cell scene (permanent children, reset in place) over dynamic recreation

### Phase 4: Polish and Distribution

**Rationale:** Purely additive. All core mechanics are verified before any cosmetic work begins. Polish is low-risk and does not touch game logic.

**Delivers:** Visual polish (line flash animation on score, possible animated dice roll), responsive layout validation across browser sizes, and distributable builds for HTML5 and desktop targets.

**Addresses features:** Line flash animation (confirm scored line before awarding point), animated dice roll (cosmetic, deferred from Phase 1), responsive layout (web + desktop)

**Avoids pitfalls:**
- Pitfall #4 (HTML5 hosting headers): Confirm final hosting platform headers or single-threaded template
- Pitfall #11 (viewport scaling): Final layout pass at multiple window sizes

### Phase Ordering Rationale

- Logic before display: The three highest-severity pitfalls (state machine, line detection, array desync) are pure logic problems. Solving them before display work means display is wired to a correct foundation.
- Bottom-up scene dependency: CellButton has no dependencies; BoardView depends on CellButton; GameManager orchestrates both. Building in this order means each layer is testable before the next is added.
- HTML5 export test in Phase 2, not Phase 4: The SharedArrayBuffer pitfall is a "works locally, fails on host" bug that is easy to avoid but painful to discover late. Testing the first HTML5 export in Phase 2 ensures there is time to address it.
- Setup screen last among core features: The game is fully playable without a setup screen (hardcode player count during development). Adding setup in Phase 3 keeps Phase 1-2 scope clean.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 4 (Polish/Distribution):** Line flash animation implementation specifics in Godot 4 (Tween API), animated dice roll approach, and final HTML5 hosting platform configuration may benefit from a targeted research pass.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Foundation):** All patterns are well-documented — GDScript enum/match state machines, BoardData encapsulation, `randi_range()` usage, `count_line()` algorithm.
- **Phase 2 (Display/Integration):** Signals-up/calls-down is the canonical Godot pattern. GridContainer, Button, RichTextLabel, and ScrollContainer usage is well-documented.
- **Phase 3 (Setup/Restart):** Scene switching and state reset are standard Godot patterns with no novel complexity.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM | Godot 4 and GDScript choices are HIGH confidence; exact current stable version (4.3 vs 4.4+) requires verification at godotengine.org before starting |
| Features | MEDIUM | Table stakes and anti-features are HIGH confidence (anchored in PROJECT.md); differentiators based on comparable games without live web verification |
| Architecture | MEDIUM | Signals-up/calls-down and GameManager patterns are HIGH confidence (canonical Godot); specific node graph is applied inference, not officially prescribed |
| Pitfalls | MEDIUM | Browser SharedArrayBuffer policy is HIGH confidence; Godot-specific HTML5 export template naming needs verification against current docs; all other pitfalls are HIGH confidence (domain-general or Godot-specific known issues) |

**Overall confidence:** MEDIUM

### Gaps to Address

- **Godot stable version:** Verify current stable release at godotengine.org before starting Phase 1. Template download must match engine version exactly.
- **HTML5 export template naming:** Confirm that the single-threaded web export option (`Threads: disabled`) exists with this exact naming in the current Godot version before the Phase 2 export step.
- **RichTextLabel API in Godot 4:** Confirm `append_text()` vs `add_text()` method name in current Godot 4 docs before building the game log.
- **Line flash animation approach:** No research was done on Godot 4 Tween API for cell highlight animations. A brief targeted lookup before Phase 4 is warranted.

---

## Sources

### Primary (HIGH confidence)
- PROJECT.md (this repo) — authoritative for scope, constraints, and existing decisions
- Godot 4 official documentation (training data, through August 2025) — Control nodes, GridContainer, GDScript patterns, signal system, web export

### Secondary (MEDIUM confidence)
- Training knowledge of Godot 4 community patterns — signals-up/calls-down architecture, Autoload usage, state machine patterns
- Training knowledge of comparable digital board games (Qwixx, Sagrada, Blokus, Ingenious) — feature expectations and table stakes
- Browser SharedArrayBuffer / CORS security policy (post-Spectre, 2021+) — well-documented but Godot-specific export template details need current docs verification

### Tertiary (LOW confidence — validate before use)
- Exact Godot 4 minor version (4.3+): https://godotengine.org/download/
- HTML5 export single-threaded template option: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
- RichTextLabel method names in current Godot 4: https://docs.godotengine.org/en/stable/classes/class_richtextlabel.html

---
*Research completed: 2026-03-11*
*Ready for roadmap: yes*
