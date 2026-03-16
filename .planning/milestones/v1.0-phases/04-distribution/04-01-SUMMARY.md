---
phase: 04-distribution
plan: 01
subsystem: infra
tags: [godot, export, butler, itch.io, github-releases, astro, deploy]

requires:
  - phase: 03-setup-and-game-flow
    provides: Completed, shippable game with setup screen and full game loop

provides:
  - project.godot renamed to "Steamroller"
  - export_presets.cfg with Web, Linux, Windows presets (embed_pck=true)
  - export/linux/ and export/windows/ directories gitignored and ready for Godot export
  - deploy.sh one-command release script covering Astro, itch.io, and GitHub Releases
  - Astro blog post at luminaldata-www with iframe embed of the game

affects: [deploy workflow, itch.io publishing, github releases, luminaldata.com]

tech-stack:
  added: [butler CLI (itch.io), gh CLI (GitHub Releases)]
  patterns: [git-tag-based semver auto-increment, butler push directory pattern, single-file embed_pck=true binaries]

key-files:
  created:
    - deploy.sh
    - /home/jlarson/code/luminaldata-www/src/content/blog/steamroller.md
  modified:
    - project.godot
    - export_presets.cfg
    - .gitignore

key-decisions:
  - "Game renamed from 'Dice Grid Game' to 'Steamroller' — all export builds now carry the correct name"
  - "Linux and Windows presets use embed_pck=true — single-file distribution, no separate .pck"
  - "deploy.sh uses git tag auto-increment (v0.9.9 default) so first deploy creates v1.0.0"
  - "butler push uses directories not files — html5/linux/windows channels; itch.io html5 channel requires manual 'Playable in browser' flag after first push"
  - "ITCH_USERNAME is a placeholder in deploy.sh — user must set before running"
  - "Astro blog post has no image field — omitted per deferred decisions (no screenshot for v1)"

patterns-established:
  - "deploy.sh validation-first: checks exports exist and tools are authenticated before any mutation"
  - "deploy.sh uses cd back to GAME_REPO_DIR after each repo switch to avoid working directory drift"

requirements-completed: [EXPORT-01, EXPORT-02]

duration: 10min
completed: 2026-03-15
---

# Phase 4 Plan 1: Distribution Configuration Summary

**Renamed game to "Steamroller", added Linux/Windows export presets with embed_pck=true, and created a one-command deploy.sh covering Astro site copy, itch.io butler push, and GitHub Release creation**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-03-15T13:38:00Z
- **Completed:** 2026-03-15T13:48:22Z
- **Tasks:** 2
- **Files modified:** 5 (project.godot, export_presets.cfg, .gitignore, deploy.sh, steamroller.md)

## Accomplishments

- Renamed project from "Dice Grid Game" to "Steamroller" in project.godot; renamed Web preset to "Steamroller Web"
- Added Linux (x86_64) and Windows Desktop export presets to export_presets.cfg with embed_pck=true for single-file distribution
- Created export/linux/ and export/windows/ directories (gitignored); extended .gitignore coverage
- Created deploy.sh with version auto-increment, pre-flight validation, and 5-step release pipeline (Astro, itch.io, GitHub Release)
- Created Astro blog post at luminaldata-www with iframe embed pointing to /games/steamroller/index.html

## Task Commits

Each task was committed atomically:

1. **Task 1: Rename game and configure export presets** - `73c083f` (feat)
2. **Task 2: Create deploy script and Astro blog post** - `26a461c` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `project.godot` - config/name changed to "Steamroller"
- `export_presets.cfg` - Web preset renamed "Steamroller Web"; Linux and Windows presets added (preset.1, preset.2)
- `.gitignore` - Added export/linux/ and export/windows/ patterns
- `deploy.sh` - One-command release script: version auto-increment, export validation, tool validation, Astro copy+push, itch.io butler push x3, GitHub Release with zipped desktop builds
- `/home/jlarson/code/luminaldata-www/src/content/blog/steamroller.md` - Astro blog post with intro paragraph and centered 1280x720 iframe embed

## Decisions Made

- `embed_pck=true` for both Linux and Windows presets — produces a single-file executable, cleaner distribution
- deploy.sh defaults `LAST_TAG` to `v0.9.9` if no git tags exist, so first deploy auto-increments to `v1.0.0`
- ITCH_USERNAME left as a placeholder with a validation check that exits with a clear error if not set
- Astro blog post omits image/imageAlt fields — no screenshot for v1 (per deferred decisions)
- deploy.sh uses `|| true` on the Astro repo git commit so re-runs don't fail when HTML5 files haven't changed

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

- The export/linux/ and export/windows/ directories could not be committed with .gdignore files since the directories themselves are gitignored. This is correct behavior — the directories are created on the local filesystem by this script and by Godot during export, but they are not tracked in git (matching how export/web/ works).

## User Setup Required

Before running deploy.sh for the first time:

1. **Set itch.io username** — edit deploy.sh line with `ITCH_USERNAME="ITCH_USERNAME"` and replace with actual username
2. **Install and authenticate butler** — `butler login` (interactive browser flow)
3. **Install and authenticate gh CLI** — `gh auth login`
4. **Configure GitHub remote** — `gh repo create` or `git remote add origin ...`
5. **Create itch.io game page** — create at https://itch.io/game/new with slug "steamroller" before first `butler push`
6. **Configure SSH access** — `luminaldata-prod` must be in `~/.ssh/config` for the Astro site deploy step
7. **Export from Godot** — Project > Export > Export All (creates all three export builds)

## Next Phase Readiness

- All configuration and tooling is in place for distribution
- User must export from Godot editor to populate export/web/, export/linux/, export/windows/
- After completing user setup above, `bash deploy.sh` distributes to all three destinations in one command
- Phase 4 is now ready for its final step: manual export from Godot and execution of deploy.sh

## Self-Check: PASSED

All created files confirmed present on disk. Both task commits verified in git log.

---
*Phase: 04-distribution*
*Completed: 2026-03-15*
