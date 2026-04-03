# ADR-002: Path to 100% Fidelity with Claude Code

## Status

Complete (2026-04-03)

## Date

2026-04-03

## Context

open-claude-code v2 achieves 85% feature coverage and 50% implementation depth against Claude Code v2.1.91. The remaining 50% is not missing features — it's implementation depth, edge case handling, and production polish.

### Current State

| Metric | Value |
|--------|-------|
| Feature coverage | 85% |
| Implementation depth | 50% |
| Code volume | 5,440 lines (vs 34,759 declarations) |
| Tests | 426 passing |
| Tools | 25/25+ |
| MCP transports | 4/4 |
| Slash commands | 38/39 |

## Decision

Close the gap in 5 phases, each independently shippable.

## Phase 1: Tool Depth (50% → 70%)

**Effort: 2 days | Impact: HIGH**

The tools work but lack Claude Code's robustness:

| Tool | Gap | Fix |
|------|-----|-----|
| Bash | No sandbox, no timeout kill, no background | Add bubblewrap/seatbelt sandbox, process group kill, `run_in_background` |
| Read | No image/PDF/notebook rendering | Add file type detection, PDF text extraction, image base64 |
| Edit | No `replace_all`, no validation of uniqueness | Add replace_all flag, check old_string is unique |
| Write | No overwrite protection | Check file exists, require Read first |
| Glob | Uses `find`, not proper glob | Use `glob` npm package or `fast-glob` |
| Grep | Uses shell `grep` | Use ripgrep binary (Claude Code bundles it) |
| Agent | No worktree isolation | Spawn in git worktree for isolation |
| WebFetch | No HTML parsing | Add readability extraction |

### Deliverable
Every tool matches Claude Code's exact input schema and edge case behavior.

## Phase 2: Streaming & Context (70% → 80%)

**Effort: 3 days | Impact: HIGH**

| Component | Gap | Fix |
|-----------|-----|-----|
| Streaming | No thinking block handling, no tool input streaming | Parse all SSE event types (content_block_start/delta/stop, message_delta) |
| Context | Char-based token estimate | Use tiktoken or API counting endpoint |
| Compaction | Basic summary | Implement micro-compaction (remove stale tool results, keep recent) |
| Prompt cache | Basic flag | Track cache_read/creation tokens, optimize CLAUDE.md layout |
| System prompt | Single CLAUDE.md | Load from `~/.claude/CLAUDE.md`, project root, parent dirs, `--add-dir` |

### Deliverable
Streaming shows thinking blocks inline, context stays within limits intelligently, prompt caching reduces costs.

## Phase 3: UI & UX (80% → 90%)

**Effort: 5 days | Impact: MEDIUM**

| Component | Gap | Fix |
|-----------|-----|-----|
| Terminal UI | Basic readline | Migrate to Ink (React for terminal) with Box, Text, Spinner |
| Virtual scroll | None | Implement for long outputs |
| Keybindings | None | Support Escape for interrupt, Ctrl+C for cancel, Tab for complete |
| Syntax highlighting | None | Add highlight.js for code blocks |
| Status bar | None | Show model, tokens used, cost, tool status |
| Progress | None | Spinner during API calls, progress bar for file operations |
| Markdown rendering | None | Render markdown in terminal (bold, italic, code, lists) |

### Deliverable
Visually indistinguishable from Claude Code's terminal UI.

## Phase 4: Security & Auth (90% → 95%)

**Effort: 3 days | Impact: MEDIUM**

| Component | Gap | Fix |
|-----------|-----|-----|
| Sandbox | Stub only | Implement bubblewrap (Linux) and seatbelt (macOS) process isolation |
| Permission prompts | Auto-allow | Interactive yes/no prompts for dangerous operations |
| OAuth | None | Implement OAuth PKCE flow for Anthropic auth |
| MCP OAuth | None | OAuth for MCP server connections |
| Command injection check | None | Validate Bash commands for injection patterns |
| File path sanitization | None | Prevent directory traversal |
| Rate limiting | None | Respect 429 responses with exponential backoff |

### Deliverable
Security-equivalent to Claude Code — can run untrusted prompts safely.

## Phase 5: Advanced Features (95% → 100%)

**Effort: 5 days | Impact: LOW**

| Component | Gap | Fix |
|-----------|-----|-----|
| Agent Teams | None | Implement EXPERIMENTAL_AGENT_TEAMS with teammate discovery |
| KAIROS/Dream | None | Background agent spawning when idle |
| Plugin marketplace | None | Plugin loading from git repos with cache |
| Multi-provider | Basic | Full Bedrock, Vertex, Azure credential flows |
| Telemetry | Stub | OTEL integration with span export |
| 498 env vars | 35 | Add remaining 463 env var handlers |
| Session teleport | None | Transfer session between machines via token |
| Cron scheduling | Stub | Persistent cron with lock files |
| LSP integration | Stub | Language server diagnostics |

### Deliverable
Feature-for-feature identical to Claude Code v2.1.91.

## Timeline

```
Phase 1 (Tools)     ████████░░░░░░░░░░░░  2 days  → 70% depth
Phase 2 (Stream)    ████████████░░░░░░░░  3 days  → 80% depth
Phase 3 (UI)        ████████████████░░░░  5 days  → 90% depth
Phase 4 (Security)  ██████████████████░░  3 days  → 95% depth
Phase 5 (Advanced)  ████████████████████  5 days  → 100% depth
                    Total: 18 days
```

## Metrics to Track

| Metric | Current | Target |
|--------|---------|--------|
| Feature coverage | 85% | 100% |
| Implementation depth | 50% | 100% |
| Code lines | 5,440 | ~15,000 |
| Tests | 426 | 1,000+ |
| Tool schemas match | ~80% | 100% |
| Edge cases handled | ~20% | 90%+ |
| Security audit | None | Pass |

## Key Insight

The last 50% is 3x harder than the first 50%. It's edge cases, error handling, cross-platform compatibility, and UX polish. Each phase delivers independently useful improvements — we don't need 100% to be useful, but we aim for it.

## References

- [ADR-001: v2 Architecture](./ADR-001-v2-architecture.md)
- [ruDevolution Decompilation](https://github.com/ruvnet/rudevolution/releases)
- [Claude Code Research](https://github.com/ruvnet/RuVector/tree/feat/mincut-decompiler/docs/research/claude-code-rvsource)
