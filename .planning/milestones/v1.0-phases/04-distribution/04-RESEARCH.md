# Phase 4: Distribution - Research

**Researched:** 2026-03-14
**Domain:** Godot 4 export, itch.io butler deployment, GitHub Releases, Astro site integration
**Confidence:** HIGH

## Summary

Phase 4 distributes the completed Steamroller game (renamed from "Dice Grid Game") as HTML5 and desktop (Linux, Windows) builds. The HTML5 export already exists in `export/web/` with threading disabled (`variant/thread_support=false`), which is the critical configuration that allows iframe embedding without COEP/COOP headers. Desktop presets (Linux, Windows) need to be added to `export_presets.cfg` via the Godot editor UI. Distribution flows to three destinations: the Astro site at luminaldata.com, itch.io via the butler CLI, and GitHub Releases via the `gh` CLI.

The single-threaded web export (added in Godot 4.3 and already configured in this project) is a load-bearing architectural choice. It eliminates the SharedArrayBuffer/COEP header requirement that makes Godot 4 HTML5 exports fail in iframes on most browsers. The project is already correctly configured for this — no change needed to the Web preset.

**Primary recommendation:** Create Linux and Windows export presets in the Godot editor, run manual exports, then execute a `deploy.sh` script that handles all three distribution destinations in sequence.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Game Rename**
- Rename game from "Dice Grid Game" to "Steamroller" as a separate early step
- Update project.godot config/name, export preset names, and any display text
- Done before any exports so all builds carry the correct name

**Hosting — Astro Site (luminaldata.com)**
- HTML5 build embedded in an Astro blog post as a centered fixed-size iframe (1280x720)
- Blog post includes a brief intro paragraph + the game embed — minimal content
- Export files placed at `public/games/steamroller/` in the luminaldata-www repo (`/home/jlarson/code/luminaldata-www`)
- Served at `/games/steamroller/index.html`

**Hosting — itch.io**
- Project slug: `steamroller`
- Minimal page: title, brief description, playable HTML5 embed — no screenshots or cover image for v1
- Tags: Board game, Dice, Strategy, Multiplayer, Local
- Initially unlisted (test via direct link, flip to public when ready)
- Desktop downloads (Linux, Windows) also uploaded to itch.io page

**Desktop Platforms**
- Linux and Windows builds only — macOS skipped for v1 (no Apple Developer account for signing)
- Windows build tested by running .exe on WSL2 host Windows
- Linux build tested natively

**Build Process**
- Manual export from Godot editor UI (export templates already downloaded)
- No CI/CD — simple manual workflow for v1

**Window Size**
- Keep current 1280x720 viewport (standard 720p)
- Desktop window is resizable (Control nodes handle stretching)

**Export Folder Structure**
- `export/web/` — HTML5 build (existing)
- `export/linux/` — Linux x86_64 binary
- `export/windows/` — Windows .exe
- All export/ contents gitignored (build artifacts, not tracked)

**Deploy Script**
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

### Deferred Ideas (OUT OF SCOPE)
- macOS build: Skipped for v1 due to code signing requirements
- CI/CD pipeline: GitHub Actions with godot-ci — defer to future
- PWA support: progressive_web_app/enabled is currently false — could enable later
- Cover image / screenshots for itch.io: Polish after v1 launch
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| EXPORT-01 | HTML5 web export | Web preset already configured with thread_support=false; deploy to Astro site + itch.io; iframe embedding confirmed safe with single-threaded export |
| EXPORT-02 | Desktop export (Windows/Linux) | Linux and Windows presets need adding to export_presets.cfg via editor; binary_format/embed_pck=true recommended; butler channels + GitHub Releases for distribution |
</phase_requirements>

## Standard Stack

### Core Tools
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Godot 4.6 Editor | 4.6 | Export Linux/Windows desktop builds | Already installed; export templates confirmed downloaded |
| butler CLI | latest | Push builds to itch.io | Official itch.io tool; handles delta patching, channel management |
| gh CLI | latest | Create GitHub Releases with assets | Official GitHub CLI; must be installed + authenticated before deploy |

