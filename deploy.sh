#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Steamroller — one-command release script
#
# Prerequisites (run once before first deploy):
#   1. Export from Godot editor: Project > Export > Export All
#      (creates export/web/, export/linux/, export/windows/ build files)
#   2. Install and authenticate butler: butler login
#   3. Install and authenticate gh CLI: gh auth login
#   4. Configure GitHub remote: gh repo create (or git remote add origin ...)
#   5. Create itch.io game page at https://itch.io/game/new with slug "steamroller"
#   6. Set ITCH_USERNAME below to your itch.io username
#   7. Ensure luminaldata-prod SSH host is configured in ~/.ssh/config
#
# Usage: bash deploy.sh
# =============================================================================

# --- Configuration ---
ASTRO_REPO="/home/jlarson/code/luminaldata-www"
ITCH_USERNAME="ITCH_USERNAME"  # TODO: replace with your actual itch.io username
GAME_SLUG="steamroller"
GAME_REPO_DIR="$(pwd)"

# --- Version auto-increment ---
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.9.9")
IFS='.' read -r MAJOR MINOR PATCH <<< "${LAST_TAG#v}"
VERSION="v${MAJOR}.${MINOR}.$((PATCH + 1))"
echo "==> Releasing ${VERSION}"

# --- Validate export builds exist ---
echo "==> Validating export builds..."
if [[ ! -f "export/web/index.html" ]]; then
  echo "ERROR: Web build missing at export/web/index.html"
  echo "       Export from Godot: Project > Export > Export All"
  exit 1
fi
if [[ ! -f "export/linux/steamroller.x86_64" ]]; then
  echo "ERROR: Linux build missing at export/linux/steamroller.x86_64"
  echo "       Export from Godot: Project > Export > Export All"
  exit 1
fi
if [[ ! -f "export/windows/steamroller.exe" ]]; then
  echo "ERROR: Windows build missing at export/windows/steamroller.exe"
  echo "       Export from Godot: Project > Export > Export All"
  exit 1
fi
echo "    All export builds present."

# --- Validate required tools ---
echo "==> Validating required tools..."
if ! command -v butler &>/dev/null; then
  echo "ERROR: butler not found on PATH."
  echo "       Install: curl -L -o /tmp/butler.zip https://broth.itch.zone/butler/linux-amd64/LATEST/archive/default"
  echo "                unzip /tmp/butler.zip -d ~/bin/ && chmod +x ~/bin/butler"
  echo "       Authenticate: butler login"
  exit 1
fi
if ! command -v gh &>/dev/null; then
  echo "ERROR: gh CLI not found on PATH."
  echo "       Install: sudo apt install gh  (or https://cli.github.com/)"
  echo "       Authenticate: gh auth login"
  exit 1
fi
if ! gh auth status &>/dev/null; then
  echo "ERROR: gh CLI is not authenticated."
  echo "       Run: gh auth login"
  exit 1
fi
if [[ "${ITCH_USERNAME}" == "ITCH_USERNAME" ]]; then
  echo "ERROR: ITCH_USERNAME not set in deploy.sh."
  echo "       Edit deploy.sh line 20 and replace ITCH_USERNAME with your itch.io username."
  exit 1
fi
echo "    All tools validated."

# --- Step 1: Copy HTML5 build to Astro repo ---
echo ""
echo "==> [1/5] Copying HTML5 build to Astro repo..."
if [[ ! -d "${ASTRO_REPO}" ]]; then
  echo "ERROR: Astro repo not found at ${ASTRO_REPO}"
  exit 1
fi
mkdir -p "${ASTRO_REPO}/public/games/steamroller"
cp export/web/* "${ASTRO_REPO}/public/games/steamroller/"
cd "${ASTRO_REPO}"
git add public/games/steamroller/
git commit -m "feat: update Steamroller HTML5 build to ${VERSION}" || true
git push origin main
cd "${GAME_REPO_DIR}"
echo "    HTML5 files copied and pushed to Astro repo."

# --- Step 2: Deploy Astro site ---
echo ""
echo "==> [2/5] Deploying luminaldata-www Astro site..."
echo "    Note: requires SSH access to luminaldata-prod (configured in ~/.ssh/config)"
cd "${ASTRO_REPO}"
bash deploy.sh
cd "${GAME_REPO_DIR}"
echo "    Astro site deployed."

# --- Step 3: Push builds to itch.io via butler ---
echo ""
echo "==> [3/5] Pushing builds to itch.io (${ITCH_USERNAME}/${GAME_SLUG})..."
butler push "export/web/"      "${ITCH_USERNAME}/${GAME_SLUG}:html5"   --userversion "${VERSION#v}"
butler push "export/linux/"    "${ITCH_USERNAME}/${GAME_SLUG}:linux"   --userversion "${VERSION#v}"
butler push "export/windows/"  "${ITCH_USERNAME}/${GAME_SLUG}:windows" --userversion "${VERSION#v}"
echo "    Builds pushed to itch.io."
echo "    NOTE: After first html5 push, go to itch.io > Edit game > Uploads"
echo "          and check 'This file will be played in the browser' on the html5 channel."

# --- Step 4: Package builds for GitHub Release ---
echo ""
echo "==> [4/5] Packaging desktop builds for GitHub Release..."
RELEASE_TMP=$(mktemp -d)
LINUX_ZIP="${RELEASE_TMP}/steamroller-linux-${VERSION}.zip"
WINDOWS_ZIP="${RELEASE_TMP}/steamroller-windows-${VERSION}.zip"
zip -j "${LINUX_ZIP}"   "export/linux/steamroller.x86_64"
zip -j "${WINDOWS_ZIP}" "export/windows/steamroller.exe"
echo "    Packaged: $(basename "${LINUX_ZIP}")"
echo "    Packaged: $(basename "${WINDOWS_ZIP}")"

# --- Step 5: Create GitHub Release ---
echo ""
echo "==> [5/5] Creating GitHub Release ${VERSION}..."
git tag "${VERSION}"
git push origin "${VERSION}"
gh release create "${VERSION}" \
  "${LINUX_ZIP}#Linux x86_64" \
  "${WINDOWS_ZIP}#Windows x86_64" \
  --title "Steamroller ${VERSION}" \
  --notes "Play in browser: https://luminaldata.com/games/steamroller

Download links below for Linux (x86_64) and Windows desktop builds."
echo "    GitHub Release ${VERSION} created."

# --- Cleanup ---
rm -rf "${RELEASE_TMP}"

# --- Summary ---
echo ""
echo "======================================================"
echo " Steamroller ${VERSION} released!"
echo "======================================================"
echo " Play:         https://luminaldata.com/games/steamroller"
echo " itch.io:      https://${ITCH_USERNAME}.itch.io/${GAME_SLUG}"
echo " GitHub:       https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/releases/tag/${VERSION}"
echo "======================================================"
