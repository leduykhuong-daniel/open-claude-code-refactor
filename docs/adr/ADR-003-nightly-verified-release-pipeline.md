# ADR-003: Nightly Verified Release Pipeline

**Status**: Accepted
**Date**: 2026-04-04
**Deciders**: rUv
**Tags**: ci, nightly, release, verification, pipeline

## Context

open-claude-code tracks upstream Claude Code releases from Anthropic (`@anthropic-ai/claude-code` on npm). When Anthropic ships a new version, we need to:

1. Detect the release promptly
2. Verify our implementation still works against the new baseline
3. Analyze what changed (new features, breaking changes, security updates)
4. Publish a verified nightly build that users and integrators can trust

Previously this was a manual process: someone would notice a new release, run tests locally, and cut a tag. This does not scale and introduces human error. We need an automated pipeline with hard verification gates that blocks releases if quality standards slip.

### Constraints

- The test suite (`node v2/test/test.mjs`) must pass with 903+ tests
- No high or critical npm audit vulnerabilities
- All `.mjs` source files must be syntactically valid
- The CLI entry point must load without crashing
- AI analysis is valuable but must not block releases when the API key is unavailable
- No secrets may appear in logs or release notes
- GitHub Actions versions must be pinned to major versions for security

## Decision

Implement a 4-phase nightly verified release pipeline as a GitHub Actions workflow, triggered on a cron schedule (03:00 UTC daily) and by manual dispatch.

### Architecture

```
                    +---------------------+
                    |   Nightly Trigger    |
                    |  (03:00 UTC cron)    |
                    |  + manual dispatch   |
                    +----------+----------+
                               |
                    +----------v----------+
                    |   Phase 1: DETECT   |
                    |                     |
                    | npm registry query  |
                    | @anthropic-ai/      |
                    |   claude-code       |
                    | vs last-known-      |
                    |   claude-version.txt|
                    +----------+----------+
                               |
                    new version? (or force)
                               |
                    +----------v----------+
                    |   Phase 2: VERIFY   |
                    |                     |
                    | +-- Test Suite ----+|
                    | |  903+ passing    ||
                    | +-----------------+|
                    | +-- npm audit ----+|
                    | |  no high/crit   ||
                    | +-----------------+|
                    | +-- Lint ---------+|
                    | |  syntax valid   ||
                    | +-----------------+|
                    | +-- Smoke Test ---+|
                    | |  CLI boots      ||
                    | +-----------------+|
                    +----------+----------+
                               |
                         ALL gates pass
                               |
              +----------------+----------------+
              |                                 |
   +----------v----------+           +----------v----------+
   |  Phase 3: ANALYZE   |           |  Phase 4: RELEASE   |
   |   (optional)        |           |                     |
   | Claude Sonnet 4.6   |           | Tag: v2.X.Y-nightly |
   | Diff analysis       |           |   .YYYYMMDD         |
   | rudevolution data   |           | Release notes       |
   | Feature discovery   |           | gh release create   |
   +---------------------+           +---------------------+
                                              |
                                     +--------v--------+
                                     | Update version  |
                                     | tracker file    |
                                     +-----------------+

   On failure (any phase):
   +---------------------+
   | Open GitHub Issue   |
   | with investigation  |
   | link and checklist  |
   +---------------------+
```

### Phase Details

#### Phase 1: Detect

- Script: `scripts/check-claude-release.sh`
- Queries `https://registry.npmjs.org/@anthropic-ai/claude-code/latest`
- Compares against `scripts/last-known-claude-version.txt`
- No `jq` dependency (uses `grep`/`cut` for JSON parsing)
- Exit code protocol: 0 = new version, 1 = same, 2 = error
- Supports `force_release` workflow dispatch input to bypass detection

#### Phase 2: Verify

All four gates run sequentially within a single job. If any gate fails, the job fails and the release is blocked.

| Gate | Command | Pass Criteria |
|------|---------|---------------|
| Test suite | `node v2/test/test.mjs` | 0 failures, 903+ passing |
| Security audit | `npm audit --audit-level=high` | Exit code 0 |
| Syntax lint | `node --check` on all `.mjs` files | No syntax errors |
| Smoke test | `node v2/src/index.mjs --version` | Process starts without crash |