### Supporting
| Tool | Purpose | Notes |
|------|---------|-------|
| zip / tar | Package desktop builds for GitHub Release | Available in WSL2 by default |
| git tag | Version tracking for deploy script auto-increment | Used to derive next semver patch version |

**Tool installation:**
```bash
# butler — download and install to ~/bin
curl -L -o /tmp/butler.zip https://broth.itch.zone/butler/linux-amd64/LATEST/archive/default
unzip /tmp/butler.zip -d ~/bin/
chmod +x ~/bin/butler
# Add ~/bin to PATH if not already present

# gh CLI — check package manager or https://cli.github.com/
sudo apt install gh  # or equivalent

# Authenticate both
butler login          # interactive browser flow
gh auth login         # interactive
```

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| butler CLI | itch.io web uploader | Manual — can't script; butler is the standard for automated uploads |
| gh CLI release | GitHub web UI | Manual — can't script asset uploads from shell |
| iframe embed | direct page link | Loses in-site experience; iframe works because thread_support=false |

## Architecture Patterns

### Recommended Project Structure (additions)
```
res://
├── export/
│   ├── web/          # existing HTML5 build (gitignored)
│   ├── linux/        # steamroller.x86_64 (gitignored)
│   └── windows/      # steamroller.exe (gitignored)
├── deploy.sh         # one-command release script
└── export_presets.cfg  # Web + Linux + Windows presets (committed)

/home/jlarson/code/luminaldata-www/
└── public/
    └── games/
        └── steamroller/     # HTML5 files copied here by deploy.sh
            ├── index.html
            ├── index.js
            ├── index.wasm
            └── index.pck
```

### Pattern 1: Export Preset Configuration (export_presets.cfg)

**What:** Linux and Windows presets appended after existing Web preset, numbered sequentially.
**When to use:** Created once via Godot editor UI (Project > Export > Add...), then committed.

```ini
# Source: Godot docs + crystal-bit/godot-game-template verified pattern
[preset.1]

name="Linux"
platform="Linux"
runnable=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="export/linux/steamroller.x86_64"
encrypt_pck=false
encrypt_directory=false
script_export_mode=2

[preset.1.options]

custom_template/debug=""
custom_template/release=""
debug/export_console_wrapper=1
binary_format/architecture="x86_64"
binary_format/embed_pck=true
texture_format/s3tc_bptc=true
texture_format/etc2_astc=false

[preset.2]

name="Windows"
platform="Windows Desktop"
runnable=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="export/windows/steamroller.exe"
encrypt_pck=false
encrypt_directory=false
script_export_mode=2

[preset.2.options]

custom_template/debug=""
custom_template/release=""
binary_format/architecture="x86_64"
binary_format/embed_pck=true
texture_format/s3tc_bptc=true
texture_format/etc2_astc=false
codesign/enable=false
application/icon=""
application/console_wrapper_icon=""
application/icon_interpolation=4
application/file_version=""
application/product_version=""
application/company_name=""
application/product_name="Steamroller"
application/file_description=""
application/copyright=""
application/trademarks=""
```

Note: `binary_format/embed_pck=true` produces a single-file executable (no separate .pck). This is preferred for distribution — one file per platform.

### Pattern 2: Butler Channel Names and Push Commands

**What:** Butler uses channel names to create upload slots on itch.io. Platform detection is automatic from the channel name.

**Channel naming convention** (verified from official docs):
- `html5` — the web build (must manually tag as "Playable in Browser" on itch.io page after first push)
- `linux` — Linux x86_64 binary (auto-detected as Linux platform)
- `windows` — Windows .exe (auto-detected as Windows platform)

