# Dice Grid Game

## What This Is

A turn-based multiplayer dice board game built in Godot 4. Players take turns rolling a d6 and claiming matching cells on a 10x10 grid. Scoring happens when a player creates three or more of their claimed cells in a row (horizontal, vertical, or diagonal). Designed for 2-4 local players, targeting both web (HTML5) and desktop export.

## Core Value

The core loop — roll, claim, score lines — must feel immediate and satisfying. A complete, playable game where turns flow smoothly and scoring is clear.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] 10x10 grid board with randomly generated cell values (1-6) at game start
- [ ] 2-4 player selection at game start
- [ ] Turn-based flow: roll d6, then claim a matching unclaimed cell
- [ ] Scoring: +1 point when a placement creates 3+ owned cells in a row (any direction)
- [ ] Max 1 point per turn regardless of how many lines are formed
- [ ] Auto-reroll when no valid moves exist for the current roll
- [ ] Game ends when a player reaches 5 points (first to 5 wins)
- [ ] Player colors visually distinguish claimed cells on the board
- [ ] Valid move highlighting after rolling
- [ ] Current player, roll value, and scores displayed in UI
- [ ] Game log showing rolls, claims, and scoring events
- [ ] Web (HTML5) and desktop export support

### Out of Scope

- AI opponents — local multiplayer only for v1
- Online multiplayer / networking
- 3D dice physics — keeping it 2D Control-node UI
- Sound effects and music — visual-only for v1
- Save/load game state
- Custom board sizes — fixed 10x10

## Context

- Engine: Godot 4 with GDScript
- UI approach: Control nodes (VBoxContainer, GridContainer, Buttons) for web compatibility
- Cell buttons show the cell's number (1-6), change color when claimed, disabled when owned
- State machine with two phases: WAIT_ROLL and WAIT_PICK
- Line detection checks 4 directions (horizontal, vertical, two diagonals) from the placed cell
- Scoring interpretation A: lines are about ownership, not matching numbers — the roll only determines which cells you can claim
- Board data: two parallel grids — `board_numbers[y][x]` (1-6) and `owner[y][x]` (-1 or player index)
- Players stored as array of {name, color, score}
- Target lightweight design for HTML5 — no heavy textures or physics

## Constraints

- **Engine**: Godot 4 / GDScript — chosen for web export simplicity
- **UI**: Control nodes only — no 2D physics or 3D; keeps HTML5 export clean
- **Board**: Fixed 10x10 grid
- **Players**: 2-4 local players, no networking

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Godot 4 over Unity | Better HTML5 export, GDScript simplicity, lightweight | — Pending |
| Scoring = ownership lines, not number matching | Simpler, more board-game-like, roll only gates which cell you claim | — Pending |
| Max 1 point per turn | Clean, prevents confusing multi-scores on a single placement | — Pending |
| Auto-reroll on no valid moves | Keeps game flowing, avoids frustrating lost turns | — Pending |
| First to 5 points | Clear win condition with a definitive moment | — Pending |

---
*Last updated: 2026-03-11 after initialization*
