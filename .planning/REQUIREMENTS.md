# Requirements: Dice Grid Game

**Defined:** 2026-03-11
**Core Value:** The core loop — roll, claim, score lines — must feel immediate and satisfying.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Core Loop

- [x] **LOOP-01**: 10x10 grid with randomly generated cell values (1-6) at game start
- [x] **LOOP-02**: Player rolls d6 via Roll button
- [ ] **LOOP-03**: Valid cells (unclaimed, matching roll) highlighted after rolling
- [ ] **LOOP-04**: Player claims a highlighted cell, which becomes owned (colored, disabled)
- [ ] **LOOP-05**: Turn auto-advances to next player after claim
- [ ] **LOOP-06**: Auto-reroll when no valid moves exist, with notification in game log

### Scoring

- [ ] **SCOR-01**: +1 point when placement creates 3+ owned cells in a row (horizontal, vertical, diagonal)
- [ ] **SCOR-02**: Max 1 point per turn regardless of lines formed
- [ ] **SCOR-03**: Line flash animation briefly highlights the scoring cells

### Win Condition

- [ ] **WIN-01**: Game ends when a player reaches 5 points
- [ ] **WIN-02**: Win announcement screen with final scores
- [ ] **WIN-03**: Play Again returns to player count/name selection

### UI

- [ ] **UI-01**: Current player clearly indicated (name + color)
- [ ] **UI-02**: Roll result prominently displayed
- [ ] **UI-03**: All player scores visible at all times
- [ ] **UI-04**: Scrollable game log showing rolls, claims, scores, and auto-rerolls
- [ ] **UI-05**: Responsive layout that works in browser and desktop windows

### Setup

- [ ] **SETUP-01**: Player count selection (2-4) at game start
- [ ] **SETUP-02**: Player name entry at game start

### Export

- [ ] **EXPORT-01**: HTML5 web export
- [ ] **EXPORT-02**: Desktop export (Windows/Linux/Mac)

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Polish

- **POLISH-01**: Animated dice roll (visual dice animation before showing result)
- **POLISH-02**: Per-player color customization (preset palette selection)
- **POLISH-03**: Sound effects and music

### Gameplay

- **GAME-01**: AI opponents for single-player mode
- **GAME-02**: Turn timer (optional, to prevent analysis paralysis)
- **GAME-03**: Custom board sizes

## Out of Scope

| Feature | Reason |
|---------|--------|
| Online multiplayer | Requires server infrastructure, state sync, auth — massive scope creep |
| 3D dice physics | Heavy asset/physics cost, breaks HTML5 performance target |
| Save/load game state | Short game sessions don't need persistence |
| Undo / move history rewind | Undermines strategic commitment; adds state complexity |
| Tutorial / onboarding flow | Game is simple enough; rules via "How to Play" modal or README |
| Achievements / progression | No persistence layer; post-v1 if game gets traction |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| LOOP-01 | Phase 1 | Complete (01-01) |
| LOOP-02 | Phase 1 | Complete (01-01) |
| LOOP-03 | Phase 1 | Pending |
| LOOP-04 | Phase 1 | Pending |
| LOOP-05 | Phase 1 | Pending |
| LOOP-06 | Phase 1 | Pending |
| SCOR-01 | Phase 1 | Pending |
| SCOR-02 | Phase 1 | Pending |
| WIN-01 | Phase 1 | Pending |
| SCOR-03 | Phase 2 | Pending |
| WIN-02 | Phase 2 | Pending |
| UI-01 | Phase 2 | Pending |
| UI-02 | Phase 2 | Pending |
| UI-03 | Phase 2 | Pending |
| UI-04 | Phase 2 | Pending |
| UI-05 | Phase 2 | Pending |
| SETUP-01 | Phase 3 | Pending |
| SETUP-02 | Phase 3 | Pending |
| WIN-03 | Phase 3 | Pending |
| EXPORT-01 | Phase 4 | Pending |
| EXPORT-02 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 18 total
- Mapped to phases: 18
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-11*
*Last updated: 2026-03-14 after plan 01-01 execution*
