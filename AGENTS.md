# AGENTS.md

Portable entry point for coding agents (GitHub Copilot, OpenCode, Claude Code, Codex, Pi agent etc.).

This repo uses an **AI-augmented delivery kit**. Prefer **custom agents** over ad-hoc chat.

## Always read first

1. [docs/process.md](docs/process.md) — how work moves, roles, gates
3. [docs/project-context.instructions.md](docs/project-context.instructions.md) — layout, conventions, **Quality Thresholds**

## Delivery model

```text
 Stories + ACs → Plan → Implement → Build-verify → Review → QA
```

- **Spec is law** for API, schema, Redis, Kafka, FE impact
- **One BRD = one Epic**; do not split Frontend BRD vs Backend BRD
- **One developer run = one story** (unless user explicitly asks otherwise)
- No guild blackboard — Jira and/or `docs/` are the source of truth

## Agents (`.github/agents/`)

| Stage | Agent |
|---|---|
| Product requirements | `prd` |
| Business requirements + Epics | `brd` |
| Technical Spec | `architect` |
| Stories + Gherkin ACs | `ba` |
| Implement | `developer` or `developer.agent.mini` |
| Code review | `reviewer` |
| AC validation | `test` |

## Skills (`.github/skills/`)

- Lookup: [.github/skills/skill-registry.md](.github/skills/skill-registry.md)
- Before any commit after code changes: [.github/skills/build-verify/SKILL.md](.github/skills/build-verify/SKILL.md)
- Profiles: `profile-java`, `profile-js-react-vite`

Load skills with the Read tool when relevant; do not only list names.

## Documents

| Path | Purpose |
|---|---|
| `docs/process.md` | Process / roles / gates (this session’s working rules) |
| `docs/prd/` | Product requirements |
| `docs/brd/` | Business requirements |
| `docs/epics/` | Epic tracker (markdown when Jira Epic pending) |
| `docs/specs/` | Technical Spec (Gate 1) |
| `docs/stories/` | Stories + ACs when Jira unavailable |
| `docs/templates/` | PRD / BRD / Spec / Story templates |
| `docs/dev-checkpoints/` | Developer task checkpoints |

## Commands (customize per app)

Document real commands in `project-context` and profile skills. Typical:

```text
Backend:  ./gradlew compileJava test jacocoTestReport clean build
Frontend: npx tsc --noEmit && npm test -- --coverage && npm run build
```

Coverage minima come **only** from `project-context` → Quality Thresholds.

## Living docs

If the human corrects you, update the relevant Spec, story, instruction, or skill so the mistake does not repeat. Prefer a separate commit for doc/skill fixes when appropriate.
