# Technology Stack

**Project:** Dice Grid Game
**Researched:** 2026-03-11
**Confidence:** MEDIUM — Godot 4 is stable and well-understood through Aug 2025 training cutoff. Exact minor version (4.3 vs 4.4) could not be verified via live docs due to tool restrictions; recommend checking godotengine.org for the current stable release before starting.

---

## Recommended Stack

### Core Engine

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Godot 4 | 4.3+ (verify latest stable at godotengine.org) | Game engine | Chosen in PROJECT.md. HTML5 export is first-class, GDScript is purpose-built for game logic, no licensing cost, small export footprint. Unity requires license for HTML5 beyond revenue thresholds; Phaser requires a separate web framework mindset. |
| GDScript | Built into Godot 4 | Game logic language | Dynamically typed, Python-like syntax, native to Godot's scene/node model. No compilation step during iteration. C# is an option but adds Mono runtime weight and complicates HTML5 export — avoid for this project. |

### UI Framework (built-in)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Control nodes (Godot built-in) | Same as engine | All UI — grid, buttons, labels, panels | The project already commits to this approach. Control nodes render identically on HTML5 and desktop, respond to browser zoom/resize via anchors, and don't depend on any external library. Using Node2D or 3D nodes for the board would complicate HTML5 sizing and break the lightweight goal. |
| GridContainer | Same as engine | 10x10 cell grid layout | Built-in Control node that tiles children in a grid by column count. Set `columns = 10`, add 100 Button children, done. No manual position math needed. |
| VBoxContainer / HBoxContainer | Same as engine | Score panel, turn display, game log | Standard layout containers — stacking UI regions vertically and horizontally without manual rect management. |
| Button | Same as engine | Individual grid cells | Each cell is a Button. `disabled = true` to prevent re-claiming; `modulate` or `self_modulate` for player color tinting; `text` property shows the die value (1-6). Simpler than a custom drawn cell. |
| RichTextLabel | Same as engine | Game log | Supports BBCode for colored player names in log entries (e.g., `[color=#e74c3c]Player 1[/color] claimed cell (3,7)`). ScrollContainer wrapping keeps log scrollable. |
| Theme / StyleBox | Same as engine | Visual polish | Godot 4's Theme resource lets you define button normal/hover/pressed/disabled appearances project-wide. StyleBoxFlat gives solid color fills with rounded corners — sufficient for a clean board aesthetic without any image assets. |

### State Management (built-in pattern)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| GDScript enum + match | Built into GDScript | Game phase state machine | PROJECT.md already specifies WAIT_ROLL and WAIT_PICK phases. GDScript's `enum` + `match` statement is the idiomatic Godot pattern for a finite state machine of this size. A full FSM plugin (e.g., LimboAI) is overkill for two states. |
| Autoload / Singleton | Built into Godot 4 | Global game state (players, board, turn) | One Autoloaded script (`GameState.gd`) holds `board_numbers`, `owner`, `players`, `current_player`, `phase`. All scenes read from it. Avoids passing state through node hierarchies. This is the standard Godot pattern for shared game data. |

### Randomization (built-in)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| RandomNumberGenerator (Godot built-in) | Same as engine | d6 rolls, initial board population | `RandomNumberGenerator.randi_range(1, 6)`. Seeding with `randomize()` at game start gives different boards each play. No external library needed. |

### Export Targets

| Target | Godot Feature | Notes |
|--------|--------------|-------|
| HTML5 / Web | Godot 4 Web export template | Requires serving over HTTPS or localhost (SharedArrayBuffer requires cross-origin isolation headers). Itchio handles this automatically. Self-hosting needs `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` headers. |
| Windows | Godot 4 Windows export template | `.exe` + PCK file or self-contained `.exe` via embed option. |
| macOS | Godot 4 macOS export template | Requires code signing for Gatekeeper unless distributing via itch.io with user instructions. |
| Linux | Godot 4 Linux export template | Straightforward, no signing required. |

---

## What NOT to Use

