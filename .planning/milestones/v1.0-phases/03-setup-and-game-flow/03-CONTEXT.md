# Phase 3: Setup and Game Flow - Context

**Gathered:** 2026-03-14
**Status:** Ready for planning

<domain>
## Phase Boundary

The complete player journey works end-to-end — select player count, enter names, play a full game, see the winner announced, and return to setup without reloading the page. Covers requirements SETUP-01, SETUP-02, WIN-03.

</domain>

<decisions>
## Implementation Decisions

### Setup Screen Layout
- Centered card on dark background — no game title or heading, straight to player count selection
- Card uses same dark panel style as sidebar (SIDEBAR_BG color, rounded corners) for visual consistency
- Board/HUD hidden during setup — same scene, visibility toggled
- Start Game button uses gold accent style (same as Roll button)

### Player Count Selection
- Three toggle buttons in a row: [2] [3] [4]
- Default selection: 2 players
- Selected button gets gold accent fill; unselected buttons use dark neutral style (like grid cells)
- Changing count shows/hides name fields with slide in/out animation
- Fixed color assignment order always: coral=P1, slate blue=P2, sage=P3, amber=P4 regardless of count
- Names in hidden fields are preserved (switching 4→2→4 keeps P3/P4 names)

### Name Entry
- Input fields pre-filled with default names ("Player 1", "Player 2", etc.)
- Max 15 characters per name
- Empty fields at game start get a random fun name (adjective+noun style: "Brave Fox", "Lucky Star", "Swift Bear")
- Each name input has a colored border in that player's muted color (coral, slate blue, sage, amber) — consistent with score strip style
- Enter/Return in a name field advances focus to the next field; Enter on the last field starts the game

### Play Again Flow
- Win overlay shows single "New Game" button (replaces current behavior)
- "New Game" returns to setup screen (satisfies WIN-03)
- Previous names and player count are remembered in setup fields on return
- Quick fade transition (~0.2s) between setup↔game and game-over→setup

### Claude's Discretion
- Exact slide animation duration and easing for name fields
- Random name word lists (adjective and noun pools)
- Fade transition implementation details
- Setup card sizing and padding
- Input field styling details beyond colored border

</decisions>

<specifics>
## Specific Ideas

- The setup card mockup: player count toggles at top, name fields below with colored borders, Start Game button at bottom
- Random names should feel playful and memorable — "Brave Fox", "Lucky Star" style
- Fade transition gives a polished feel without being slow

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `_style_button_gold(btn)`: Styles any Button with gold accent — reuse for Start Game button and selected count toggle
- `_set_cell_color(btn, bg, border_color, border_px)`: StyleBoxFlat utility with border support — adaptable for name input colored borders
- `PLAYER_COLORS`, `PLAYER_HEX` constants: Muted color palette already defined
- `SIDEBAR_BG`, `NEUTRAL_CELL` constants: Dark theme colors for setup card and toggle buttons
- `_on_new_game_pressed()`: Existing reset logic — needs modification to route to setup instead of instant restart

### Established Patterns
- StyleBoxFlat for all custom styling (buttons, panels, badges) — setup screen follows same approach
- Single `main.gd` script owns all state — setup logic added to same script
- Visibility toggling already used for `win_overlay` — same pattern for setup screen
- `_setup_score_strip()` dynamically creates panels per `player_count` — already handles variable count
- Tween API used throughout (score animation, panel flash) — available for fade and slide transitions

### Integration Points
- `_ready()` currently goes straight to gameplay — needs to show setup screen first
- `players` array is hardcoded with 4 entries — must become dynamic based on setup selections
- `player_count` variable exists but defaults to 4 — setup screen sets this
- `_on_new_game_pressed()` needs to show setup screen instead of resetting in place
- Score strip (`_setup_score_strip()`) needs rebuilding when player count changes between games
- `_build_grid()` signal connections are made once at `_ready()` — comment in code warns about Phase 3 needing to avoid double-fire

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-setup-and-game-flow*
*Context gathered: 2026-03-14*
