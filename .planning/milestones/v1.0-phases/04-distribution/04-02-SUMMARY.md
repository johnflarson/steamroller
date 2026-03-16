---
phase: 04-distribution
plan: 02
subsystem: distribution
tags: [godot, html5, linux, windows, butler, itch.io, github-releases, astro]

# Dependency graph
requires:
  - phase: 04-01
    provides: deploy.sh, export presets configured for Steamroller Web/Linux/Windows, Astro blog post scaffolded
provides:
  - HTML5 build live at luminaldata.com/blog/steamroller/ embedded in Astro site
  - HTML5 build live and playable on itch.io steamroller page
  - Linux desktop binary and Windows .exe on GitHub Releases
  - Verified, distributed v1 release of Steamroller
affects: []

# Tech tracking
tech-stack:
  added: [butler (itch.io upload CLI), gh CLI (GitHub Releases), Godot export templates (HTML5/Linux/Windows)]
  patterns: [manual Godot editor export workflow, butler push for itch.io channels, gh release create for desktop builds]

key-files:
  created: [export/web/index.html, export/linux/steamroller.x86_64, export/windows/steamroller.exe]
  modified: [deploy.sh (ITCH_USERNAME replaced with real username)]

key-decisions:
  - "Manual Godot editor export used (locked decision from 04-01) — no headless CLI export"
  - "itch.io page saved as Draft initially; html5 channel marked playable-in-browser after first butler push"
  - "GitHub repo created for dicegame; gh release create used for versioned desktop zip assets"

patterns-established:
  - "Deploy pattern: butler push html5 channel, gh release create with zip assets, rsync to Astro site"
  - "Version tagging: deploy.sh reads version from project.godot and tags GitHub releases accordingly"

requirements-completed: [EXPORT-01, EXPORT-02]

# Metrics
duration: ~60min
completed: 2026-03-15
---

# Phase 4 Plan 02: Distribution Execution Summary

**Steamroller v1 deployed to all three targets: luminaldata.com Astro embed, itch.io HTML5 playable, and GitHub Releases with Linux/Windows desktop builds**

## Performance

- **Duration:** ~60 min (manual export + account setup + deploy run + platform verification)
- **Started:** 2026-03-15
- **Completed:** 2026-03-15
- **Tasks:** 3
- **Files modified:** 3 export artifacts + deploy.sh configuration

## Accomplishments

- Exported all three Godot builds (HTML5, Linux x86_64, Windows .exe) from the Godot 4 editor using the configured presets
- Installed butler, authenticated, created itch.io game page with correct slug and viewport settings, and ran deploy.sh to completion
- Verified the game plays correctly on all five distribution destinations: luminaldata.com iframe, itch.io embed, Linux desktop, Windows desktop, and GitHub Releases page

## Task Commits

All three tasks were human-action or human-verify checkpoints — no code commits were generated. The export artifacts are binary files and the deploy ran against external services.

1. **Task 1: Export builds from Godot editor** - manual export via Godot editor UI (no commit)
2. **Task 2: Set up distribution prerequisites and run deploy** - external service setup + deploy.sh execution (no commit)
3. **Task 3: Verify game on all platforms** - manual verification across 5 platforms (no commit)

## Files Created/Modified

- `export/web/index.html` - HTML5 export for browser play (and supporting .pck/.js/.wasm files)
- `export/linux/steamroller.x86_64` - Single-file Linux desktop executable (embed_pck=true)
- `export/windows/steamroller.exe` - Single-file Windows desktop executable (embed_pck=true)
- `deploy.sh` - Updated ITCH_USERNAME placeholder with real itch.io username before running

## Decisions Made

- Manual Godot editor export confirmed as the correct path — the locked decision from 04-01 planning worked without issues
- itch.io page created as Draft initially; after the first butler push the html5 channel was manually marked "This file will be played in the browser" per the plan
- GitHub repo created under the dicegame slug; desktop builds zipped and attached to a versioned GitHub Release

## Deviations from Plan

None - plan executed exactly as written. All three tasks completed in sequence with no unexpected blockers.

## Issues Encountered

None.

## User Setup Required

All external service configuration was completed during this plan's execution:
- butler installed and authenticated via `butler login`
- itch.io game page created at the steamroller slug with HTML embed configured
- GitHub repo created and gh CLI authenticated
- Astro site SSH access to luminaldata-prod confirmed working

No further setup required for future re-deploys — running `./deploy.sh` is sufficient.

## Next Phase Readiness

This is the final plan of Phase 4 and the final plan of the entire v1 roadmap. All requirements are complete:

- EXPORT-01 (HTML5 web export): Complete — live on luminaldata.com and itch.io
- EXPORT-02 (Desktop export Windows/Linux): Complete — available on GitHub Releases and itch.io

**The game is shipped. Steamroller v1 is distributed and verified on all target platforms.**

## Self-Check: PASSED

- SUMMARY.md: FOUND at .planning/phases/04-distribution/04-02-SUMMARY.md
- STATE.md: Updated — progress 100%, stopped_at updated, decision added, metric recorded
- ROADMAP.md: Updated — Phase 4 shows 2/2 complete, Phase 3 shows 1/1 complete, all plan entries checked off
- REQUIREMENTS.md: EXPORT-01 and EXPORT-02 already marked complete (no change needed)

---
*Phase: 04-distribution*
*Completed: 2026-03-15*
