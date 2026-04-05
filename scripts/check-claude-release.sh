#!/usr/bin/env bash
# check-claude-release.sh
#
# Checks npm registry for new @anthropic-ai/claude-code releases.
#
# Exit codes:
#   0 — new version detected (prints version to stdout)
#   1 — no new version (current matches last known)
#   2 — error fetching version
#
# No jq dependency — uses grep/cut for JSON parsing.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KNOWN_VERSION_FILE="${SCRIPT_DIR}/last-known-claude-version.txt"
PACKAGE="@anthropic-ai/claude-code"
REGISTRY_URL="https://registry.npmjs.org/${PACKAGE}/latest"

# Read last known version
if [ -f "${KNOWN_VERSION_FILE}" ]; then
  LAST_KNOWN="$(cat "${KNOWN_VERSION_FILE}" | tr -d '[:space:]')"
else
  LAST_KNOWN="unknown"
fi

# Fetch latest version from npm registry (no jq — use grep/cut)
HTTP_RESPONSE="$(curl -sf --max-time 30 "${REGISTRY_URL}" 2>/dev/null)" || {
  echo "ERROR: Failed to fetch version from npm registry" >&2
  exit 2
}

# Extract "version" field from JSON response
LATEST_VERSION="$(echo "${HTTP_RESPONSE}" | grep -oE '"version"\s*:\s*"[^"]+"' | head -1 | cut -d'"' -f4)"

if [ -z "${LATEST_VERSION}" ]; then
  echo "ERROR: Could not parse version from registry response" >&2
  exit 2
fi

# Compare versions
if [ "${LATEST_VERSION}" = "${LAST_KNOWN}" ]; then
  # No new version
  exit 1
else
  # New version found — print it and exit 0
  echo "${LATEST_VERSION}"
  exit 0
fi