```bash
# Source: https://itch.io/docs/butler/pushing.html
# Push HTML5 (push the directory, not individual files)
butler push export/web/ USERNAME/steamroller:html5 --userversion "1.0.0"

# Push Linux binary
butler push export/linux/ USERNAME/steamroller:linux --userversion "1.0.0"

# Push Windows binary
butler push export/windows/ USERNAME/steamroller:windows --userversion "1.0.0"
```

**Authentication:** `butler login` for interactive setup. For scripted use, set `BUTLER_API_KEY` environment variable. Credentials stored at `~/.config/itch/butler_creds` after login.

### Pattern 3: GitHub Release Creation

**What:** `gh release create` tags the commit, creates a release, and uploads zip assets in one command.

**Prerequisite:** Repo must have a GitHub remote configured, and `gh auth login` must have been run.

```bash
# Source: https://cli.github.com/manual/gh_release_create
# Create release with zipped assets
gh release create v1.0.0 \
  export/linux/steamroller-linux-v1.0.0.zip \
  export/windows/steamroller-windows-v1.0.0.zip \
  --title "Steamroller v1.0.0" \
  --notes "Initial release. Play at https://luminaldata.com/games/steamroller"
```

### Pattern 4: Version Auto-Increment in deploy.sh

**What:** Derive next patch version from last git tag.

```bash
# Get last tag, default to v1.0.0 if none
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.9.9")
# Strip 'v', split on '.', increment patch
IFS='.' read -r MAJOR MINOR PATCH <<< "${LAST_TAG#v}"
NEXT_VERSION="v${MAJOR}.${MINOR}.$((PATCH + 1))"
```

### Pattern 5: Astro Blog Post with iframe Embed

**What:** A markdown blog post in `src/content/blog/` with inline HTML for the iframe. The Astro content schema allows HTML in markdown files.

The iframe must set `allow="fullscreen"` for the Godot fullscreen button. Because `variant/thread_support=false` is set, no COEP/COOP headers are required — the game will load in a standard iframe on any modern browser.

The existing server (Caddy → nginx) does not require special header configuration for the single-threaded build.

```markdown
---
title: "Steamroller — a browser dice strategy game"
description: "Roll dice, claim cells, form lines. A turn-based strategy game for 2-4 players."
author: "John Larson"
date: 2026-03-14
tags: ["game", "godot", "dice", "strategy", "browser game"]
linkedin: false
bluesky: false
---

Steamroller is a turn-based dice strategy game for 2-4 local players.
Roll the die, claim matching cells on the board, and form lines of 3 or more
to score. First player to 5 points wins.

<div style="display:flex;justify-content:center;margin:2rem 0;">
  <iframe
    src="/games/steamroller/index.html"
    width="1280"
    height="720"
    style="border:none;max-width:100%;"
    allow="fullscreen"
  ></iframe>
</div>
```

### Pattern 6: deploy.sh Structure

