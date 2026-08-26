# AI-Augmented Delivery Kit

A portable, harness-agnostic set of process docs, role specs, and templates giving AI coding agents (Claude Code, GitHub Copilot, OpenCode, Codex, and others) a consistent way to work through a software initiative — from a rough idea to a merged, reviewed, tested change — instead of ad-hoc chat-driven development.

This repo **ships the kit**; it's not itself an application, and has no source code, build system, or test suite. Copy the files described below into your own repo to adopt it.

## What changes for your team

Most teams either hand-write everything and paste it into a chat, or let an AI agent freewheel across a whole feature with no checkpoints. This kit replaces that with two connected stages:

1. **Discovery** (optional, human-in-the-loop) — brainstorm a PRD, break it into one or more BRDs (one per Epic), then design a Spec (and a system-wide HLD) for each — each stage gated on explicit human sign-off, not a rubber stamp.
2. **Delivery** (Orchestrator-driven) — once a BRD or Story is ready: BA grooms stories with Gherkin ACs → Developer implements one story at a time (test-first, build-verify gate) → Reviewer gives a blocking-only P1/P2 verdict in a fresh, isolated context → QA validates every AC against a running app in a fresh, isolated context → loop back on failure, escalate to a human after 2 unresolved review cycles.

Two properties matter most:

- **Nothing merges without evidence.** Build-verify must be GREEN, Reviewer must APPROVE (zero P1/P2), QA must PASS every AC (or a human explicitly waives it) — see `docs/process.md` → Definition of Done.
- **Review and QA are adversarial by design.** They run in a fresh session that never inherited the Developer's conversation, so they check the diff cold instead of confirming what they were told.

You don't have to use every stage — see "Ways to enter the loop" below.

## The full picture

```text
Discovery (optional, human-in-the-loop — docs/discovery/):

  Brainstorm → to-prd.agent.md    → PRD (Gate 0 approved)
             → to-brd.agent.md    → BRD(s), one per Epic (Status: Ready for Spec)
             → architect.agent.md → HLD (docs/architecture.md) + Spec per BRD (Status: Approved)
             → Finalization check: PRD + every BRD + the HLD + every Spec all done
```

```text
Delivery (Orchestrator-driven — docs/process.md, docs/team/):

  Pick next queue item (BRD / Epic / already-groomed Story)
    → groomed story already exists for it?
         NO  → ba.agent grooms it into stories + Gherkin ACs
         YES → skip straight through (state check, not a check on the item's label)
    → developer.agent implements (fresh context per story; test-first: unit → integration; build-verify gate)
    → reviewer.agent (fresh, isolated context, ideally a different model)
         ├─ APPROVE                     → QA
         ├─ REQUEST_CHANGES, cycles < 2 → back to developer
         └─ REQUEST_CHANGES, cycles ≥ 2 → circuit breaker: escalate to human, stop
    → qa.agent (fresh, isolated context)
         ├─ PASS → close story, next ready story, then next queue item once all closed
         └─ FAIL → back to developer
```

## Ways to enter the loop

You don't have to start at the top:

| Starting point | What you skip | Use when |
|---|---|---|
| Brainstorm with `to-prd.agent.md` | Nothing — the full discovery chain | New initiative, nothing written down yet |
| Hand-write a BRD against `brd.template.md` | The discovery agents entirely | You already know the business requirements |
| Hand-write a Spec against `spec.template.md` | PRD/BRD authoring | The BRD exists, you just need the technical contract |
| Point the Orchestrator at an already-groomed Story (Jira key / GitHub issue / `docs/stories/**/*.md`) | BA grooming entirely | A story with ACs already exists — a small fix, a hand-written story, whatever |

The Orchestrator's input (`docs/process.md`) is a **queue that can mix all of these**. It decides whether to run BA per item based on whether a groomed story already exists — never on how the item happens to be labeled.

## Getting started in your own repo

1. **Build the kit for your harness**, then copy its contents into your repo:

   ```bash
   ./scripts/build-kit.sh                 # interactive menu
   ./scripts/build-kit.sh claude          # build one kit, e.g. for Claude Code
   ./scripts/build-kit.sh claude opencode # build several
   ./scripts/build-kit.sh all             # build all five
   ```

   Supported harness names: `claude`, `opencode`, `pi`, `copilot`, `codex`, or `all`. Each run produces a ready-to-copy `<harness>-kit/` directory at the repo root (gitignored — a build artifact, regenerate any time after editing `docs/skills/`, `docs/team/`, `docs/templates/`, or `AGENTS-example.md`), pre-arranged for that harness: native skill mirrors, per-role `/<name>` agent/command files where supported (see step 4), a starter `docs/project-context.md`/`docs/architecture.md` plus a clone-ready `docs/project-context-example.md` (see step 2), a bundled `docs/example/` reference (delete once used, per its own README), a self-contained `README.md`, and the empty `docs/{prd,brd,specs,epics,stories,dev-checkpoints}/` folders. Copy that directory's contents into your project's root — that's the whole step. See [`scripts/README.md`](scripts/README.md) for the full per-harness breakdown.

