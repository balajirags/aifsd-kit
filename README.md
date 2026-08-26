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

   **Shortcut:** `scripts/build-kit.sh <harness>` (or run with no arguments for an interactive menu) generates a ready-to-copy `<harness>-kit/` directory at the repo root with these files pre-arranged for your harness — including native skill mirrors for all five harnesses, a starter `docs/project-context.md`/`docs/architecture.md`, a standalone `docs/project-context-example.md` (the same filled-in reference as `docs/example/project-context.md`, but sitting at the top level of `docs/` so you can literally copy it over the blank `docs/project-context.md` if your stack is close enough — see step 2), a bundled `docs/example/` (same worked reference, for when the recipient only has the generated kit and not this source repo — delete it once used, per its own README), a self-contained `README.md`, and the empty `docs/{prd,brd,specs,epics,stories,dev-checkpoints}/` folders — so copy that one directory into your project instead of assembling files by hand. Supported harness names: `claude`, `opencode`, `pi`, `copilot`, `codex`, or `all`.

2. **Fill in `docs/project-context.md`** — the single most important step. Copy it from `docs/templates/project-context.template.md` and fill in every section: your repository's GitHub URL and commit message format, your stack, source layout, conventions, build/lint/test commands, Quality Thresholds (coverage minima, and an optional mutation-score minimum), and — critically — your **Delivery Tracker** (`Jira` / `GitHub Issues` / `Local docs`), since every role file reads this to know where stories live and how status gets posted back. Use `docs/example/project-context.md` as a reference for the level of detail expected, not a value to copy. If your stack is close enough to that example to start from a filled-in file instead of the blank template, `docs/project-context-example.md` is the same content ready to clone: copy it over `docs/project-context.md` and adapt it.

3. **(Optional) Add project skills** per `docs/templates/skill.template.md` — engineering-standard rules (security, db conventions, logging, whatever your project needs). Add new skills directly at your harness's native skill location — `.claude/skills/<slug>/SKILL.md` (Claude Code), `.opencode/skills/<slug>/SKILL.md` (OpenCode), `.agents/skills/<slug>/SKILL.md` (Pi and Codex), or `.github/skills/<slug>/SKILL.md` (GitHub Copilot — native Agent Skills support since December 2025). Every supported harness now discovers and judges relevance for them on its own; none of `docs/team/*.agent.md` names a skill path or needs to. If you didn't use the `scripts/build-kit.sh` shortcut, create that folder yourself — it isn't part of the hand-copy list in step 1. Skills carry no role tag and no forced-load flag either way — any agent that does load one judges relevance to its own current task from the skill's content itself.

4. **Wire it into your coding agent.** The kit is deliberately harness-agnostic — the one thing guaranteed to work everywhere, hand-copied or not, is pointing your agent at a file directly ("follow `AGENTS.md`", or "follow `docs/team/developer.agent.md`"). If you used the `scripts/build-kit.sh` shortcut, each harness below also gets an ad hoc `/<name>`-style way to invoke one role directly, generated for you — hand-copying doesn't produce these on its own:
   - **Claude Code** — `CLAUDE.md` (`@AGENTS.md`) auto-loads every session; nothing else required. `.claude/commands/<name>.md` is generated per role: `ba`/`developer`/`reviewer`/`qa` run isolated (`context: fork`) with a commented `model:` override to pin a different model than the implementer, and `reviewer` is additionally enforced read-only (`disallowed-tools`); `to-prd`/`to-brd`/`architect` run in your current session instead, since those are sustained co-authoring conversations, not one-shot dispatches.
   - **OpenCode** — auto-loads `AGENTS.md` from the project root with zero config; nothing else required. `.opencode/agents/<name>.md` (mode/model/permission) plus a thin `.opencode/commands/<name>.md` are generated per role, giving the same `/<name>` invocation and isolation/read-only pattern as Claude Code above (`mode: subagent` for team roles, `mode: primary` for discovery roles).
   - **GitHub Copilot** — `.github/copilot-instructions.md` (generated) points Copilot at `AGENTS.md`. `.github/agents/<name>.agent.md` — GitHub's real custom-agent format, spanning VS Code's agent picker, the GitHub.com cloud coding agent, and the Copilot CLI — is generated per role with a commented `model:` line; `to-prd`/`to-brd`/`architect` are scoped `target: vscode`, since the cloud coding agent is an autonomous, PR-opening surface unsuited to a co-authoring conversation.
   - **Pi** — tell it to read `AGENTS.md` at the start of a session. `.pi/prompts/<name>.md` is generated per role as a named pointer prompt; core Pi has no isolated-subagent or per-agent `model:` mechanism, so it can't get the same isolation/model treatment as the harnesses above.
   - **Codex** — tell it to read `AGENTS.md` at the start of a session. No per-role commands are generated: its only markdown-backed custom-prompt mechanism is user-global (not project-local) and deprecated, and its model-profile mechanism is inherently per-machine — `AGENTS.md`'s own routing is the only way to invoke a role.

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
| `docs/project-context-example.md` | The same filled-in reference as `docs/example/project-context.md`, but clone-ready at the top level of `docs/` — copy it over `docs/project-context.md` if your stack is close enough to start from, instead of the blank template |
| `docs/team/` | Pipeline role specs: `ba`, `developer`, `reviewer`, `qa` |
| `docs/discovery/` | Optional upstream co-authoring: `to-prd`, `to-brd`, `architect` |
| `docs/templates/` | PRD / BRD / Spec / Story / project-context / skill templates |
| `docs/prd/`, `docs/brd/`, `docs/specs/`, `docs/stories/`, `docs/epics/` | Where the actual artifacts live once written |
| `docs/architecture.md` | Optional system-wide HLD, produced/maintained by `architect.agent.md` |
| `docs/skills/` | Your project's engineering-standard rules — the authoring location in this source repo; `scripts/build-kit.sh` relocates skills into your harness's native folder (e.g. `.claude/skills/`, `.github/skills/`) rather than leaving them here |
| `docs/dev-checkpoints/` | Developer's resumable per-story task checkpoints |
| `docs/example/` | A fully filled-in worked instance — reference only, never copy into your repo by hand. `scripts/build-kit.sh` does bundle it into generated kits for teams without access to this source repo — delete it once used either way |

## Keeping the kit healthy (living docs)

If a human corrects an agent's behavior or a standard, the fix belongs in the doc that produced the mistake — `docs/process.md`, the relevant `docs/team/*.agent.md` or `docs/discovery/*.agent.md`, or a template — not just in that one conversation. That's what keeps the next session, and the next teammate, from hitting the same issue. See `docs/process.md` → Living documents.

## Gotchas worth knowing up front

- The Reviewer↔Developer loop caps at 2 `REQUEST_CHANGES` cycles before escalating to a human; the QA↔Developer loop has no such cap today. Known and intentional — see `docs/process.md`.
- Reviewer and QA's fresh-context requirement is a **hard rule**, not a default — it's what makes the gate meaningful. Developer's and BA's fresh-context-per-item is a *default* for context-window hygiene, which a harness can skip for convenience without breaking anything.
- Templates must stay stack-agnostic; project-specific facts belong in `docs/project-context.md`, never hardcoded into a role file.
- All five supported harnesses auto-discover skills from their own native folder — Copilot added this in December 2025 — so `docs/team/*.agent.md`/`docs/process.md` deliberately never name a skill path for any of them.
- GitHub Copilot's custom agents (`.github/agents/*.agent.md`) and its skill discovery (`.github/skills/`) are two independent native mechanisms, added and documented separately — a custom agent's frontmatter has no field that references skill files, so having one doesn't imply the other.