```bash
#!/usr/bin/env bash
set -euo pipefail

# --- Version ---
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.9.9")
IFS='.' read -r MAJOR MINOR PATCH <<< "${LAST_TAG#v}"
VERSION="v${MAJOR}.${MINOR}.$((PATCH + 1))"
echo "==> Releasing ${VERSION}"

# --- Validate exports exist ---
[[ -f export/linux/steamroller.x86_64 ]] || { echo "ERROR: Linux build missing. Export from Godot first."; exit 1; }
[[ -f export/windows/steamroller.exe ]] || { echo "ERROR: Windows build missing. Export from Godot first."; exit 1; }
[[ -f export/web/index.html ]] || { echo "ERROR: Web build missing. Export from Godot first."; exit 1; }

ASTRO_REPO="/home/jlarson/code/luminaldata-www"
ITCH_USER="USERNAME"  # replace with actual itch.io username
GAME_SLUG="steamroller"

# --- 1. Copy HTML5 to Astro repo ---
echo "==> Copying HTML5 build to Astro repo..."
mkdir -p "${ASTRO_REPO}/public/games/steamroller"
cp export/web/* "${ASTRO_REPO}/public/games/steamroller/"
cd "${ASTRO_REPO}"
git add public/games/steamroller/
git commit -m "feat: update Steamroller HTML5 build to ${VERSION}" || true
git push origin main
cd -

# --- 2. Deploy Astro site ---
echo "==> Deploying luminaldata-www..."
cd "${ASTRO_REPO}"
bash deploy.sh
cd -

# --- 3. Push to itch.io via butler ---
echo "==> Pushing builds to itch.io..."
butler push export/web/  "${ITCH_USER}/${GAME_SLUG}:html5"    --userversion "${VERSION#v}"
butler push export/linux/   "${ITCH_USER}/${GAME_SLUG}:linux"   --userversion "${VERSION#v}"
butler push export/windows/ "${ITCH_USER}/${GAME_SLUG}:windows" --userversion "${VERSION#v}"

# --- 4. Package for GitHub Release ---
echo "==> Packaging for GitHub Release..."
mkdir -p /tmp/steamroller-release
zip -j "/tmp/steamroller-release/steamroller-linux-${VERSION}.zip" export/linux/steamroller.x86_64
zip -j "/tmp/steamroller-release/steamroller-windows-${VERSION}.zip" export/windows/steamroller.exe

# --- 5. Create GitHub Release ---
echo "==> Creating GitHub Release ${VERSION}..."
git tag "${VERSION}"
git push origin "${VERSION}"
gh release create "${VERSION}" \
  "/tmp/steamroller-linux-${VERSION}.zip" \
  "/tmp/steamroller-windows-${VERSION}.zip" \
  --title "Steamroller ${VERSION}" \
  --notes "Play in browser: https://luminaldata.com/games/steamroller"

echo "==> Release ${VERSION} complete!"
```

### Anti-Patterns to Avoid
- **Adding export directories to git:** build artifacts bloat the repo; `export/linux/` and `export/windows/` must be gitignored
- **Exporting from command line headless:** Known issues with reimporting in Godot 4.3+; the user decided manual editor export anyway
- **Pushing .pck separately:** With `embed_pck=true`, the PCK is baked into the binary — do not distribute a separate .pck file for desktop builds
- **Setting thread_support=true on web export:** Would break iframe embedding on most browsers; leave as false
- **Committing export/web/ HTML5 files to this repo:** Files are already gitignored and belong in the Astro repo instead

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| itch.io uploads | custom HTTP upload script | butler CLI | Butler handles delta patching, channel management, progress reporting, auth token management |
| GitHub Release assets | curl/API script | gh CLI | Native tag creation, asset upload in one command |
| Version numbering | custom version file | git tag + shell arithmetic | Source of truth is already in git tags; no separate version file to keep in sync |
| Cross-origin isolation for HTML5 | custom service worker | thread_support=false (already set) | The project already has the correct fix; adding a service worker would be redundant complexity |

**Key insight:** The hardest Godot 4 HTML5 distribution problem (SharedArrayBuffer/COEP) is already solved by the existing `variant/thread_support=false` configuration. Don't change it.

## Common Pitfalls

### Pitfall 1: HTML5 build not loading in iframe
**What goes wrong:** Godot 4 HTML5 exports with thread support enabled require COEP/COOP headers and SharedArrayBuffer — these don't work inside iframes on Firefox/Safari.
**Why it happens:** SharedArrayBuffer was restricted after Spectre; cross-origin isolation is required to re-enable it, and iframes break that isolation.
**How to avoid:** Already avoided — `variant/thread_support=false` is set in the existing Web preset. Do not enable thread support.
**Warning signs:** Browser console shows SharedArrayBuffer errors; game canvas is blank in iframe.

### Pitfall 2: Linux platform name in export_presets.cfg
**What goes wrong:** Older presets created in Godot < 4.3 may use `platform="Linux/X11"`. Godot 4.3+ renamed it to `platform="Linux"`.
**Why it happens:** Breaking rename between minor versions.
**How to avoid:** Create presets fresh in Godot 4.6 editor UI — it will use the correct name automatically.
**Warning signs:** `!preset.is_valid()` error when attempting export; preset doesn't appear in the Export dialog.

