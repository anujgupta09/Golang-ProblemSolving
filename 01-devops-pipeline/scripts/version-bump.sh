#!/usr/bin/env bash
# Cut a release: bump the POM version in java-maven-sample-app, push to main, push release-X.Y.Z.
# Usage: bash scripts/version-bump.sh [X.Y.Z]   (steps: ../docs/how-to-cut-a-release.md)
#   No argument: auto-increment the current POM version (patch +1; each part rolls over at 9: 2.0.9 -> 2.1.0, 2.9.9 -> 3.0.0).
#   With X.Y.Z: use that exact version.
# Where the app checkout is: APP_DIR from the environment, else from the .env file
# ($ENV_FILE, else config/.env; same file as one-touch.sh). Only the APP_DIR line is read from it.
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
env_file=${ENV_FILE:-$here/../config/.env}
BRANCH=main

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

# APP_DIR: path to the java-maven-sample-app checkout (POSIX style for Git Bash, e.g. /c/work/java-maven-sample-app).
if [[ -z "${APP_DIR:-}" && -f "$env_file" ]]; then
    APP_DIR=$(sed -n -E "s/^[[:space:]]*APP_DIR=[\"']?([^\"']*)[\"']?[[:space:]]*$/\1/p" "$env_file" | tail -n 1)
fi
[[ -n "${APP_DIR:-}" ]] || fail "APP_DIR is not set. Add APP_DIR=\"/path/to/java-maven-sample-app\" to $env_file (or set ENV_FILE / the APP_DIR variable)."

version=${1:-}
[[ -z "$version" || "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail 'Usage: bash scripts/version-bump.sh [X.Y.Z] (e.g. 2.0.0; omit to auto-increment)'

command -v git >/dev/null || fail 'git is required.'
[[ -f "$APP_DIR/pom.xml" ]] || fail "No pom.xml in APP_DIR: $APP_DIR"
cd "$APP_DIR"

[[ "$(git rev-parse --abbrev-ref HEAD)" == "$BRANCH" ]] || fail "Check out $BRANCH in $APP_DIR first."
[[ -z "$(git status --porcelain)" ]] || fail 'Working tree not clean; commit or stash changes first.'
git fetch origin "$BRANCH" --tags --quiet
[[ "$(git rev-parse HEAD)" == "$(git rev-parse "origin/$BRANCH")" ]] || fail "Local $BRANCH differs from origin/$BRANCH; pull/push first."

# Only the project <version> (first one after </parent>) changes, never the Spring Boot parent's.
current=$(awk '/<\/parent>/{p=1} p && /<version>/{gsub(/.*<version>|<\/version>.*/,""); print; exit}' pom.xml)
[[ -n "$current" ]] || fail 'Could not find the project <version> in pom.xml.'
[[ "$current" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] || fail "POM version '$current' is not plain X.Y.Z; pass the new version explicitly."

if [[ -z "$version" ]]; then
    major=${BASH_REMATCH[1]} minor=${BASH_REMATCH[2]} patch=$(( ${BASH_REMATCH[3]} + 1 ))
    if (( patch > 9 )); then patch=0; minor=$(( minor + 1 )); fi
    if (( minor > 9 )); then minor=0; major=$(( major + 1 )); fi
    version="$major.$minor.$patch"
fi
tag="release-$version"

[[ "$current" != "$version" ]] || fail "pom.xml is already at $version."
git rev-parse -q --verify "refs/tags/$tag" >/dev/null && fail "Tag $tag already exists locally."
remote_tags=$(git ls-remote --tags origin "refs/tags/$tag") || fail 'Could not query origin for existing tags (network/credentials?).'
[[ -z "$remote_tags" ]] || fail "Tag $tag already exists on origin."

trap 'rm -f pom.xml.new' EXIT
awk -v v="$version" '
    /<\/parent>/ { p = 1 }
    p && !done && /<version>/ { sub(/<version>[^<]*<\/version>/, "<version>" v "</version>"); done = 1 }
    { print }
' pom.xml > pom.xml.new && mv pom.xml.new pom.xml

# Read it back: never commit a POM whose version is not the one we meant to write.
written=$(awk '/<\/parent>/{p=1} p && /<version>/{gsub(/.*<version>|<\/version>.*/,""); print; exit}' pom.xml)
if [[ "$written" != "$version" ]]; then
    git checkout -- pom.xml
    fail "pom.xml now says '$written', expected '$version'. pom.xml was restored; nothing committed."
fi
git diff --stat -- pom.xml

printf 'Bumping %s -> %s\n' "$current" "$version"
git add pom.xml
git commit -m "Bump version to $version" \
    || { git restore --staged --worktree pom.xml; fail 'git commit failed (hook?). pom.xml was restored; nothing committed.'; }
git push origin "$BRANCH" \
    || fail "Push of $BRANCH failed. The bump commit exists locally but is NOT pushed and no tag was created. Fix the cause, then: git push origin $BRANCH && git tag $tag && git push origin $tag"   # ancestry gate: tagged commit must be on origin/main
git tag "$tag"
git push origin "$tag" \
    || fail "Push of tag $tag failed ($BRANCH is already pushed). Fix the cause, then: git push origin $tag"   # fires the webhook

printf 'Done: pushed %s and %s. Verify in Jenkins job vdx-release.\n' "$BRANCH" "$tag"
