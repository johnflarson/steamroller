# Phase 1: Foundation - Context

**Gathered:** 2026-03-11
**Status:** Ready for planning

<domain>
## Phase Boundary

The complete game loop runs correctly in the Godot editor — roll, highlight, claim, score, advance turn, detect win — with no display polish required. Covers requirements LOOP-01 through LOOP-06, SCOR-01, SCOR-02, and WIN-01.

</domain>

<decisions>
## Implementation Decisions

### Board Generation
- Weighted random distribution: each number (1-6) appears roughly equally (~16-17 times) but with natural variance — not strictly balanced, not pure random
- Count-balanced only — no spatial distribution constraints (same numbers can cluster)
- Fresh random board generated each new game (no seed support)
- All cell numbers visible to players at all times (matches PROJECT.md: "cell buttons show the cell's number")
- Fixed d6 for Phase 1, but data model should use a configurable dice range variable (not hardcoded to 6) for future extensibility
- Grid size stored as configurable rows/cols variables (default 10x10), not hardcoded

### Stalemate Handling
- If all cells claimed and no player has 5 points: highest score wins
- Ties resolved as shared victory (all tied players win together)
- No near-stalemate warnings or countdown
- Unlimited consecutive auto-rerolls until a valid move is found; each reroll logged

### Line Detection & Scoring
- Lines of 3, 4, or 5 owned cells all score exactly 1 point (no bonus for longer lines)
- Line detection checks only from the just-placed cell (4 directions: horizontal, vertical, 2 diagonals) — not a full board scan
- Cells that participated in a scored line become "spent" — they cannot contribute to future line scoring
- Data model needs a per-cell "scored" boolean flag to track spent status
- Spent cells remain owned/colored but will be visually distinct in Phase 2

### Editor-Playable UI (Phase 1 Minimum)
- Functional clickable grid buttons showing cell numbers, changing color when claimed
- Roll button, text labels for current player, roll result, and scores
- In-game log visible in the scene (not just console output) showing rolls, claims, scores, rerolls
- Support 2-4 players with hardcoded names ("Player 1" through "Player 4") — no selection UI
- Basic valid-move highlighting: cells matching the roll visually change when claimable

### Claude's Discretion
- Exact weighted random algorithm for board generation
- GDScript architecture (scene tree structure, node organization)
- State machine implementation details
- Color palette for player ownership (functional, not polished)
- Log formatting and scroll behavior

</decisions>

<specifics>
## Specific Ideas

- Board should feel like it has a fair spread of numbers without being perfectly uniform — "weighted random" feel
- The "spent cells" mechanic adds strategic depth: players can't just keep extending the same cluster forever
- Game should default to 4 players for testing (exercises the full player array)

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — greenfield project, no existing code

### Established Patterns
- None yet — Phase 1 establishes the foundational patterns

### Integration Points
- Phase 1 creates the core data model and state machine that all subsequent phases build on
- Phase 2 will add visual polish to the functional UI built here
- Phase 3 will replace hardcoded players with a setup/selection flow

</code_context>

<deferred>
## Deferred Ideas

- **Board visibility setting**: Toggle between always-visible and revealed-on-roll number modes — user wants this as a game setting (future phase, needs settings UI)
- **Configurable dice range**: d4/d8/d10 variants — data model prepared but not exposed in Phase 1
- **Custom board sizes**: Data model flexible but UI locked to 10x10 for v1

</deferred>

---

*Phase: 01-foundation*
*Context gathered: 2026-03-11*