### Pitfall 3: butler pushing files instead of directory
**What goes wrong:** `butler push export/web/index.html` pushes a single file, not the full game. itch.io needs all the JS/WASM/PCK files.
**Why it happens:** Confusing file vs directory syntax.
**How to avoid:** Always push the **directory**: `butler push export/web/ user/game:html5` (trailing slash optional but clear).

### Pitfall 4: itch.io HTML5 channel not tagged as playable
**What goes wrong:** After first butler push of the html5 channel, itch.io shows it as a downloadable file, not an in-browser game.
**Why it happens:** Butler cannot set the "Playable in browser" flag via CLI — it must be set manually on the itch.io Edit page.
**How to avoid:** After first push, go to itch.io > Edit game > Uploads, find the html5 channel entry, and check "This file will be played in the browser."
**Warning signs:** itch.io page shows a download button instead of a Play button.

### Pitfall 5: GitHub remote not configured
**What goes wrong:** `gh release create` fails with "no git remotes found".
**Why it happens:** The dicegame repo has no remote configured yet (confirmed by checking git config).
**How to avoid:** Before running deploy.sh, run `gh repo create` to create the GitHub repo and push. Then `gh release create` will work.
**Warning signs:** `gh: error: no git remotes found` in deploy.sh output.

### Pitfall 6: deploy.sh invokes luminaldata-www deploy.sh which rebuilds and redeploys the whole site
**What goes wrong:** The luminaldata-www `deploy.sh` does a full `npm run build` + remote rsync/docker deploy. This is a heavy operation that requires SSH access to the production server.
**Why it happens:** That script is designed for full site deploys. Calling it from the game deploy script is appropriate — but the user needs the SSH host `luminaldata-prod` configured in `~/.ssh/config`.
**How to avoid:** Verify SSH config before first run. Alternatively, the game deploy script can commit to the Astro repo and let the user trigger site deploy separately.

### Pitfall 7: Missing export directories
**What goes wrong:** Godot export fails if the output directory doesn't exist.
**Why it happens:** Godot does not auto-create export directories.
**How to avoid:** Create `export/linux/` and `export/windows/` directories before exporting. The deploy script should check these exist (and contain built files) before proceeding.

## Code Examples

### .gitignore extension for new export directories
```gitignore
# Source: matches existing web pattern
# Linux export output
export/linux/

# Windows export output
export/windows/
```

### Verify single-threaded export is working (no COEP needed)
```bash
# Current web preset confirms correct setting:
# variant/thread_support=false  <- already set, do not change
```

### butler version check
```bash
butler version
# Expected: butler version X.Y.Z
```