2. **Fill in `docs/project-context.md`** — the single most important step. Copy it from `docs/templates/project-context.template.md` and fill in every section: your repository's GitHub URL and commit message format, stack, source layout, conventions, build/lint/test commands, Quality Thresholds (coverage minima, optional mutation-score minimum), and — critically — your **Delivery Tracker** (`Jira` / `GitHub Issues` / `Local docs`), since every role file reads this to know where stories live and how status gets posted back. Use `docs/example/project-context.md` as a reference for the level of detail expected, not a value to copy. If your stack is close enough, `docs/project-context-example.md` is the same content clone-ready: copy it over `docs/project-context.md` and adapt it.

3. **(Optional) Add project skills** per `docs/templates/skill.template.md` — engineering-standard rules (security, db conventions, logging, etc). Place them at your harness's native skill location: `.claude/skills/<slug>/SKILL.md` (Claude Code), `.opencode/skills/<slug>/SKILL.md` (OpenCode), `.agents/skills/<slug>/SKILL.md` (Pi and Codex), or `.github/skills/<slug>/SKILL.md` (GitHub Copilot). All five harnesses auto-discover and judge relevance on their own — no `docs/team/*.agent.md` file names a skill path. Skills carry no role tag or forced-load flag; any agent that loads one judges relevance from its content.

4. **Wire it into your coding agent.** The kit is harness-agnostic — pointing your agent at a file directly ("follow `AGENTS.md`") works everywhere. Each harness below also gets a generated `/<name>` way to invoke one role directly:
   - **Claude Code** — `CLAUDE.md` (`@AGENTS.md`) auto-loads every session. `.claude/commands/<name>.md` per role: `ba`/`developer`/`reviewer`/`qa` run isolated (`context: fork`) with a commented `model:` override; `reviewer` is also read-only (`disallowed-tools`); `to-prd`/`to-brd`/`architect` run in your current session since they're sustained co-authoring conversations.
   - **OpenCode** — auto-loads `AGENTS.md` with zero config. `.opencode/agents/<name>.md` (mode/model/permission) plus a thin `.opencode/commands/<name>.md` per role give the same isolation/read-only pattern (`mode: subagent` for team roles, `mode: primary` for discovery roles).
   - **GitHub Copilot** — `.github/copilot-instructions.md` points Copilot at `AGENTS.md`. `.github/agents/<name>.agent.md` (VS Code, cloud coding agent, and Copilot CLI) is generated per role with a commented `model:` line; `to-prd`/`to-brd`/`architect` are scoped `target: vscode` since the cloud agent auto-opens PRs, a poor fit for co-authoring.
   - **Pi** — tell it to read `AGENTS.md` at session start. `.pi/prompts/<name>.md` per role as a pointer prompt; Pi has no isolated-subagent or per-agent model mechanism.
   - **Codex** — tell it to read `AGENTS.md` at session start. No per-role commands generated: its custom-prompt mechanism is user-global and deprecated, and its model-profile mechanism is per-machine — `AGENTS.md` routing is the only way to invoke a role.

   One distinction to keep in mind either way: `docs/discovery/*.agent.md` agents are sustained, human-in-the-loop sessions by design — don't dispatch them as isolated one-shot subagents, that defeats the point. `docs/team/*.agent.md` agents are closer to the opposite — Reviewer and QA specifically *require* a fresh, isolated session/subagent that never continues the Developer's conversation.

5. **Run it.**
   - Starting from scratch: open a session and say "follow `docs/discovery/to-prd.agent.md`, let's brainstorm a PRD for X."
   - Starting from an existing BRD or Story: tell your coding agent to follow `AGENTS.md` and point it at the BRD/Story — it resolves the right role itself.

## Key documents

| Path | Purpose |
|---|---|
| [`scripts/build-kit.sh`](scripts/README.md) | Generates a ready-to-copy, harness-specific kit directory (gitignored, regenerate on demand) |
| `AGENTS.md` (from `AGENTS-example.md`) | Portable entry point — read first by any agent |
| `docs/process.md` | Roles, gates, the Orchestrator's lifecycle graph, Definition of Done |
| `docs/project-context.md` | Your stack, conventions, Quality Thresholds, Delivery Tracker — **you fill this in** |
| `docs/project-context-example.md` | Same filled-in reference as `docs/example/project-context.md`, clone-ready at the top of `docs/` — copy over `docs/project-context.md` if your stack is close enough |
| `docs/team/` | Pipeline role specs: `ba`, `developer`, `reviewer`, `qa` |
| `docs/discovery/` | Optional upstream co-authoring: `to-prd`, `to-brd`, `architect` |
| `docs/templates/` | PRD / BRD / Spec / Story / project-context / skill templates |
| `docs/prd/`, `docs/brd/`, `docs/specs/`, `docs/stories/`, `docs/epics/` | Where the actual artifacts live once written |
| `docs/architecture.md` | Optional system-wide HLD, produced/maintained by `architect.agent.md` |
| `docs/skills/` | Engineering-standard rules, authored here; `scripts/build-kit.sh` relocates them into your harness's native folder (e.g. `.claude/skills/`, `.github/skills/`) |
| `docs/dev-checkpoints/` | Developer's resumable per-story task checkpoints |
| `docs/example/` | Fully filled-in worked instance — reference only, never copy by hand. `scripts/build-kit.sh` bundles it into generated kits for teams without this source repo — delete once used |

## Keeping the kit healthy (living docs)

If a human corrects an agent's behavior or a standard, fix the doc that produced the mistake — `docs/process.md`, the relevant `docs/team/*.agent.md` or `docs/discovery/*.agent.md`, or a template — not just that one conversation, so the next session and teammate don't hit the same issue. See `docs/process.md` → Living documents.
