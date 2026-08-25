# AGENTS.md

Portable entry point for coding agents (GitHub Copilot, OpenCode, Claude Code, Codex, Pi agent etc.).

This repo uses an **AI-augmented delivery kit**. Prefer following the roles/gates below over ad-hoc chat.

## Always read first

1. [docs/process.md](docs/process.md) — how work moves, roles, gates
2. [docs/project-context.md](docs/project-context.md) — this project's stack, layout, conventions, **Quality Thresholds**, and **Delivery Tracker** (Jira / GitHub Issues / Local docs). Create it from [docs/templates/project-context.template.md](docs/templates/project-context.template.md) if it doesn't exist yet.

## Delivery model

```text
 BRD(s) or Story(s) → Stories + Gherkin ACs → Plan (tasks + test cases) → Implement (test-first: unit → integration) → Build-verify → Review → QA
```

- The Orchestrator takes a queue of BRDs, Epics, and/or already-groomed Stories. Whether BA runs depends on **state, not label**: no groomed story yet for this item → BA grooms it first; a groomed story already exists (a BRD groomed in an earlier pass, an Epic with ready stories, or a standalone Jira key/GitHub issue/`docs/stories/**/*.md`) → skip BA, straight to Developer; see `docs/process.md` → Orchestrator for the full lifecycle graph
- Those BRDs (and the PRD/Spec behind them) can be hand-authored, or built with the optional `docs/discovery/` co-authoring agents (`to-prd` → `to-brd` → `architect`) — see Upstream authoring below. The Orchestrator's graph is unchanged either way
- **Spec is law** for API, schema, cache, messaging, FE impact — `docs/architecture.md` governs too, when it exists
- **One BRD = one Epic**; do not split Frontend BRD vs Backend BRD
- **BA grooms each BRD in a fresh context by default** — same context-window-hygiene reasoning as the developer's per-story default below, not the adversarial isolation Reviewer/QA require (see `docs/team/ba.agent.md` → Context)
- **One developer run = one story**, in a fresh context by default (context-window hygiene, not the adversarial isolation Reviewer/QA require — see `docs/process.md` → Developer rules), unless user explicitly asks otherwise
- No guild blackboard — Jira and/or `docs/` are the source of truth

## Roles (`docs/team/`)

| Stage | Role |
|---|---|
| Stories + Gherkin ACs | `ba.agent.md` |
| Implement | `developer.agent.md` |
| Code review | `reviewer.agent.md` |
| AC validation | `qa.agent.md` |

PRD, BRD, and Technical Spec are authored **upstream of this pipeline** — by hand against `docs/templates/prd.template.md`, `brd.template.md`, and `spec.template.md`, or with the optional co-authoring agents below. Either way they're the same artifacts; the pipeline above doesn't care how they were produced.

## Upstream authoring (optional, human-driven — `docs/discovery/`)

Not part of the Orchestrator's lifecycle graph — sustained, human-in-the-loop co-authoring sessions that produce the artifacts the pipeline above consumes. Persistence works differently here: the PRD/BRD/Spec file itself, saved incrementally, makes a session resumable across sittings — not a fresh-context-per-run default or a checkpoint file like the pipeline roles use.

| Stage | Role | Produces | Human gate |
|---|---|---|---|
| Brainstorm → PRD | `to-prd.agent.md` | `docs/prd/<initiative-slug>.md` | PRD `Gate 0` checkbox |
| PRD → BRD(s) | `to-brd.agent.md` | `docs/brd/<epic-slug>.md` (one per Epic) | BRD `Status: Ready for Spec` |
| BRD → HLD + Spec | `architect.agent.md` | `docs/architecture.md` (HLD, spans all BRDs) + `docs/specs/<epic-key>.md` per BRD | HLD `Status: Approved` **and** every Spec `Status: Approved` |

Execution doesn't start on a subset. `architect.agent.md` runs a **Finalization check** — PRD approved, every BRD Ready for Spec, the HLD approved, every Spec approved — before handing the whole initiative to the Orchestrator's own graph at `docs/team/ba.agent.md`. One BRD's Spec being Approved doesn't by itself start execution.

## Skills (project-authored)

