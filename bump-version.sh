#!/usr/bin/env bash
set -euo pipefail

FILE="Sources/narya/Core/Configuration.swift"

if [[ ! -f "$FILE" ]]; then
    echo "Error: file not found: $FILE" >&2
    exit 1
fi

# macOS/BSD date
today="$(date +%Y%m%d)" # e.g. 20260102

# Extract current version value from: static let version = "0.3.1"
current="$(
    awk -F'"' '
    $0 ~ /static[[:space:]]+let[[:space:]]+version[[:space:]]*=/ {
      if (NF >= 2) { print $2; exit }
    }
  ' "$FILE"
)"

if [[ -z "${current:-}" ]]; then
    echo "Error: could not find version line in $FILE" >&2
    exit 1
fi

new=""
# If current is already day-semver for today, bump the minor
if [[ "$current" =~ ^([0-9]{8})\.([0-9]+)$ ]]; then
    base="${BASH_REMATCH[1]}"
    minor="${BASH_REMATCH[2]}"
    if [[ "$base" == "$today" ]]; then
        new="${today}.$((minor + 1))"
    else
        new="${today}.0"
    fi
else
    # Not day-semver, reset to today's base
    new="${today}.0"
fi

# In-place replace the quoted version string on the matching line.
# Use BSD sed's -i '' form for macOS.
sed -i '' -E \
    "s/(static[[:space:]]+let[[:space:]]+version[[:space:]]*=[[:space:]]*\")([^\"]+)(\")/\1${new}\3/" \
    "$FILE"

echo "$new"
