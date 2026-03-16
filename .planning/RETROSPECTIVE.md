# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 — MVP

**Shipped:** 2026-03-15
**Phases:** 4 | **Plans:** 10

### What Was Built
- Complete game loop: roll, highlight, claim, score lines, auto-reroll, win detection
- Dark-themed UI with player colors, score animations, scrollable game log
- Setup screen with player count selection, name entry, Play Again flow
- Multi-platform distribution: HTML5 (luminaldata.com, itch.io), desktop (GitHub Releases)

### What Worked
- Inside-out build order (logic → display → flow → distribution) prevented integration bugs
- Single-file architecture (911 LOC main.gd) kept complexity low and iteration fast
- Explicit GDScript type annotations caught early what would have broken HTML5 export
- butler + gh CLI deploy pipeline made multi-platform release repeatable

### What Was Inefficient
- Phase 4 distribution required a gap closure plan (04-03) for export preset issues that could have been caught in 04-01
- Some ROADMAP plan checkboxes weren't updated after execution (02-02, 02-03, 04-03 still show `[ ]` in archive)
- Performance metrics in STATE.md captured only a subset of plans

### Patterns Established
- RichTextLabel nodes built in .tscn (not code) to avoid Godot runtime issues
- Explicit type annotations required for all GDScript web exports
- embed_pck=true as default for desktop presets

### Key Lessons
1. Export configuration should be verified immediately after first export, not deferred to a separate gap closure plan
2. Single-scene Godot games with Control nodes export cleanly to HTML5 with minimal configuration
3. Deploy scripts should validate all placeholders before running (ITCH_USERNAME pattern)

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1.0 | 4 | 10 | Initial project — established inside-out phase ordering |

### Top Lessons (Verified Across Milestones)

1. Build logic before display — prevents the hardest integration bugs
2. Verify export/deploy config immediately, not in follow-up plans
