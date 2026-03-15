# Phase 4: Distribution - Context

**Gathered:** 2026-03-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Distributable builds exist for HTML5 and desktop (Linux, Windows), verified to run correctly. Game renamed to "Steamroller." Hosted on user's Astro site (luminaldata.com) and itch.io. Desktop builds distributed via GitHub Releases and itch.io. A deploy script automates the full release flow.

</domain>

<decisions>
## Implementation Decisions

### Game Rename
- Rename game from "Dice Grid Game" to "Steamroller" as a separate early step
- Update project.godot config/name, export preset names, and any display text
- Done before any exports so all builds carry the correct name

### Hosting — Astro Site (luminaldata.com)
- HTML5 build embedded in an Astro blog post as a centered fixed-size iframe (1280x720)
- Blog post includes a brief intro paragraph + the game embed — minimal content
- Export files placed at `public/games/steamroller/` in the luminaldata-www repo (`/home/jlarson/code/luminaldata-www`)
- Served at `/games/steamroller/index.html`

### Hosting — itch.io
- Project slug: `steamroller`
- Minimal page: title, brief description, playable HTML5 embed — no screenshots or cover image for v1
- Tags: Board game, Dice, Strategy, Multiplayer, Local
- Initially unlisted (test via direct link, flip to public when ready)
- Desktop downloads (Linux, Windows) also uploaded to itch.io page

### Desktop Platforms
- Linux and Windows builds only — macOS skipped for v1 (no Apple Developer account for signing)
- Windows build tested by running .exe on WSL2 host Windows
- Linux build tested natively

### Build Process
- Manual export from Godot editor UI (export templates already downloaded)
- No CI/CD — simple manual workflow for v1

### Window Size
- Keep current 1280x720 viewport (standard 720p)
- Desktop window is resizable (Control nodes handle stretching)

### Export Folder Structure
- `export/web/` — HTML5 build (existing)
- `export/linux/` — Linux x86_64 binary
- `export/windows/` — Windows .exe
- All export/ contents gitignored (build artifacts, not tracked)

### Deploy Script
- Single `deploy.sh` script lives in this repo (game is source of truth)
- Full all-in-one: copies HTML5 to Astro repo, pushes HTML5 + desktop builds to itch.io via butler CLI, creates GitHub Release with zipped desktop builds
- Auto-increments patch version from last git tag (v1.0.0 → v1.0.1)

### Claude's Discretion
- itch.io page description text
- Astro blog post intro wording
- Deploy script error handling and validation details
- Exact butler channel names for itch.io uploads
- GitHub Release description format
- .gitignore patterns for new export directories
- Export preset configuration for Linux and Windows

</decisions>

<specifics>
## Specific Ideas

- The Astro site repo is at `/home/jlarson/code/luminaldata-www` — deploy script should reference this path
- Butler CLI (itch.io) used for automated uploads — user has an itch.io account already
- The deploy script should be a one-command release: run it after exporting from Godot, and it handles everything

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `export_presets.cfg`: Web export preset already configured with `export/web/index.html` path, thread support disabled, desktop VRAM compression enabled
- `.gitignore`: Already ignores `export/web/*.html`, `*.js`, `*.wasm`, `*.pck`, `*.png`, `*.ico` — needs extension for linux/ and windows/ directories

### Established Patterns
- Export path convention: `export/{platform}/` with named output files
- Web preset uses `script_export_mode=2` (compiled) and `variant/extensions_support=false`

### Integration Points
- `project.godot` line 13: `config/name="Dice Grid Game"` — rename to "Steamroller"
- `export_presets.cfg`: Need to add Linux and Windows presets alongside existing Web preset
- `export/web/` directory exists — linux/ and windows/ directories need creation
- `.gitignore`: Extend patterns for new export directories

</code_context>

<deferred>
## Deferred Ideas

- **macOS build**: Skipped for v1 due to code signing requirements. Revisit if Apple Developer account obtained.
- **CI/CD pipeline**: GitHub Actions with godot-ci for automated builds — defer to future if manual process becomes tedious.
- **PWA support**: progressive_web_app/enabled is currently false in export_presets.cfg — could enable for installable web app experience.
- **Cover image / screenshots for itch.io**: Polish the itch.io page with visuals after v1 launch.

</deferred>

---

*Phase: 04-distribution*
*Context gathered: 2026-03-14*