#### Phase 3: Analyze (Optional)

- Script: `scripts/analyze-discoveries.sh`
- Requires `ANTHROPIC_API_KEY` secret (gracefully skipped if absent)
- Uses `claude-sonnet-4-6-20250514` model
- Gathers rudevolution submodule data if present
- Produces markdown summary: new features, breaking changes, security changes, architecture changes
- Result uploaded as artifact and embedded in release notes

#### Phase 4: Release

- Tag format: `v2.0.0-nightly.YYYYMMDD`
- Script: `scripts/generate-release-notes.sh`
- Notes include: verification table, version comparison, discovery analysis, links
- Published as prerelease via `gh release create`
- Updates `scripts/last-known-claude-version.txt` and commits the change

### Failure Handling

When any phase fails, the `on-failure` job:
1. Checks for an existing open issue labeled `nightly-failure`
2. If found, adds a comment with the new failure details
3. If not found, creates a new issue with investigation checklist and links

## Verification Gates

The pipeline enforces these hard gates:

```
MUST PASS:
  [x] Test suite:      node v2/test/test.mjs  ->  903+ passing, 0 failing
  [x] Security audit:  npm audit --audit-level=high  ->  exit 0
  [x] Syntax lint:     node --check *.mjs  ->  all files valid
  [x] Smoke test:      CLI entry point loads  ->  process starts

OPTIONAL (does not block release):
  [ ] AI analysis:     Claude Sonnet 4.6 discovery  ->  enhances release notes
```

## Security Constraints

1. **No secrets in logs**: The `ANTHROPIC_API_KEY` is only used in the analyze phase, passed via environment variable, never echoed
2. **Pinned actions**: All GitHub Actions are pinned to major versions (`@v4`)
3. **Minimal permissions**: Only `contents: write` (for releases/tags) and `issues: write` (for failure issues)
4. **npm audit gate**: Blocks release on high/critical vulnerabilities
5. **No arbitrary code execution**: Scripts use `set -euo pipefail` and validate inputs

## Release Tag Format

```
v{package-version}-nightly.{YYYYMMDD}

Examples:
  v2.0.0-nightly.20260404
  v2.0.0-nightly.20260405
  v2.1.0-nightly.20260410
```

The package version comes from `v2/package.json`. The date suffix ensures uniqueness for daily builds.

## Consequences

### Positive

- Automated detection of upstream releases within 24 hours
- Every release is verified by 4 independent quality gates
- AI-powered change analysis provides insight into upstream evolution
- Failure issues ensure problems are tracked and not silently ignored
- Manual dispatch with `force_release` allows ad-hoc releases
- No external dependencies beyond npm registry and GitHub Actions

### Negative

- Nightly runs consume GitHub Actions minutes even when no new version exists (mitigated by fast Phase 1 exit)
- AI analysis depends on an external API key that may not always be configured
- The `last-known-claude-version.txt` commit creates noise in git history
- Version detection relies on npm registry availability

### Neutral

- Release notes quality depends on AI analysis availability
- The pipeline does not publish to npm (only GitHub releases) — npm publishing can be added later
- Test count threshold (903+) may need adjustment as the test suite grows

## Files

| File | Purpose |
|------|---------|
| `.github/workflows/nightly.yml` | GitHub Actions workflow (4 phases) |
| `scripts/check-claude-release.sh` | Phase 1: npm registry version check |
| `scripts/generate-release-notes.sh` | Phase 4: release notes generator |
| `scripts/analyze-discoveries.sh` | Phase 3: AI-powered change analysis |
| `scripts/last-known-claude-version.txt` | Version tracker (updated by pipeline) |

## References

- [ADR-001: v2 Architecture](./ADR-001-v2-architecture.md)
- [open-claude-code repository](https://github.com/ruvnet/open-claude-code)
- [ruDevolution](https://github.com/ruvnet/rudevolution)
- [pi.ruv.io Dashboard](https://pi.ruv.io)
- [@anthropic-ai/claude-code on npm](https://www.npmjs.com/package/@anthropic-ai/claude-code)
