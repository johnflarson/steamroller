# Steamroller

## What This Is

A turn-based multiplayer dice board game built in Godot 4. Players roll a d6, claim matching cells on a 10x10 grid, and score points by forming lines of 3+ owned cells. 2-4 local players, deployed to web (HTML5) and desktop (Linux, Windows).

## Core Value

The core loop — roll, claim, score lines — must feel immediate and satisfying. A complete, playable game where turns flow smoothly and scoring is clear.

## Requirements

### Validated

- ✓ 10x10 grid with randomly generated cell values (1-6) at game start — v1.0
- ✓ 2-4 player selection at game start — v1.0
- ✓ Turn-based flow: roll d6, then claim a matching unclaimed cell — v1.0
- ✓ Scoring: +1 point when placement creates 3+ owned cells in a row — v1.0
- ✓ Max 1 point per turn regardless of lines formed — v1.0
- ✓ Auto-reroll when no valid moves exist — v1.0
- ✓ Game ends when a player reaches 5 points — v1.0
- ✓ Player colors visually distinguish claimed cells — v1.0
- ✓ Valid move highlighting after rolling — v1.0
- ✓ Current player, roll value, and scores displayed in UI — v1.0
- ✓ Game log showing rolls, claims, scores, and auto-rerolls — v1.0
- ✓ Line flash animation highlights scoring cells — v1.0
- ✓ Win announcement screen with final scores — v1.0
- ✓ Play Again returns to setup screen — v1.0
- ✓ Player name entry at game start — v1.0
- ✓ Responsive layout for browser and desktop — v1.0
- ✓ HTML5 web export — v1.0
- ✓ Desktop export (Linux, Windows) — v1.0

### Active

(None — planning next milestone)

### Out of Scope

- AI opponents — local multiplayer only for v1
- Online multiplayer / networking — requires server infrastructure
- 3D dice physics — keeping it 2D Control-node UI
- Sound effects and music — visual-only for v1
- Save/load game state — short sessions don't need persistence
- Custom board sizes — fixed 10x10
- Undo / move history rewind — undermines strategic commitment

## Context

Shipped v1.0 with 911 LOC GDScript in a single main.gd file.
Tech stack: Godot 4, GDScript, Control nodes (no Node2D/physics).
Deployed to luminaldata.com (Astro embed), itch.io, and GitHub Releases.
Desktop builds use embed_pck for single-file executables.
Deploy pipeline: butler (itch.io) + gh CLI (GitHub Releases) via deploy.sh.

## Constraints

- **Engine**: Godot 4 / GDScript — chosen for web export simplicity
- **UI**: Control nodes only — no 2D physics or 3D; keeps HTML5 export clean
- **Board**: Fixed 10x10 grid
- **Players**: 2-4 local players, no networking

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Godot 4 over Unity | Better HTML5 export, GDScript simplicity, lightweight | ✓ Good — clean web export, 911 LOC total |
| Scoring = ownership lines, not number matching | Simpler, more board-game-like | ✓ Good — intuitive gameplay |
| Max 1 point per turn | Clean, prevents confusing multi-scores | ✓ Good — clear scoring |
| Auto-reroll on no valid moves | Keeps game flowing, avoids frustrating lost turns | ✓ Good — no dead turns |
| First to 5 points | Clear win condition with a definitive moment | ✓ Good — games end decisively |
| Single main.gd, no autoloads | Short-lived matches, single scene | ✓ Good — simple architecture |
| RichTextLabel in .tscn not code | Avoids Godot issue #94630 | ✓ Good — no runtime issues |
| Explicit type annotations for web export | GDScript := inference breaks HTML5 | ✓ Good — prevented export errors |
| embed_pck=true for desktop | Single-file executables, simpler distribution | ✓ Good — clean deploy |
| butler + gh CLI deploy pipeline | One-command release to all platforms | ✓ Good — repeatable deploys |

---
*Last updated: 2026-03-15 after v1.0 milestone*
