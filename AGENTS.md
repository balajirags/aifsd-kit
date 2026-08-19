# AGENTS.md

Portable entry point for coding agents (GitHub Copilot, OpenCode, Claude Code, Codex, Pi agent etc.).

This repo uses an **AI-augmented delivery kit**. Prefer following the roles/gates below over ad-hoc chat.

## Always read first

1. [docs/process.md](docs/process.md) — how work moves, roles, gates
2. [docs/project-context.md](docs/project-context.md) — this project's stack, layout, conventions, **Quality Thresholds**, and **Delivery Tracker** (Jira / GitHub Issues / Local docs). Create it from [docs/templates/project-context.template.md](docs/templates/project-context.template.md) if it doesn't exist yet.

## Delivery model

```text
 Stories + ACs → Plan → Implement → Build-verify → Review → QA
```

- **Spec is law** for API, schema, cache, messaging, FE impact
- **One BRD = one Epic**; do not split Frontend BRD vs Backend BRD
- **One developer run = one story** (unless user explicitly asks otherwise)
- No guild blackboard — Jira and/or `docs/` are the source of truth

## Roles (`docs/team/`)

| Stage | Role |
|---|---|
| Stories + Gherkin ACs | `ba.agent.md` |
| Implement | `developer.agent.md` |
| Code review | `reviewer.agent.md` |
| AC validation | `qa.agent.md` |

PRD, BRD, and Technical Spec are **template-driven, not agent-driven**, in this kit — author them by hand (or with your harness's general assistant) against `docs/templates/prd.template.md`, `brd.template.md`, and `spec.template.md`. Add a dedicated `prd`/`brd`/`architect` role under `docs/team/` if your team wants one; none ships today.

## Skills (`docs/skills/`, project-authored)

This kit ships the loading mechanism, not the content: `docs/skills/` is where this project's own engineering-standard skills live (clean code, backend best practices, logging, security, db conventions, etc. — whichever this project needs). It's empty in the kit itself; add skills per `docs/templates/skill.template.md` as your project needs them. `developer.agent.md` reads `docs/project-context.md` plus whichever skills apply to the current task (always-on ones, plus any whose "Applies when" condition matches what Recon found) — see its Phase 1–2. If your harness also has a native skill/instruction mechanism (e.g. `.claude/skills/`, `.github/instructions/`), point it at these same files instead of duplicating content.

Before any commit after code changes: run this project's build/lint/test commands as documented in `docs/project-context.md`.

## Documents

| Path | Purpose |
|---|---|
| `docs/process.md` | Process / roles / lifecycle graph / gates (this session's working rules) |
| `docs/project-context.md` | This project's filled-in stack, layout, conventions, Quality Thresholds, Delivery Tracker — create from the template |
| `docs/prd/` | Product requirements |
| `docs/brd/` | Business requirements |
| `docs/epics/` | Epic tracker (markdown when Jira Epic pending) |
| `docs/specs/` | Technical Spec (Gate 1) |
| `docs/stories/` | Stories + ACs when Jira unavailable |
| `docs/templates/` | PRD / BRD / Spec / Story / project-context / skill templates |
| `docs/team/` | Per-role agent behavior specs (ba, developer, reviewer, qa) |
| `docs/skills/` | This project's engineering-standard skills (empty in the kit; add your own) |
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

Coverage minima come **only** from `docs/project-context.md` → Quality Thresholds.

## Living docs

If the human corrects you, update the relevant Spec, story, instruction, or role file so the mistake does not repeat. Prefer a separate commit for doc/skill fixes when appropriate.