This project has its own engineering-standard skills (clean code, backend best practices, logging, security, db conventions, etc. — whichever this project needs), each a real [Agent Skills](https://agentskills.io/specification) `SKILL.md` per `docs/templates/skill.template.md`. Skills are agent-agnostic with no declared trigger — relevance is always judged by whichever agent is working, never forced or hardcoded to a phase. If your harness has a native skill mechanism (Claude Code, OpenCode, Pi, Codex all do), it discovers and surfaces relevant skills on its own from wherever that harness keeps them — none of the role files above need to know or say where. GitHub Copilot has no such mechanism; see that harness's own setup notes for how skills are handled there instead.

## MCP servers (harness-configured, not authored here)

This kit does not declare or generate MCP server configuration — that's your harness's own setup (Claude Code's `.mcp.json`, OpenCode's `opencode.json` → `mcp`, Codex's `.codex/config.toml`, Pi's `.mcp.json`, GitHub Copilot's `.mcp.json`/`.github/mcp.json`), the same way this file never says where skills live for a harness with native discovery. Whatever MCP servers your harness has configured (Jira, GitHub, Confluence, a database, Playwright, whatever this project or your environment needs), scan what's available at the start of a session and use whichever are relevant to the task at hand — the same judgment-call pattern as Skills above, just for tools instead of instructions. A role's own "Requires" line (e.g. developer/reviewer's "Jira or GitHub MCP tools (or equivalent)") names what that role typically needs, not an exhaustive or mandatory list — don't skip a relevant MCP tool just because a role file didn't name it, and don't treat a missing one as blocking if a documented fallback exists (e.g. local `git diff` instead of GitHub MCP, `docs/stories/**/*.md` instead of Jira MCP).

Before any commit after code changes: run this project's build/lint/test commands as documented in `docs/project-context.md`.

## Documents

| Path | Purpose |
|---|---|
| `docs/process.md` | Process / roles / lifecycle graph / gates (this session's working rules) |
| `docs/project-context.md` | This project's filled-in stack, layout, conventions, Quality Thresholds, Delivery Tracker — create from the template |
| `docs/prd/` | Product requirements |
| `docs/brd/` | Business requirements |
| `docs/epics/` | Epic tracker (markdown when Jira Epic pending) |
| `docs/specs/` | Technical Spec (Gate 1) — one per BRD/Epic |
| `docs/architecture.md` | Optional cross-cutting architecture doc (system-wide, beyond any one BRD's Spec) — `developer.agent.md` reads it alongside the Spec when it exists |
| `docs/stories/` | Stories + ACs when Jira unavailable |
| `docs/templates/` | PRD / BRD / Spec / Story / project-context / skill templates |
| `docs/team/` | Per-role agent behavior specs (ba, developer, reviewer, qa) |
| `docs/discovery/` | Optional human-driven PRD → BRD → Spec co-authoring agents (to-prd, to-brd, architect) — see Upstream authoring above |
| *(harness-native skill folder, or `docs/skills/` if none)* | This project's engineering-standard skills — starter reference set shipped, add/replace as needed |
| `docs/dev-checkpoints/` | Developer task checkpoints |
| `docs/example/` | A fully filled-in worked example of this kit (fictional project) — copy the kit files above, not this folder |

## Commands

**Mirror only** — `docs/project-context.md` → Commands is authoritative; if these ever drift, that file wins. This section exists so the everyday commands (build/lint/test) are available without a second file read; the full set (integration tests, run-locally, per-stack breakdowns) lives in project-context only.

Example shape, mirroring a Java + JS/TS stack (see [docs/example/project-context.md](docs/example/project-context.md) for the fully filled two-stack instance this is drawn from):

```text
Backend:   ./gradlew compileJava --no-daemon
           ./gradlew pmdMain spotbugsMain --no-daemon
           ./gradlew test jacocoTestReport --no-daemon
           ./gradlew clean build --no-daemon   # FULL BUILD GATE — must be GREEN before commit

Frontend:  npx tsc --noEmit
           npx eslint src/ --ext .ts,.tsx
           npm test -- --coverage
           npm run build
```

Coverage and mutation-score minima (if set) come **only** from `docs/project-context.md` → Quality Thresholds.

## Living docs

If the human corrects you, update the relevant Spec, story, instruction, or role file so the mistake does not repeat. Prefer a separate commit for doc/skill fixes when appropriate.
