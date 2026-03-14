# Phase 2: Display and Integration - Context

**Gathered:** 2026-03-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Every game event is visible to the player — cell colors, valid move highlights, score display, game log, current player indicator, win announcement — and the game passes a real HTML5 export test. Covers requirements SCOR-03, WIN-02, UI-01, UI-02, UI-03, UI-04, UI-05.

</domain>

<decisions>
## Implementation Decisions

### Visual Theming
- Softer/muted player color palette (e.g., coral, slate blue, sage, amber) replacing raw RED/BLUE/GREEN/YELLOW
- Dark theme background (charcoal/dark gray) as default — muted colors pop against dark
- Cells have rounded corners with subtle 2-3px gaps between them (GridContainer spacing)
- Spent cells (already scored) shown as dimmed/faded version of player color (~50% opacity/saturation)
- Valid-move highlight uses a glowing border/outline (e.g., gold/white) rather than background color fill
- Sidebar has a subtle background panel (slightly different shade, rounded edges) to separate from board

### Score Line Flash (SCOR-03)
- Scale pop effect: scoring cells briefly enlarge (~1.2x scale) then return to normal
- Quick ~0.3s duration — keeps game pace snappy
- Score updates during the animation (not waiting for animation to complete)
- After pop animation, scored cells immediately transition to dimmed/spent appearance
- Use Godot Tween API for the animation

### Win Announcement (WIN-02)
- Semi-transparent overlay dims the board, centered panel shows winner info
- Displays winner name prominently + ranked list of all players with final scores
- Overlay header/border tinted with winning player's color
- Stalemate endings use same overlay layout but "Game Over" message instead of "X wins!", showing highest scorer(s)
- Board remains visible underneath overlay

### HUD & Sidebar
- Current player shown as colored name badge (player's muted color as background, like a tag/chip)
- Dice roll result displayed as large prominent number (48px+ font), unmissable
- Scores displayed as compact horizontal bar (all scores in one strip, like a sports ticker)
- Game log entries color-coded by acting player using RichTextLabel BBCode — score events get bold/highlight emphasis
- Roll button styled as prominent accent button (larger, distinct accent/gold color), visually disabled during pick phase

### Claude's Discretion
- Exact muted color hex values for each player
- Dark theme exact background shades
- Font choices and sizes (beyond roll result being large)
- Exact glow/outline thickness and color for valid-move highlight
- Sidebar panel corner radius and padding
- Game log formatting details beyond color-coding
- HTML5 export configuration specifics

</decisions>

<specifics>
## Specific Ideas

- Cells should feel like modern rounded tiles with clean separation — not a flat spreadsheet grid
- The scale pop for scoring should feel satisfying but brief — a quick "boop" effect
- The win overlay should feel celebratory with the player's color, not generic
- Horizontal score bar inspired by sports ticker — compact, always visible

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `_set_cell_color(btn, color)`: Sets StyleBoxFlat on all 4 button states — can be extended for rounded corners, borders, and dimmed variants
- `RichTextLabel` with `bbcode_enabled = true`: Already set up for color-coded log entries via BBCode tags
- `_log(message)`: Simple append function — can be enhanced to accept player index for color-coding

### Established Patterns
- All UI updates flow through `_update_ui()` — centralized refresh point for sidebar elements
- StyleBoxFlat used for cell coloring — same approach works for rounded corners, borders, sidebar panels
- Game state machine (`WAIT_ROLL`, `WAIT_PICK`, `GAME_OVER`) — overlay visibility can key off `GAME_OVER` state
- Button nodes created once at `_ready()`, updated in place — no grid rebuilding

### Integration Points
- `_check_score()` returns the scoring cells — animation needs these cell positions to trigger scale pop
- `_check_win_or_stalemate()` and `_resolve_stalemate()` — need to trigger overlay display instead of just log messages
- `HIGHLIGHT_COLOR` constant — replace with border/outline approach
- `players` array has `color` property — update with muted palette values
- `scored_grid` boolean per cell — drives dimmed appearance logic in cell rendering

</code_context>

<deferred>
## Deferred Ideas

- **Light/dark theme toggle**: User wants players to select between light and dark themes — needs settings UI, deferred to future phase
- **Board visibility setting** (from Phase 1): Toggle between always-visible and revealed-on-roll number modes

</deferred>

---

*Phase: 02-display-and-integration*
*Context gathered: 2026-03-14*