| Category | Avoid | Why |
|----------|-------|-----|
| Language | C# / .NET | Adds Mono runtime weight (~30MB+), complicates HTML5 export, no benefit for a project of this scale. GDScript is sufficient. |
| Rendering | Node2D / CanvasItem for board | Control nodes handle layout automatically and are HTML5-resize-safe. Node2D requires manual coordinate math for a grid and fights the browser's viewport model. |
| Physics | RigidBody2D or 3D dice | Out of scope per PROJECT.md. Adds complexity, increases export size, and is unnecessary for a 2D UI board game. |
| State | LimboAI or similar FSM plugins | Two-state machine doesn't justify a plugin dependency. Plugin updates can break on Godot minor version bumps. |
| Persistence | Save/load systems | Out of scope for v1 per PROJECT.md. |
| Audio | AudioStreamPlayer | Out of scope for v1 per PROJECT.md. |
| Networking | MultiplayerAPI / WebRTC | Out of scope. Local multiplayer only. |
| External UI | HTML overlays / JS bridges | Increases complexity and breaks the clean Godot-owns-everything model. All UI stays in Godot Control nodes. |

---

## Project Structure (Recommended)

```
res://
├── project.godot
├── autoloads/
│   └── GameState.gd          # Singleton: board data, players, phase
├── scenes/
│   ├── Main.tscn              # Root scene: wires everything together
│   ├── Board.tscn             # GridContainer + 100 CellButton children
│   ├── CellButton.tscn        # Single reusable cell (Button + label)
│   ├── HUD.tscn               # Score panel, current player, roll result
│   ├── GameLog.tscn           # ScrollContainer > RichTextLabel
│   └── PlayerSetup.tscn       # 2-4 player count selection screen
├── scripts/
│   ├── Board.gd               # Grid logic, valid-move highlighting
│   ├── CellButton.gd          # Cell press handler, color update
│   ├── HUD.gd                 # UI refresh on state change
│   ├── GameLog.gd             # Append formatted log entries
│   └── PlayerSetup.gd         # Player count selection, game start
└── theme/
    └── GameTheme.tres         # StyleBoxFlat definitions for cells/buttons
```

This structure keeps scenes small and single-purpose. GameState.gd as an Autoload means any script can call `GameState.roll()` or read `GameState.current_player` without node path traversal.

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Engine | Godot 4 | Unity | Unity HTML5 WebGL export is heavier and has revenue-based licensing; Godot exports smaller bundles |
| Engine | Godot 4 | Phaser 3 (JS) | Pure web, but requires web dev toolchain; GDScript is simpler for game-specific logic |
| Language | GDScript | C# in Godot | Runtime weight, HTML5 complexity, no benefit at this scope |
| Cell implementation | Button node | Custom drawn Node2D | Button gives hover/press states, disabled state, and text for free |
| Logging | Custom Label array | RichTextLabel + BBCode | BBCode coloring of player names requires RichTextLabel; simpler than managing Label node arrays |

---

## Installation / Setup

```bash
# Download Godot 4 (no installation — single executable)
# https://godotengine.org/download/

# For HTML5 export, download export templates from:
# Editor > Export > Manage Export Templates > Download

# No package manager, no dependencies, no build step.
# Open project.godot in Godot editor and run.
```

For web export specifically, export templates must match the exact engine version. The export template download in-editor handles this automatically.

---

## Confidence Assessment

| Decision | Confidence | Notes |
|----------|------------|-------|
| Godot 4 as engine | HIGH | Explicitly chosen in PROJECT.md; well-established 2024-2025 |
| GDScript over C# | HIGH | Standard guidance for HTML5 targets; C# HTML5 limitations are documented |
| Control nodes for board | HIGH | Project already commits to this; aligns with Godot's UI system design |
| Autoload for game state | HIGH | Canonical Godot pattern, documented in official guides |
| GridContainer for 10x10 | HIGH | Exact use case GridContainer was designed for |
| RichTextLabel for game log | MEDIUM | BBCode support verified in training; confirm current API in Godot 4 docs |
| Specific Godot version (4.3+) | MEDIUM | 4.3 was current as of Aug 2025; may be 4.4+ by now — verify at godotengine.org |
| Web export CORS headers requirement | MEDIUM | SharedArrayBuffer requirement is documented; hosting specifics vary by platform |

---

## Sources

- Godot 4 documentation (training data, Aug 2025): https://docs.godotengine.org/en/stable/
- Godot 4 Web export guide: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
- PROJECT.md constraints and decisions (this repo)
- NOTE: Live web verification was unavailable during this research session. Recommend spot-checking the Godot stable version and any HTML5 export header requirements against current docs before beginning Phase 1.
