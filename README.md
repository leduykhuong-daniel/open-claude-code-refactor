<h1 align="center">Open Claude Code</h1>
<h3 align="center">Open Source Claude Code CLI — Reverse Engineered & Rebuilt</h3>

<p align="center">
  <em>The open source implementation of Anthropic's Claude Code CLI,<br/>
  built from decompiled source intelligence using <a href="https://github.com/ruvnet/rudevolution">ruDevolution</a>.</em>
</p>

<p align="center">
  <img alt="Node.js" src="https://img.shields.io/badge/Node.js-18%2B-brightgreen?style=flat-square" />
  <img alt="License" src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" />
  <img alt="Status" src="https://img.shields.io/badge/v2-coming_soon-purple?style=flat-square" />
  <img alt="Based on" src="https://img.shields.io/badge/based_on-Claude_Code_v2.1.91-orange?style=flat-square" />
</p>

---

## 🔥 Background: The Claude Code Source Leak

On March 31, 2026, Anthropic accidentally shipped source maps in the Claude Code npm package, exposing the full TypeScript source. The leak revealed:

- **KAIROS** — an autonomous agent system that works without user input
- **Undercover Mode** — hides AI involvement in commits from Anthropic employees
- **Internal tools** (TungstenTool, SendUserFileTool, PushNotificationTool)
- **22 private repository names**
- **Animal codenames** for unreleased models

Anthropic patched it within hours, but the architecture was documented by [Sabrina Ramonov](https://www.sabrina.dev/p/claude-code-source-leak-analysis) and others.

**This project takes a different approach.** Instead of relying on leaked source, we use [ruDevolution](https://github.com/ruvnet/rudevolution) — an AI-powered decompiler — to analyze the **published npm package** legally, and rebuild an open source version from that intelligence.

## 📦 What Is This?

**Open Claude Code** is a clean-room open source implementation of the Claude Code CLI architecture. It's not a copy of Anthropic's code — it's a ground-up rebuild informed by decompilation analysis of the published binary.

### v1 (Current — 2025)

The original implementation with basic WASM terminal UI, conversation management, and Claude API integration. Built before the decompilation intelligence was available.

### v2 (Coming Soon — 2026)

A complete rewrite based on [ruDevolution's decompilation](https://github.com/ruvnet/rudevolution/releases) of Claude Code v2.1.91 (34,759 declarations, 981 modules). The v2 architecture mirrors the actual Claude Code internals:

- **Async generator agent loop** — 13 event types, recursive after tool execution
- **25+ built-in tools** — Bash, Read, Edit, Write, Glob, Grep, Agent, WebFetch
- **6 permission modes** — bypassPermissions, acceptEdits, auto, default, dontAsk, plan
- **MCP client** — stdio, SSE, Streamable HTTP transports
- **Hooks system** — PreToolUse, PostToolUse, Stop events
- **Settings chain** — user/project/local/managed
- **Context compaction** — automatic context window management
- **Custom agents & skills** — extensible AI personas

[Preview the v2 source →](./v2/)

## 🔍 What ruDevolution Found in Claude Code

Our decompiler discovered capabilities Anthropic hasn't publicly announced:

| Discovery | Evidence |
|-----------|---------|
| 🤖 **Agent Teams** | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`, `TEAMMATE_COMMAND` |
| 🌙 **Auto Dream Mode** | `tengu_auto_dream_completed` — works while you sleep |
| 🔮 **claude-opus-4-6** | Unreleased model ID (current public is 4.5) |
| 🔮 **claude-sonnet-4-6** | Unreleased model ID |
| 🔐 **6 "amber" codenames** | `amber_flint`, `amber_prism`, `amber_stoat`, `amber_wren` |
| 🧰 **Advisor Tool** | `tengu_advisor_tool_call` — new tool type |
| 🧰 **Agentic Search** | Search that spawns sub-agents |
| ☁️ **CCR (Cloud Code Runner)** | Full cloud execution with BYOC |
| 🎮 **Powerups** | Gamification with unlockable abilities |
| 📡 **MCP Streamable HTTP** | New transport replacing SSE |
| 📱 **Chrome Extension** | Extension ID: `fcoeoabgfenejglbffodgkkbkcdhcgfn` |
| 🎙️ **Native Audio** | Voice input capability |
| **117 new env vars** | Since v2.0 |

[Download decompiled releases →](https://github.com/ruvnet/rudevolution/releases)

## ⚡ Quick Start

### v1 (Current)

```bash
git clone https://github.com/ruvnet/open-claude-code.git
cd open-claude-code/open_claude_code/src
npm install
ANTHROPIC_API_KEY=your-key node index.mjs
```

### v2 (Preview)

```bash
cd open-claude-code/v2
ANTHROPIC_API_KEY=your-key node src/index.mjs "explain this codebase"
```

### Decompile Claude Code Yourself

```bash
npx ruvector decompile @anthropic-ai/claude-code
```

## 🏗️ v2 Architecture

```
v2/src/
├── core/
│   └── agent-loop.mjs        # Async generator (13 event types)
├── tools/
│   ├── registry.mjs           # validateInput/call interface
│   ├── bash.mjs, read.mjs     # Built-in tools
│   ├── edit.mjs, write.mjs
│   └── glob.mjs, grep.mjs
├── permissions/
│   └── checker.mjs            # 6 permission modes
├── config/
│   ├── settings.mjs           # User/project/local chain
│   └── cli-args.mjs
└── index.mjs                  # Entry point
```

## ⚖️ Legal

This project is a **clean-room implementation** — not a copy of Anthropic's source code. The architecture is informed by analysis of the **published npm package** using [ruDevolution](https://github.com/ruvnet/rudevolution), which is legal under:

- 🇺🇸 US DMCA §1201(f) — reverse engineering for interoperability
- 🇪🇺 EU Software Directive Art. 6 — decompilation for interoperability
- 🇬🇧 UK CDPA §50B — decompilation for interoperability

No leaked source code was used. No DRM was bypassed. No proprietary code was copied.

## 🔗 Related

- [ruDevolution](https://github.com/ruvnet/rudevolution) — The AI-powered decompiler used to analyze Claude Code
- [Decompiled Claude Code Releases](https://github.com/ruvnet/rudevolution/releases) — Every major version decompiled
- [Sabrina Ramonov's Leak Analysis](https://www.sabrina.dev/p/claude-code-source-leak-analysis) — Coverage of the March 2026 source leak

## 📄 License

MIT
