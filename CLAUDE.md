# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

This is **not an application** — it's an **AI-augmented software delivery kit**: a portable, harness-agnostic set of process docs, role specs, and templates meant to be copied into other repositories so that AI coding agents (Claude Code, Copilot, OpenCode, Codex, etc.) follow a consistent BA → Developer → Reviewer → QA workflow there. There is no source code, build system, or test suite in this repo itself — everything here is Markdown.

`AGENTS-example.md` and `CLAUDE-example.md` are the portable entry points a consuming repo copies in (as `AGENTS.md` / `CLAUDE.md`) to bootstrap the kit. `CLAUDE-example.md` is intentionally just `@AGENTS.md` — Claude Code follows that reference into the shared `AGENTS.md` content rather than duplicating it.

## Working in this repo

Since this repo ships the kit rather than consumes it, most edits are to the process/role/template files themselves:

- Treat `AGENTS-example.md` as the canonical "what a consumer copies" entry point — keep it in sync with `docs/process.md` and `docs/team/*.agent.md` if you change roles, gates, or the lifecycle graph.
- `docs/example/` is a fully filled-in worked instance (fictional "Performance Marketing Platform MVP") used to show what a completed `project-context.md`/PRD look like. **Never** edit it to make it more "generic" — it exists precisely to be concrete. Don't fold its content back into the templates. `scripts/build-kit.sh` copies this folder byte-identical into every generated `<harness>-kit/` (a team with only the generated kit, not this source repo, still needs the reference) — that's bundling, not folding-back-into-templates, and doesn't conflict with the rule above as long as the copy stays unedited.
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

`docs/skills/<slug>/SKILL.md` is the analogous per-project mechanism for engineering-standard rules (security, db conventions, logging, etc.) — `docs/templates/skill.template.md` defines the shape, and this kit ships 15 real skills as a reference set: 13 for the Java/Spring/React stack, plus 2 stack-agnostic QA/testing-tool skills (`playwright-cli`, `playwright-generate-test`) usable by the QA role regardless of backend/frontend stack — adapt or replace per-project. Each file is a real [Agent Skills](https://agentskills.io/specification) `SKILL.md` (YAML frontmatter: `name`, `description`), not a kit-invented format — deliberately no "Owner" or bespoke Meta-table field, since ownership belongs in CODEOWNERS and everything functional already has a spec-defined home in frontmatter. Skills are **agent-agnostic** with no declared trigger and no forced-load flag: any agent (developer/reviewer/architect) reads every skill's name/content and judges relevance to what it's doing right now — always judged, never skipped or forced. Each agent then applies only the guidance relevant to its own job (e.g. Reviewer still only acts on P1/P2-relevant rules from a loaded skill).

`docs/skills/` in *this* repo is the authoring location, not a fixed runtime path — `scripts/build-kit.sh` *relocates* skills into each harness's native folder when generating a kit (`.claude/skills/`, `.opencode/skills/`, `.agents/skills/` for Pi and Codex; `docs/skills/` stays put only for Copilot, which has no native mechanism). Critically, `AGENTS.md`/`docs/team/*.agent.md`/`docs/discovery/architect.agent.md`/`docs/process.md`/`docs/templates/skill.template.md` are copied **byte-identical** into every kit regardless of harness — none of them name a skill path or instruct an agent to list/judge one, on purpose. Claude Code, OpenCode, Pi, and Codex each discover and judge skill relevance from their own native folder automatically, so there's nothing for those role files to say; adding that back in would just be a path to keep in sync for no behavioral gain. Copilot is the one harness without that native mechanism, so it's the one place a skill path is spelled out explicitly — in the generated `.github/copilot-instructions.md`, a harness-unique file this kit already writes fresh per generation, not one of the shared role files. See `scripts/README.md`.

`build-kit.sh` also generates one ad hoc `/<name>` invocation per role (`ba`, `developer`, `qa`, `reviewer`, `to-prd`, `to-brd`, `architect`) for harnesses that support it — built *from* the canonical `docs/team/<name>.agent.md` / `docs/discovery/<name>.agent.md` at generation time (embedding its content), not a hand-maintained duplicate, so those files stay the single byte-identical source of truth described above. `AGENTS.md`'s own routing already resolves the right role automatically without one of these; they exist for a human who wants to invoke a role directly — and, where the harness supports it, to give `reviewer.agent.md`/`qa.agent.md`'s "run in a fresh, isolated context" hard rule and "prefer a different model than the implementer" recommendation an actual mechanism instead of leaving both as "wire this into your harness yourself." Claude Code merged its commands into Skills, so one `.claude/commands/<name>.md` file does everything (`context: fork` for isolation, a `model:` override on the same file, `disallowed-tools` to make Reviewer's read-only rule enforced rather than requested). OpenCode keeps two separate files — `.opencode/agents/<name>.md` (mode/model/permission) plus a thin `.opencode/commands/<name>.md` pointing at it — since its `/` namespace is commands-only and its separate `.opencode/agents/` mechanism (Tab/`@`-mention-only) was the original source of confusion here. Pi and Codex don't get the isolation/model treatment: core Pi has no per-agent model field or isolated-subagent concept at all, and Codex's only project-local custom-prompt mechanism is deprecated while its model-profile mechanism is inherently per-machine. See `scripts/README.md` for the full per-harness table and gotchas.

## Gotchas specific to this kit

- The Reviewer↔Developer loop and the QA↔Developer loop are asymmetric on purpose today: Reviewer caps at 2 `REQUEST_CHANGES` cycles before escalating to a human; QA↔Developer has no such cap. This is called out explicitly in `docs/process.md` rather than silently fixed — don't "fix" it without flagging the tradeoff to the user first.
- Reviewer and QA agent specs both hard-require a **fresh, isolated context** (new subagent/session) — this is the load-bearing property that makes the gate meaningful, more important than the "different model" recommendation that goes with it. Preserve this distinction if editing those files.
- The `docs/example/` README explicitly says: don't copy `docs/example/` into a consuming repo — it's reference only, delete after use.
- MCP server configuration is intentionally **not** templated or generated by this kit — see `AGENTS-example.md` → MCP servers. The three harness MCP schemas diverge enough (Claude Code/Pi/Copilot share one `.mcp.json`/`mcpServers` shape; OpenCode and Codex don't) that auto-generating native config for all 5 would need either a new `jq`/TOML dependency in `scripts/build-kit.sh` or a bespoke bash parser — deliberately skipped. Don't add that automation back in without flagging the tradeoff to the user first, same as the Reviewer/QA circuit-breaker asymmetry above.
