# Feature Landscape

**Domain:** Dice/Grid Board Game (local multiplayer, 2D, web-compatible)
**Researched:** 2026-03-11
**Confidence Note:** Web search unavailable. Analysis draws on training knowledge of dice/grid games (Qwixx, Yahtzee variants, Blokus, Ingenious, Sagrada, King of Tokyo, digital tabletop ports). Confidence: MEDIUM.

---

## Table Stakes

Features players expect in any turn-based dice/grid game. Missing = product feels broken or unfinished.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Clear current-player indication | Players must always know whose turn it is — confusion causes wrong moves | Low | Highlight name/color, not just a label |
| Roll result prominently displayed | Player needs to know what they rolled before deciding | Low | Dice face or large number, hard to miss |
| Valid move highlighting | After a roll, which cells can be claimed must be visually obvious | Low-Med | Highlight all cells showing the matching number |
| Cell ownership visual (color) | Players must see who owns what at a glance | Low | Per-player colors, consistent throughout |
| Score display for all players | Scores must always be visible, not buried in a menu | Low | Show all active players simultaneously |
| Win condition announcement | Clear end-state screen or banner when someone wins | Low | Block further input after win |
| Disabled/locked claimed cells | Claimed cells must not be clickable by other players | Low | Visual + interaction feedback |
| Turn sequencing | Automatic advance to next player after a move is made | Low | Should not require manual "end turn" button |
| Undo-free design OR undo support | If no undo, moves must have a confirmation gate OR be obviously irreversible | Low-Med | Project has chosen no undo — cell click = committed claim |
| Game restart without engine reload | Players must be able to play again without reloading the page | Low | "Play Again" returns to player count selection |

## Differentiators

Features not universally expected, but add meaningful value or distinguish the game.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Game log (roll/claim/score history) | Lets players review what happened; reduces disputes; makes scoring feel fair | Low-Med | Scrollable list, timestamped or turn-numbered |
| Animated dice roll | Makes the random element feel earned rather than arbitrary; adds physical delight | Med | Godot tween/animation; must not slow turn flow |
| Line flash animation on score | Rewards the scoring moment; makes it clear which line scored | Med | Highlight the 3+ cells briefly before granting point |
| Auto-reroll notification | When no valid moves exist, players need to know why the roll changed | Low | "No valid moves — rerolling" message in game log |
| Numerical cell labels (1-6 shown) | Grid cells showing their number lets players plan before rolling | Low | Already in spec; differentiates from pure abstract grids |
| Player name entry | Personalizes experience, especially for 3-4 players | Low | Simple text input at game start |
| Per-player color customization | Small personalization hook, especially relevant for 3-4 player | Low-Med | Preset palette, no custom color picker needed |
| Responsive layout (web + desktop) | HTML5 target requires layout that works at browser window sizes | Med | Godot Control nodes handle this if designed correctly |
| Turn timer (optional) | Prevents analysis paralysis in casual play | Med | Would need opt-in; not in scope for v1 |
| "Last scores" recap at game end | Show each player's final score and total turns at win screen | Low | Adds closure without complexity |

## Anti-Features

Features to deliberately NOT build for this project.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| AI opponents | Requires game-tree search or heuristics; high complexity, out of scope for v1 | Local multiplayer only; add as a future phase if validated |
| Online/networked multiplayer | Requires server infrastructure, state sync, auth — massive scope creep | Local hot-seat only; Godot's multiplayer API adds significant complexity |
| 3D dice physics | Heavy asset/physics cost, breaks HTML5 performance target | 2D roll animation or instant number reveal |
| Sound effects and music | Audio export adds file size; browser autoplay policies cause friction | Visual-only feedback; audio can be layered post-v1 |
| Save/load game state | Adds persistence complexity; short game sessions don't need it | In-memory only; "Play Again" resets everything |
| Custom board sizes | Parameterized board requires re-balancing spawn density and scoring thresholds | Fixed 10x10; well-defined and validated for the scoring mechanic |
| Undo / move history rewind | Undermines strategic commitment; adds state management complexity | Cells are visually distinct (owned vs valid) — make intentions clear before clicking |
| Tutorial / onboarding flow | Low value for a game this simple; adds build time | Rules accessible via a simple "How to Play" modal or README |
| Achievements / progression | No persistence layer exists; would require save system first | Post-v1 if game gets traction |
| Spectator mode | No networking, no use case for local play | N/A |
| Chat / emoji reactions | Overkill for local hot-seat; players are in the same room | N/A |

---

## Feature Dependencies

```
Player count selection → Board initialization (grid cell values assigned per game)
Board initialization → Turn sequencing starts
Roll result → Valid move highlighting
Valid move highlighting → Cell claim (player clicks highlighted cell)
Cell claim → Line detection (check 4 directions from claimed cell)
Line detection → Score update (if 3+ in a row)
Score update → Win check (if score >= 5)
Win check (not won) → Advance to next player
Win check (won) → Win announcement → Restart option
Auto-reroll → Uses same Roll result → Valid move highlighting path
Game log → Receives events from: Roll, Claim, Score, Win, Auto-reroll
```

---

## MVP Recommendation

Prioritize (already in PROJECT.md active requirements — confirmed as correct scope):

1. Grid rendering with cell numbers (1-6), claiming, and color ownership
2. Turn flow: roll, highlight valid cells, claim, advance player
3. Line detection (4 directions) and scoring
4. Win condition check and end-game screen
5. Game log (low-complexity differentiator, worth including in v1 for UX clarity)
6. Auto-reroll with notification in game log

Defer:
- Animated dice roll: Nice to have, but purely cosmetic — implement after core loop is stable
- Line flash animation: Worth building right after line detection is verified correct
- Per-player color customization: Default palette is fine for v1; add if player count reaches 3-4
- Turn timer: Explicitly out of scope; revisit if playtesting shows analysis paralysis

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Table stakes | HIGH | Established conventions across tabletop digital ports, dice games, and grid games — not subject to recency |
| Differentiators | MEDIUM | Based on comparable games (Qwixx, Sagrada, Blokus); no web search to verify current player expectations in 2026 |
| Anti-features | HIGH | Directly anchored in PROJECT.md out-of-scope decisions, which are well-reasoned |
| Feature dependencies | HIGH | Derived directly from game logic described in PROJECT.md; not speculative |

---

## Sources

- PROJECT.md requirements and out-of-scope definitions (authoritative for this project)
- Training knowledge: Qwixx (dice + scoresheet grid), Sagrada (dice drafting), Blokus (grid territory), Ingenious (line scoring), King of Tokyo (dice press-your-luck), Yahtzee variants
- Training knowledge: Godot 4 HTML5 export constraints and Control node UI patterns
- Note: WebSearch unavailable during research session — no external sources verified
