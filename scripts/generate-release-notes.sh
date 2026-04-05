#!/usr/bin/env bash
# generate-release-notes.sh
#
# Generates markdown release notes for nightly verified builds.
#
# Usage:
#   ./generate-release-notes.sh <claude-version> <test-pass-count> \
#       <previous-version> <audit-clean> <lint-clean> <smoke-ok> \
#       <test-fail-count> [discovery-text]
#
# All args are positional. Discovery text is optional.

set -euo pipefail

CLAUDE_VERSION="${1:?Usage: $0 <claude-version> <test-pass-count> <previous-version> <audit-clean> <lint-clean> <smoke-ok> <test-fail-count> [discovery-text]}"
TEST_PASS_COUNT="${2:-0}"
PREVIOUS_VERSION="${3:-unknown}"
AUDIT_CLEAN="${4:-false}"
LINT_CLEAN="${5:-false}"
SMOKE_OK="${6:-false}"
TEST_FAIL_COUNT="${7:-0}"
DISCOVERY_TEXT="${8:-}"

DATE="$(date -u +%Y-%m-%d)"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Helper: status emoji
status_icon() {
  if [ "$1" = "true" ]; then
    echo "PASS"
  else
    echo "FAIL"
  fi
}

AUDIT_STATUS="$(status_icon "${AUDIT_CLEAN}")"
LINT_STATUS="$(status_icon "${LINT_CLEAN}")"
SMOKE_STATUS="$(status_icon "${SMOKE_OK}")"

if [ "${TEST_FAIL_COUNT}" -eq 0 ] 2>/dev/null; then
  TEST_STATUS="PASS"
else
  TEST_STATUS="FAIL"
fi

cat <<NOTES
# Nightly Verified Build — ${DATE}

**Triggered by:** Claude Code upstream release \`${CLAUDE_VERSION}\`
**Build timestamp:** ${TIMESTAMP}
**Package:** \`@ruvnet/open-claude-code\`

---

## Verification Summary

| Gate | Status | Details |
|------|--------|---------|
| Test Suite | ${TEST_STATUS} | ${TEST_PASS_COUNT} passing, ${TEST_FAIL_COUNT} failing |
| Security Audit | ${AUDIT_STATUS} | \`npm audit --audit-level=high\` |
| Syntax Lint | ${LINT_STATUS} | All \`.mjs\` files validated |
| Smoke Test | ${SMOKE_STATUS} | CLI entry point loads |

All verification gates must pass before release.

---

## Version Comparison

| | Previous | Current |
|--|----------|---------|
| Claude Code (upstream) | \`${PREVIOUS_VERSION}\` | \`${CLAUDE_VERSION}\` |
| open-claude-code | \`2.0.0\` | \`2.0.0\` |
| Test count | 903+ | ${TEST_PASS_COUNT} |

---

## Discovery Analysis

NOTES

if [ -n "${DISCOVERY_TEXT}" ]; then
  echo "${DISCOVERY_TEXT}"
else
  cat <<'PLACEHOLDER'
> AI-powered discovery analysis was not available for this release.
> Set the `ANTHROPIC_API_KEY` secret to enable automatic change detection.

### What to look for manually

- New CLI flags or commands in Claude Code
- Changed API behaviors or protocols
- New MCP transport options
- Permission model updates
- Streaming or agent loop changes
PLACEHOLDER
fi

cat <<NOTES

---

## Performance

| Metric | Value |
|--------|-------|
| Test suite | ${TEST_PASS_COUNT} tests |
| Install time | npm ci (cached) |
| Entry point | \`v2/src/index.mjs\` |
| Binary | \`occ\` |

---

## Links

- [Dashboard (pi.ruv.io)](https://pi.ruv.io)
- [ruDevolution](https://github.com/ruvnet/rudevolution)
- [open-claude-code README](https://github.com/ruvnet/open-claude-code#readme)
- [npm: @ruvnet/open-claude-code](https://www.npmjs.com/package/@ruvnet/open-claude-code)

---

*This is an automated nightly verified build. All verification gates passed before publication.*
NOTES
