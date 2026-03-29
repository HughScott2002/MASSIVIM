#!/usr/bin/env bash
# MASSIVIM release — auto-version, changelog, tag, and push
set -euo pipefail

cd "$(dirname "$0")"

# --- Determine bump type ---
BUMP="${1:-patch}"  # patch (default), minor, or major

if [[ ! "$BUMP" =~ ^(patch|minor|major)$ ]]; then
  echo "Usage: ./release.sh [patch|minor|major]"
  echo "  patch — bug fixes, tweaks (1.0.0 → 1.0.1)"
  echo "  minor — new plugins, features (1.0.0 → 1.1.0)"
  echo "  major — breaking changes (1.0.0 → 2.0.0)"
  exit 1
fi

# --- Get current version from latest git tag ---
CURRENT=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
CURRENT="${CURRENT#v}"

IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"

case $BUMP in
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  patch) PATCH=$((PATCH + 1)) ;;
esac

NEW_VERSION="v${MAJOR}.${MINOR}.${PATCH}"

# --- Check for uncommitted changes ---
if [ -n "$(git status --porcelain)" ]; then
  echo "Staging and committing changes..."
  git add -A
  git commit -m "update config — ${NEW_VERSION}"
fi

# --- Check there are commits since last tag ---
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -n "$LAST_TAG" ]; then
  COMMITS=$(git log "${LAST_TAG}..HEAD" --oneline 2>/dev/null)
  if [ -z "$COMMITS" ]; then
    echo "No changes since ${LAST_TAG}. Nothing to release."
    exit 0
  fi
fi

# --- Generate changelog entry ---
DATE=$(date +%Y-%m-%d)
CHANGELOG_FILE="CHANGELOG.md"

# Build the entry from commit messages since last tag
ENTRY="## ${NEW_VERSION} — ${DATE}\n\n"

if [ -n "$LAST_TAG" ]; then
  while IFS= read -r line; do
    ENTRY+="- ${line#* }\n"
  done <<< "$(git log "${LAST_TAG}..HEAD" --oneline --no-decorate)"
else
  while IFS= read -r line; do
    ENTRY+="- ${line#* }\n"
  done <<< "$(git log --oneline --no-decorate)"
fi

ENTRY+="\n"

# Create or prepend to CHANGELOG.md
if [ -f "$CHANGELOG_FILE" ]; then
  EXISTING=$(cat "$CHANGELOG_FILE")
  printf "# MASSIVIM Changelog\n\n%b%s" "$ENTRY" "$(echo "$EXISTING" | tail -n +3)" > "$CHANGELOG_FILE"
else
  printf "# MASSIVIM Changelog\n\n%b" "$ENTRY" > "$CHANGELOG_FILE"
fi

# --- Commit changelog, tag, and push ---
git add CHANGELOG.md
git commit -m "release ${NEW_VERSION}"
git tag -a "$NEW_VERSION" -m "${NEW_VERSION}"
git push origin main --tags

echo ""
echo "=== Released ${NEW_VERSION} ==="
echo "https://github.com/HughScott2002/MASSIVIM/releases/tag/${NEW_VERSION}"
