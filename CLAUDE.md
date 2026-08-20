# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

This is **not an application** — it's an **AI-augmented software delivery kit**: a portable, harness-agnostic set of process docs, role specs, and templates meant to be copied into other repositories so that AI coding agents (Claude Code, Copilot, OpenCode, Codex, etc.) follow a consistent BA → Developer → Reviewer → QA workflow there. There is no source code, build system, or test suite in this repo itself — everything here is Markdown.

`AGENTS-example.md` and `CLAUDE-example.md` are the portable entry points a consuming repo copies in (as `AGENTS.md` / `CLAUDE.md`) to bootstrap the kit. `CLAUDE-example.md` is intentionally just `@AGENTS.md` — Claude Code follows that reference into the shared `AGENTS.md` content rather than duplicating it.

## Working in this repo

Since this repo ships the kit rather than consumes it, most edits are to the process/role/template files themselves:

- Treat `AGENTS-example.md` as the canonical "what a consumer copies" entry point — keep it in sync with `docs/process.md` and `docs/team/*.agent.md` if you change roles, gates, or the lifecycle graph.
- `docs/example/` is a fully filled-in worked instance (fictional "Performance Marketing Platform MVP") used to show what a completed `project-context.md`/PRD look like. **Never** edit it to make it more "generic" — it exists precisely to be concrete. Don't fold its content back into the templates.
- Templates (`docs/templates/*.template.md`) must stay stack-agnostic — they're filled in per-consuming-project, not per-example. If you add a placeholder, add the corresponding filled-in reference in `docs/example/` when relevant.
- When correcting a mistaken assumption about how this kit should behave, update the living doc it came from (`docs/process.md`, the relevant `docs/team/*.agent.md`, or a template) rather than only fixing the immediate output — that's the kit's own "living docs" rule (see `docs/process.md` → Living documents), and it applies recursively to editing the kit itself.

## Architecture: the delivery lifecycle

The kit's central idea, defined in `docs/process.md`, is a strict role graph with gates and a circuit breaker:

```text
Pick next queue item — BRD (docs/brd/<epic-slug>.md), Epic (docs/epics/*.md), or an already-groomed Story (Jira key / GitHub issue / docs/stories/**/*.md)
           → groomed story already exists for it? NO → BA grooms it into stories + Gherkin ACs
                                                  YES → skip BA (state check, not a check on the item's label)
           → Developer (implement + build-verify gate)
           → Reviewer (P1/P2-only verdict, fresh/isolated context, ideally a different model)
                ├─ APPROVE                        → QA
                ├─ REQUEST_CHANGES, cycles < 2     → back to Developer
                └─ REQUEST_CHANGES, cycles ≥ 2     → circuit breaker: escalate to human, stop
           → QA (validate ACs against running app; fresh/isolated context, P1/P2-only defects)
                ├─ PASS → close story, next ready story for this item, then next queue item once all closed
                └─ FAIL → back to Developer
```

Each role has one behavior spec under `docs/team/`, and each is meant to be *read by an agent playing that role*, not by a human orchestrator:

| File | Role | Key constraint |
|---|---|---|
| `docs/team/ba.agent.md` | Breaks BRDs into stories with Gherkin ACs | Never writes code; runs an "Auto Re-slice" pass every time to kill mega-stories (CRUD bundles, >7 AC rows, multi-screen UI files) before anything else |
| `docs/team/developer.agent.md` | Implements one story per run | Numbered phase flow (0 Intake → 11 Tracker); cannot commit/PR unless build-verify is GREEN per `project-context.md` → Quality Thresholds |
| `docs/team/reviewer.agent.md` | P1(security/critical)/P2(architecture/Spec/boundary drift)-only review | Must run in a fresh, isolated context/session (never continuing the developer's conversation), ideally a different model; no style/test nits; 2-cycle circuit breaker |
| `docs/team/qa.agent.md` | Validates ACs against a running app | Must also run in a fresh, isolated context; PASS/FAIL/BLOCKED per AC, no lowering the bar |

PRD, BRD, and technical Spec are authored **upstream of this graph**, either by hand against `docs/templates/prd.template.md`, `brd.template.md`, `spec.template.md`, or via the optional co-authoring agents under `docs/discovery/` — sustained, human-in-the-loop sessions (not fresh-context-per-run like `docs/team/`), each gated on the template's own approval field rather than build-verify/circuit-breaker:

| File | Role | Human gate |
|---|---|---|
| `docs/discovery/to-prd.agent.md` | Brainstorm → PRD | PRD `Gate 0` checkbox |
| `docs/discovery/to-brd.agent.md` | PRD → BRD(s), one per Epic | BRD `Status: Ready for Spec` |
| `docs/discovery/architect.agent.md` | BRD → HLD (`docs/architecture.md`, spans all BRDs) + Spec per BRD | HLD `Status: Approved` **and** every Spec `Status: Approved` |

This stage sits outside the Orchestrator's graph in `docs/process.md`. Execution doesn't start on a subset: `architect.agent.md` runs a Finalization check (PRD approved, every BRD Ready for Spec, HLD approved, every Spec approved) before a BRD produced this way enters the Orchestrator's queue. A standalone Story bypasses this whole discovery chain and enters the queue directly.

## Key mechanism: `docs/project-context.md`

Every role file defers stack-specific facts (languages, frameworks, build/test/lint commands, coverage thresholds, layering conventions, and which Delivery Tracker — Jira / GitHub Issues / local `docs/` — owns Epics/Stories) to a single `docs/project-context.md` in the *consuming* repo, created from `docs/templates/project-context.template.md`. This kit deliberately does not hardcode any language/framework/coverage numbers anywhere else — when editing role files, don't reintroduce stack-specific assumptions; point at `project-context.md` instead, the same way the existing files do.

`docs/skills/` (empty in this kit by design) is the analogous per-project mechanism for engineering-standard rules (security, db conventions, logging, etc.) — `docs/templates/skill.template.md` defines the shape. Skills are **agent-agnostic** with no declared trigger: each just declares `Always load: Yes | No`, and any agent (developer/reviewer/architect) loads every `Yes` skill plus whichever `No` ones it judges relevant to what it's doing right now, from the skill's own content — no role tag, no condition string to keep in sync. Each agent then applies only the guidance relevant to its own job (e.g. Reviewer still only acts on P1/P2-relevant rules from a loaded skill).

## Gotchas specific to this kit

- The Reviewer↔Developer loop and the QA↔Developer loop are asymmetric on purpose today: Reviewer caps at 2 `REQUEST_CHANGES` cycles before escalating to a human; QA↔Developer has no such cap. This is called out explicitly in `docs/process.md` rather than silently fixed — don't "fix" it without flagging the tradeoff to the user first.
- Reviewer and QA agent specs both hard-require a **fresh, isolated context** (new subagent/session) — this is the load-bearing property that makes the gate meaningful, more important than the "different model" recommendation that goes with it. Preserve this distinction if editing those files.
- The `docs/example/` README explicitly says: don't copy `docs/example/` into a consuming repo — it's reference only, delete after use.
