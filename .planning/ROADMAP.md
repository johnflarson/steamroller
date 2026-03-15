# Roadmap: Dice Grid Game

## Overview

Four phases build the game from the inside out: correct game logic first, visual layer second, complete player flow third, and distributable exports last. Each phase delivers a coherent, independently verifiable capability. The dependency chain — data before display, display before flow, flow before distribution — prevents the hardest bugs this type of project produces.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation** - Core game logic, state machine, and data model running correctly in the editor (completed 2026-03-14)
- [x] **Phase 2: Display and Integration** - Full visual layer wired to working logic; first HTML5 export test (completed 2026-03-14)
- [x] **Phase 3: Setup and Game Flow** - Player count selection, name entry, and complete restart flow (completed 2026-03-15)
- [x] **Phase 4: Distribution** - HTML5 and desktop export builds verified on target platforms (completed 2026-03-15)

## Phase Details

### Phase 1: Foundation
**Goal**: The complete game loop runs correctly in the Godot editor — roll, highlight, claim, score, advance turn, detect win — with no display polish required
**Depends on**: Nothing (first phase)
**Requirements**: LOOP-01, LOOP-02, LOOP-03, LOOP-04, LOOP-05, LOOP-06, SCOR-01, SCOR-02, WIN-01
**Success Criteria** (what must be TRUE):
  1. A player can roll, see valid cells highlighted, claim one, and watch the turn advance to the next player
  2. Placing a third consecutive owned cell in any direction (horizontal, vertical, diagonal) awards exactly 1 point regardless of how many lines are formed
  3. When no valid cells exist for the rolled number, the game auto-rerolls and logs the event without hanging
  4. The game ends and blocks further input when any player reaches 5 points
**Plans:** 3/3 plans complete

Plans:
- [x] 01-01-PLAN.md — Godot project setup, main scene, data model, board generation, dice roll
- [x] 01-02-PLAN.md — Cell highlighting, claiming, turn advance, auto-reroll
- [x] 01-03-PLAN.md — Line detection scoring, spent-cell mechanic, win condition

### Phase 2: Display and Integration
**Goal**: Every game event is visible to the player — cell colors, valid move highlights, score display, game log, current player indicator, win announcement — and the game passes a real HTML5 export test
**Depends on**: Phase 1
**Requirements**: SCOR-03, WIN-02, UI-01, UI-02, UI-03, UI-04, UI-05
**Success Criteria** (what must be TRUE):
  1. Claimed cells show the owning player's color; valid-move cells are visually distinct from neutral and claimed cells
  2. Current player name and color, the current roll value, and all player scores are visible simultaneously without opening any menu
  3. The game log shows each roll, claim, score event, and auto-reroll in scrollable history
  4. When a line scores, the scoring cells briefly flash before the point is awarded
  5. The game loads and plays correctly in a web browser from an HTML5 export
**Plans:** 3/3 plans complete

Plans:
- [x] 02-01-PLAN.md — Dark theme, muted colors, rounded cells, border highlights, HUD sidebar (completed 2026-03-14)
- [ ] 02-02-PLAN.md — Score line flash animation, spent-cell dimming, win/stalemate overlay
- [ ] 02-03-PLAN.md — HTML5 export configuration and browser verification

### Phase 3: Setup and Game Flow
**Goal**: The complete player journey works end-to-end — select player count, enter names, play a full game, see the winner announced, and return to setup without reloading the page
**Depends on**: Phase 2
**Requirements**: SETUP-01, SETUP-02, WIN-03
**Success Criteria** (what must be TRUE):
  1. At game start, a player selects 2, 3, or 4 players and enters a name for each before the board appears
  2. The win screen shows the winner's name and all final scores clearly
  3. Clicking "Play Again" returns to the player count/name selection screen with all board state reset, without reloading the page
**Plans:** 1 plan

Plans:
- [x] 03-01-PLAN.md — Setup screen UI, player count/name entry, game flow wiring, New Game reroute

### Phase 4: Distribution
**Goal**: Game renamed to "Steamroller", distributable builds for HTML5 and desktop (Linux, Windows), verified and deployed to luminaldata.com, itch.io, and GitHub Releases
**Depends on**: Phase 3
**Requirements**: EXPORT-01, EXPORT-02
**Success Criteria** (what must be TRUE):
  1. The HTML5 export loads and plays a complete game in a browser hosted on the target platform (not just local preview)
  2. Desktop builds for Windows and Linux run the full game without errors
**Plans:** 3/3 plans complete

Plans:
- [x] 04-01-PLAN.md — Rename to Steamroller, export presets, deploy script, Astro blog post
- [x] 04-02-PLAN.md — Manual Godot export, deploy execution, platform verification
- [ ] 04-03-PLAN.md — Gap closure: fix embed_pck, Windows product_name, Web preset name, deploy.sh TODO

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 3/3 | Complete   | 2026-03-14 |
| 2. Display and Integration | 3/3 | Complete   | 2026-03-14 |
| 3. Setup and Game Flow | 1/1 | Complete   | 2026-03-15 |
| 4. Distribution | 3/3 | Complete   | 2026-03-15 |
