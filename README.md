# AI-Augmented Delivery Kit

A portable, harness-agnostic set of process docs, role specs, and templates that gives AI coding agents (Claude Code, GitHub Copilot, OpenCode, Codex, and others) a consistent way to work through a software initiative — from a rough idea to a merged, reviewed, tested change — instead of ad-hoc chat-driven development.

This repo **ships the kit**; it is not itself an application, and has no source code, build system, or test suite. Copy the files described below into your own repository to adopt it there.

## What changes for your team

Today, most teams either hand-write everything and paste it into a chat, or let an AI agent freewheel across a whole feature with no checkpoints. This kit replaces that with two connected stages:

1. **Discovery** (optional, human-in-the-loop) — brainstorm a PRD, break it into one or more BRDs (one per Epic), then design a Spec (and a system-wide HLD) for each — each stage gated on an explicit human sign-off, not a rubber stamp.
2. **Delivery** (Orchestrator-driven) — once a BRD or Story is ready, an Orchestrator drives a fixed loop: BA grooms stories with Gherkin acceptance criteria → Developer implements one story at a time (test-first, build-verify gate) → Reviewer gives a blocking-only P1/P2 verdict in a fresh, isolated context → QA validates every AC against a running app in a fresh, isolated context → loop back on failure, escalate to a human after 2 unresolved review cycles.

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

1. **Copy the kit files** into your repo (not this whole repo — just these):
   - `AGENTS-example.md` → `AGENTS.md`
   - `CLAUDE-example.md` → `CLAUDE.md` (Claude Code only — it's a one-line `@AGENTS.md` pointer; skip for other harnesses)
   - `docs/process.md`
   - `docs/team/` — the pipeline role specs (`ba`, `developer`, `reviewer`, `qa`)
   - `docs/templates/` — PRD / BRD / Spec / Story / project-context / skill templates
   - `docs/discovery/` — only if you want the optional PRD → BRD → Spec co-authoring agents (`to-prd`, `to-brd`, `architect`)
   - Do **not** copy `docs/example/` — it's a worked reference to read, not kit content (see its own README)

   **Shortcut:** `scripts/build-kit.sh <harness>` (or run with no arguments for an interactive menu) generates a ready-to-copy `<harness>-kit/` directory at the repo root with these files pre-arranged for your harness — including native skill mirrors for Claude Code/OpenCode/Pi/Codex, a starter `docs/project-context.md`/`docs/architecture.md`, and the empty `docs/{prd,brd,specs,epics,stories,dev-checkpoints}/` folders — so copy that one directory into your project instead of assembling files by hand. Supported harness names: `claude`, `opencode`, `pi`, `copilot`, `codex`, or `all`.

2. **Fill in `docs/project-context.md`** — the single most important step. Copy it from `docs/templates/project-context.template.md` and fill in every section: your repository's GitHub URL and commit message format, your stack, source layout, conventions, build/lint/test commands, Quality Thresholds (coverage minima, and an optional mutation-score minimum), and — critically — your **Delivery Tracker** (`Jira` / `GitHub Issues` / `Local docs`), since every role file reads this to know where stories live and how status gets posted back. Use `docs/example/project-context.md` as a reference for the level of detail expected, not a value to copy.

3. **(Optional) Add project skills** per `docs/templates/skill.template.md` — engineering-standard rules (security, db conventions, logging, whatever your project needs). If you used the `scripts/build-kit.sh` shortcut, add new skills directly at your harness's native skill location (e.g. `.claude/skills/<slug>/SKILL.md`, `.opencode/skills/<slug>/SKILL.md`) — that harness discovers and judges relevance for them on its own; none of `docs/team/*.agent.md` names a skill path or needs to. If you copied files by hand instead (no native skill mechanism, e.g. GitHub Copilot), `docs/skills/` is the only location, and nothing surfaces them automatically — see Gotchas below. Skills carry no role tag and no forced-load flag either way — any agent that does load one judges relevance to its own current task from the skill's content itself.

4. **Wire it into your coding agent.** The kit is deliberately harness-agnostic — the one thing guaranteed to work everywhere is pointing your agent at a file directly ("follow `AGENTS.md`", or "follow `docs/team/developer.agent.md`"). Per-harness conveniences on top of that are optional and not part of the portable kit:
   - **Claude Code** — `CLAUDE.md` (`@AGENTS.md`) auto-loads every session; nothing else required. For a quick way to invoke one role ad hoc, you can add a `.claude/commands/<name>.md` slash command whose body is `@docs/team/<name>.agent.md` (or `@docs/discovery/<name>.agent.md`).
   - **GitHub Copilot** — point `.github/copilot-instructions.md` at `AGENTS.md`, or use Copilot's own prompt-file mechanism for individual roles.
   - **OpenCode / Codex / others** — reference `AGENTS.md` via your harness's own instruction/config mechanism, or just tell the agent to read it at the start of a session.

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
| `docs/team/` | Pipeline role specs: `ba`, `developer`, `reviewer`, `qa` |
| `docs/discovery/` | Optional upstream co-authoring: `to-prd`, `to-brd`, `architect` |
| `docs/templates/` | PRD / BRD / Spec / Story / project-context / skill templates |
| `docs/prd/`, `docs/brd/`, `docs/specs/`, `docs/stories/`, `docs/epics/` | Where the actual artifacts live once written |
| `docs/architecture.md` | Optional system-wide HLD, produced/maintained by `architect.agent.md` |
| `docs/skills/` | Your project's engineering-standard rules — only the skill location if hand-copied without a native skill mechanism; `scripts/build-kit.sh` relocates this to your harness's native folder instead |
| `docs/dev-checkpoints/` | Developer's resumable per-story task checkpoints |
| `docs/example/` | A fully filled-in worked instance — reference only, never copy into your repo |

## Keeping the kit healthy (living docs)

If a human corrects an agent's behavior or a standard, the fix belongs in the doc that produced the mistake — `docs/process.md`, the relevant `docs/team/*.agent.md` or `docs/discovery/*.agent.md`, or a template — not just in that one conversation. That's what keeps the next session, and the next teammate, from hitting the same issue. See `docs/process.md` → Living documents.

## Gotchas worth knowing up front

- The Reviewer↔Developer loop caps at 2 `REQUEST_CHANGES` cycles before escalating to a human; the QA↔Developer loop has no such cap today. Known and intentional — see `docs/process.md`.
- Reviewer and QA's fresh-context requirement is a **hard rule**, not a default — it's what makes the gate meaningful. Developer's and BA's fresh-context-per-item is a *default* for context-window hygiene, which a harness can skip for convenience without breaking anything.
- Templates must stay stack-agnostic; project-specific facts belong in `docs/project-context.md`, never hardcoded into a role file.
- GitHub Copilot has no native skill-discovery mechanism — Claude Code, OpenCode, Pi, and Codex all auto-discover skills from their own native folder, so `docs/team/*.agent.md`/`docs/process.md` deliberately never name a skill path. For Copilot, that means project skills need an explicit nudge; `scripts/build-kit.sh` puts one in the generated `copilot-instructions.md`, but if you're wiring Copilot by hand, you'll need to tell it to read `docs/skills/*/SKILL.md` yourself. Known and intentional, not a bug to route around by re-adding path mechanics to the shared role files.
