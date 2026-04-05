#!/usr/bin/env bash
# analyze-discoveries.sh
#
# Uses Claude API (Sonnet 4.6) to analyze differences between Claude Code versions.
# Outputs markdown summary of discovered changes.
#
# Usage:
#   ANTHROPIC_API_KEY=sk-... ./analyze-discoveries.sh <new_version> <previous_version>
#
# Exit codes:
#   0 — analysis complete (markdown on stdout)
#   1 — API key missing or API call failed (graceful fallback on stderr)

set -euo pipefail

NEW_VERSION="${1:?Usage: $0 <new_version> <previous_version>}"
PREVIOUS_VERSION="${2:?Usage: $0 <new_version> <previous_version>}"
API_KEY="${ANTHROPIC_API_KEY:-}"

if [ -z "${API_KEY}" ]; then
  echo "WARN: ANTHROPIC_API_KEY not set — skipping AI analysis" >&2
  exit 1
fi

# Collect rudevolution context if the submodule is present
RUDEVOLUTION_CONTEXT=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [ -d "${REPO_ROOT}/rudevolution" ]; then
  # Try to gather recent decompilation notes
  NOTES_FILES="$(find "${REPO_ROOT}/rudevolution" -name '*.md' -newer "${REPO_ROOT}/scripts/last-known-claude-version.txt" 2>/dev/null | head -5)"
  if [ -n "${NOTES_FILES}" ]; then
    RUDEVOLUTION_CONTEXT="Recent rudevolution decompilation notes found:
"
    for f in ${NOTES_FILES}; do
      RUDEVOLUTION_CONTEXT="${RUDEVOLUTION_CONTEXT}
--- $(basename "${f}") ---
$(head -50 "${f}")
"
    done
  fi
fi

# Build the prompt
PROMPT="You are analyzing changes between Claude Code versions for the open-claude-code project (an open source implementation).

Previous version: ${PREVIOUS_VERSION}
New version: ${NEW_VERSION}

${RUDEVOLUTION_CONTEXT}

Based on the version numbers and any context provided, analyze what likely changed between these Claude Code releases. Focus on:

1. **New Features** — new CLI commands, flags, tools, or capabilities
2. **Breaking Changes** — API changes, removed features, behavior changes
3. **Security Changes** — permission model updates, auth changes, vulnerability fixes
4. **Architecture Changes** — streaming protocol, agent loop, MCP transport changes
5. **Performance** — speed improvements, memory optimizations

Format your response as concise markdown sections. Be specific where possible, and note when you are inferring vs certain. Keep it under 300 words."

# Call Claude API (Sonnet 4.6)
RESPONSE="$(curl -sf --max-time 60 \
  -X POST "https://api.anthropic.com/v1/messages" \
  -H "content-type: application/json" \
  -H "x-api-key: ${API_KEY}" \
  -H "anthropic-version: 2023-06-01" \
  -d "$(cat <<PAYLOAD
{
  "model": "claude-sonnet-4-6-20250514",
  "max_tokens": 1024,
  "messages": [
    {
      "role": "user",
      "content": $(printf '%s' "${PROMPT}" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')
    }
  ]
}
PAYLOAD
)" 2>/dev/null)" || {
  echo "WARN: Claude API call failed" >&2
  exit 1
}

# Extract the text content from the response (no jq — use python3 which is available on GH Actions)
ANALYSIS="$(echo "${RESPONSE}" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    if 'content' in data and len(data['content']) > 0:
        print(data['content'][0].get('text', ''))
    elif 'error' in data:
        print('API Error: ' + data['error'].get('message', 'unknown'), file=sys.stderr)
        sys.exit(1)
    else:
        print('Unexpected response format', file=sys.stderr)
        sys.exit(1)
except Exception as e:
    print(f'Parse error: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null)" || {
  echo "WARN: Failed to parse Claude API response" >&2
  exit 1
}

if [ -z "${ANALYSIS}" ]; then
  echo "WARN: Empty analysis returned" >&2
  exit 1
fi

# Output the analysis as markdown
cat <<EOF
### AI-Powered Discovery Analysis

**Model:** Claude Sonnet 4.6 (\`claude-sonnet-4-6-20250514\`)
**Compared:** \`${PREVIOUS_VERSION}\` to \`${NEW_VERSION}\`

${ANALYSIS}

---
*Analysis generated automatically. Verify findings against official changelogs.*
EOF