### gh release syntax with labels
```bash
# Source: https://cli.github.com/manual/gh_release_create
gh release create v1.0.0 \
  'export/linux/steamroller-linux-v1.0.0.zip#Linux x86_64' \
  'export/windows/steamroller-windows-v1.0.0.zip#Windows x86_64' \
  --title "Steamroller v1.0.0"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Godot 4 web exports required COEP/COOP headers (SharedArrayBuffer) | Single-threaded export (thread_support=false) avoids SharedArrayBuffer entirely | Godot 4.3 (2024) | Iframe embedding now works without server header config |
| Linux export platform name `Linux/X11` | Renamed to `Linux` in export_presets.cfg | Godot 4.3 | Old preset configs from Godot 4.2 break silently |
| Separate .pck + binary | `embed_pck=true` single-file binary | Godot 4.x option | Simpler distribution, single file download |

**Deprecated/outdated:**
- `platform="Linux/X11"` preset key: replaced by `platform="Linux"` in Godot 4.3+
- Threaded HTML5 + service worker workaround: now unnecessary for single-threaded builds

## Open Questions

1. **itch.io username for butler commands**
   - What we know: User has an itch.io account; project slug is `steamroller`
   - What's unclear: The exact username is not documented in the context files
   - Recommendation: Planner should leave a placeholder `ITCH_USERNAME` in deploy.sh with a comment to fill in

2. **GitHub repository name and remote**
   - What we know: The local repo has no GitHub remote configured
   - What's unclear: Whether the user wants the repo public or private, and the exact GitHub username/org
   - Recommendation: Deploy script setup task should include `gh repo create` step as prerequisite

3. **SSH access to luminaldata-prod for Astro deploy**
   - What we know: luminaldata-www/deploy.sh SSHes to `luminaldata-prod` host
   - What's unclear: Whether the user's current WSL2 environment has the SSH key configured
   - Recommendation: Treat this as a prerequisite check in the deploy task; provide an alternative "manual Astro deploy" fallback path

4. **itch.io game page creation**
   - What we know: The user has an itch.io account; project slug is `steamroller`
   - What's unclear: Whether the game page has been created yet (butler push to a non-existent page will fail)
   - Recommendation: Plan should include a task to create the itch.io game page before running deploy.sh

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual verification (no automated test framework) |
| Config file | none |
| Quick run command | n/a — manual smoke tests |
| Full suite command | n/a |

This phase has no unit-testable logic (it's build/deploy tooling + config files). Validation is through manual smoke tests at the end of each export task.

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EXPORT-01 | HTML5 build loads and plays in browser at target host | smoke | manual | n/a |
| EXPORT-02 | Linux and Windows desktop builds run the full game | smoke | manual | n/a |

### Sampling Rate
- **Per task:** Build file exists and is non-zero size; export paths match export_presets.cfg
- **Phase gate:** Full manual smoke test on each platform before marking phase complete

### Wave 0 Gaps
- [ ] `export/linux/` directory — must be created before Godot export
- [ ] `export/windows/` directory — must be created before Godot export
- [ ] butler installed and authenticated — prerequisite for deploy.sh
- [ ] gh CLI installed and authenticated — prerequisite for GitHub Release step
- [ ] GitHub remote configured on dicegame repo — prerequisite for gh release create
- [ ] itch.io game page created at `steamroller` slug — prerequisite for butler push

## Sources

### Primary (HIGH confidence)
- Godot 4.3 Web Export blog post (godotengine.org/article/progress-report-web-export-in-4-3/) — confirmed single-threaded export eliminates COEP requirement
- export_presets.cfg (existing project file) — confirmed `variant/thread_support=false` already set
- butler official docs (itch.io/docs/butler/pushing.html) — push syntax, channel naming
- butler login docs (itch.io/docs/butler/login.html) — BUTLER_API_KEY env var, credential location
- gh CLI manual (cli.github.com/manual/gh_release_create) — release create syntax

### Secondary (MEDIUM confidence)
- crystal-bit/godot-game-template export_presets.cfg — verified Linux/Windows preset format with embed_pck=true
- Godot GitHub issue #89012 — confirmed platform rename from "Linux/X11" to "Linux" in Godot 4.3
- luminaldata-www/src/content.config.ts (project file) — confirmed blog post frontmatter schema
- luminaldata-www/src/pages/blog/[...slug].astro — confirmed markdown-based blog route structure
- rafa.ee/articles/deploying-godot-4-html-exports/ — COEP header context

### Tertiary (LOW confidence)
- nisovin gist on Godot/itch.io/SharedArrayBuffer — historical context; superseded by Godot 4.3 single-threaded export

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — tools are all official/well-documented; project config already partially in place
- Architecture: HIGH — export preset format verified against real project examples; butler commands from official docs
- Pitfalls: HIGH — HTML5 iframe issue verified from official Godot 4.3 release notes + existing project config already handles it

**Research date:** 2026-03-14
**Valid until:** 2026-09-14 (stable tools; Godot export format is stable within 4.x)
