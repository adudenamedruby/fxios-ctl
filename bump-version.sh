#!/usr/bin/env bash
set -euo pipefail

FILE="Sources/narya/Core/Configuration.swift"

die() {
    echo "Error: $*" >&2
    exit 1
}

[[ -f "$FILE" ]] || die "file not found: $FILE"
command -v git >/dev/null 2>&1 || die "git not found"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "not inside a git repo"

today="$(date +%Y%m%d)" # macOS/BSD date

# Extract current version value from: static let version = "0.3.1"
current="$(
    awk -F'"' '
    $0 ~ /static[[:space:]]+let[[:space:]]+version[[:space:]]*=/ {
      if (NF >= 2) { print $2; exit }
    }
  ' "$FILE"
)"
[[ -n "$current" ]] || die "could not find version line in $FILE"

# Compute new version (day-semver)
if [[ "$current" =~ ^([0-9]{8})\.([0-9]+)$ ]]; then
    base="${BASH_REMATCH[1]}"
    minor="${BASH_REMATCH[2]}"
    if [[ "$base" == "$today" ]]; then
        new="${today}.$((minor + 1))"
    else
        new="${today}.0"
    fi
else
    new="${today}.0"
fi

# Fail if it wouldn't change
[[ "$new" != "$current" ]] || die "version already '$current' (no change)"

# Update file (BSD sed -i '' for macOS)
sed -i '' -E \
    "s/(static[[:space:]]+let[[:space:]]+version[[:space:]]*=[[:space:]]*\")([^\"]+)(\")/\1${new}\3/" \
    "$FILE"

# Verify the replacement actually happened
updated="$(
    awk -F'"' '
    $0 ~ /static[[:space:]]+let[[:space:]]+version[[:space:]]*=/ {
      if (NF >= 2) { print $2; exit }
    }
  ' "$FILE"
)"
[[ "$updated" == "$new" ]] || die "failed to update version (still '$updated')"

tag="v${new}"

# Ensure tag doesn't already exist (locally or on origin)
if git rev-parse -q --verify "refs/tags/${tag}" >/dev/null; then
    die "git tag '${tag}' already exists locally"
fi
if git ls-remote --tags origin "refs/tags/${tag}" | grep -q .; then
    die "git tag '${tag}' already exists on origin"
fi

jj commit -m "Release ${tag}"
jj push -m

# Create and push tag
git tag "${tag}"
git push origin "${tag}"

echo "version updated to $new"
