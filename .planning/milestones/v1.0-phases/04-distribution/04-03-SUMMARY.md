---
phase: 04-distribution
plan: 03
subsystem: distribution
tags: [godot, export-presets, deploy, itch-io, github-releases]

# Dependency graph
requires:
  - phase: 04-distribution
    provides: export_presets.cfg and deploy.sh created in plans 01-02
provides:
  - export_presets.cfg with embed_pck=true on Linux and Windows presets (single-file executables)
  - Windows preset with application/product_name="Steamroller"
  - Web preset renamed to "Steamroller Web"
  - deploy.sh free of misleading TODO comment
affects: [future re-exports from Godot editor, deploy pipeline re-runs]

# Tech tracking
tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified:
    - export_presets.cfg
    - deploy.sh

key-decisions:
  - "embed_pck=true on Linux and Windows presets ensures single-file executables — deploy.sh zip commands that package only the binary are correct as-is"
  - "ITCH_USERNAME TODO comment removed since value was already correctly set to 'johnfredone'"

patterns-established: []

requirements-completed: [EXPORT-01, EXPORT-02]

# Metrics
duration: 3min
completed: 2026-03-15
---

# Phase 4 Plan 03: Export Preset Gap Closure Summary

**export_presets.cfg corrected with embed_pck=true on Linux/Windows, product_name set, Web preset renamed — deploy pipeline now produces single-file executables**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-15T21:00:00Z
- **Completed:** 2026-03-15T21:03:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Linux and Windows presets now have embed_pck=true, meaning re-export from Godot produces self-contained single-file executables (no separate .pck companion file needed)
- Windows preset now has application/product_name="Steamroller" for correct binary metadata
- Web preset renamed from "Web" to "Steamroller Web" for consistent naming
- deploy.sh TODO comment removed — ITCH_USERNAME was already correctly set and the comment was misleading

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix export_presets.cfg — embed_pck, product_name, preset name** - `b6a8e31` (fix)
2. **Task 2: Remove misleading TODO comment from deploy.sh** - `84aa239` (fix)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `export_presets.cfg` - Fixed: embed_pck=true on Linux and Windows presets, product_name="Steamroller" on Windows, Web preset renamed to "Steamroller Web"
- `deploy.sh` - Fixed: removed misleading TODO comment from ITCH_USERNAME line

## Decisions Made

- embed_pck=true means the zip commands in deploy.sh (which package only the binary) are already correct — no further changes to deploy.sh packaging logic needed
- ITCH_USERNAME value "johnfredone" preserved unchanged; only the comment was removed

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

After these config changes, the user must re-export from Godot editor (Project > Export > Export All) to produce new single-file binaries with embedded .pck, then re-run deploy.sh to update all distribution channels.

## Next Phase Readiness

- Phase 4 gap closure complete — all distribution artifacts are now correct
- Re-export and re-deploy required to apply the embed_pck fix to live builds
- No further planning phases scheduled

---
*Phase: 04-distribution*
*Completed: 2026-03-15*
