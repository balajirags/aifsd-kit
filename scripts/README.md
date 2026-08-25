# `build-kit.sh`

Generates a self-contained, harness-specific kit directory at the repo root, ready to copy straight into a consuming project. It replaces assembling `AGENTS.md`/`CLAUDE.md`/`docs/` by hand — see the root [`README.md`](../README.md) for what the kit itself is.

## Usage

```bash
./scripts/build-kit.sh                 # interactive menu
./scripts/build-kit.sh claude           # build one kit
./scripts/build-kit.sh claude pi        # build several
./scripts/build-kit.sh all              # build all five
```

Supported harness names: `claude`, `opencode`, `pi`, `copilot`, `codex`.

Every run fully rebuilds the target `<harness>-kit/` directories from scratch (`rm -rf` then regenerate) — safe to re-run any time after editing `docs/skills/`, `docs/team/`, `docs/templates/`, or `AGENTS-example.md`. Output directories are gitignored (`*-kit/`) — they're build artifacts of this repo, not something to commit here.

## What gets generated

Every `<harness>-kit/` gets the same core content:

- `AGENTS.md` (rendered from `AGENTS-example.md`)
- `README.md` — a self-contained, harness-specific "how to adopt this" guide (see `write_kit_readme` in `build-kit.sh`), since the receiving team only has this directory, not this source repo. It covers the same ground as "Taking a generated kit forward" below, so update both together if that section changes.
- `docs/process.md`, `docs/team/*.agent.md`, `docs/templates/*.template.md`, `docs/discovery/*.agent.md`
- A starter `docs/project-context.md` and `docs/architecture.md`, pre-seeded from their templates
- `docs/example/` — the full worked reference (filled-in `project-context.md` + PRD), copied byte-identical. It's included so a team that only has the generated kit (not this source repo) can still see a completed example; its own README says to delete it once used, same as when hand-copying from this repo.
- Empty `docs/{prd,brd,specs,epics,stories,dev-checkpoints}/` directories (with a `.gitkeep`) so none of them are missed

**Skills get relocated, not mirrored, and no role file mentions where.** `docs/skills/<slug>/SKILL.md` in *this* repo is a real [Agent Skills](https://agentskills.io/specification) file and the authoring location. `AGENTS.md`, `docs/process.md`, `docs/team/*.agent.md`, `docs/discovery/architect.agent.md`, and `docs/templates/skill.template.md` are copied byte-identical into every kit regardless of harness — none of them name a skill path or instruct an agent to list/judge one. That's deliberate: Claude Code, OpenCode, Pi, and Codex all have a native skill mechanism that discovers and judges relevance from their own folder automatically, so `build-kit.sh` only needs to put the files there — no text to keep in sync, nothing to rewrite.

| Harness | Entry point(s) | Skill location |
|---|---|---|
| `claude-kit/` | `AGENTS.md` + `CLAUDE.md` | `.claude/skills/<slug>/SKILL.md` |
| `opencode-kit/` | `AGENTS.md` | `.opencode/skills/<slug>/SKILL.md` |
| `pi-kit/` | `AGENTS.md` | `.agents/skills/<slug>/SKILL.md` |
| `codex-kit/` | `AGENTS.md` | `.agents/skills/<slug>/SKILL.md` (same path Pi uses — both tools converged on it independently) |
| `copilot-kit/` | `AGENTS.md` + `.github/copilot-instructions.md` | `docs/skills/<slug>/SKILL.md` |

**Copilot is the one exception.** It has no native skill-discovery mechanism — nothing in Copilot itself decides to go read a skill file based on relevance, unlike the other four. Since the shared role files stay silent on purpose, `copilot-instructions.md` (a file this script writes fresh per kit, not one of the shared/copied ones) carries the one explicit instruction: read `docs/skills/*/SKILL.md` yourself and apply what's relevant. This is a known, accepted gap, not something to route around by re-adding path mechanics to the shared role files — see the root README's Gotchas section.

Every skill ships into its harness's location (not just some subset), so relevance is judged for all of them, always — there's no forced-load flag (see `docs/templates/skill.template.md`).

## Requirements on `docs/skills/*/SKILL.md`

Every skill file needs valid YAML frontmatter with a non-empty `description` field — the same field the [Agent Skills spec](https://agentskills.io/specification) already requires, so there's nothing kit-specific to fill in. The script validates this up front for every skill before building anything, and fails loudly naming the offending file if one is missing. There's deliberately no "Owner," "Always load," or bespoke Meta-table field: ownership is a repo-level concern (CODEOWNERS, not per-file boilerplate), relevance is judged by the loading agent every time rather than flagged, and everything else lives in frontmatter now that these files are real `SKILL.md`s rather than a kit-invented shape.

## Taking a generated kit forward

**This is also written as `README.md` inside every generated kit** — the version below is for browsing this source repo; the generated copy is what travels with the kit once it's copied elsewhere.

Once you've run e.g. `./scripts/build-kit.sh opencode`:

1. **Copy `opencode-kit/`'s contents into your target repo's root**, merging with whatever's already there (don't overwrite unrelated files).
2. **Fill in `docs/project-context.md`** — the single most important step: your stack, source layout, conventions, build/lint/test commands, Quality Thresholds, and Delivery Tracker (Jira / GitHub Issues / Local docs).
3. **Fill in `docs/architecture.md`** once more than one BRD/Epic exists and something is genuinely shared across them (it's optional until then — leave the starter file as-is).
4. **Add project skills directly at that harness's skill location** (e.g. `.opencode/skills/<slug>/SKILL.md`) per `docs/templates/skill.template.md`. OpenCode discovers it there on its own — `docs/team/developer.agent.md`/`reviewer.agent.md` don't need to say so, and don't. No separate `docs/skills/` copy to keep in sync, and no need to come back to this source repo unless you want the skill here too for other projects/harnesses.
5. **Wire it into your coding agent** — `CLAUDE.md` (`@AGENTS.md`) and `.github/copilot-instructions.md` are already wired for you. OpenCode auto-loads `AGENTS.md` from the project root with zero config (it traverses upward from the working directory looking for `AGENTS.md`/`CLAUDE.md`), so nothing else is required there either. For Pi/Codex, tell the harness to read `AGENTS.md` at the start of a session (or point its own instruction mechanism at it).
6. **Run it** — starting from scratch: "follow `docs/discovery/to-prd.agent.md`, let's brainstorm a PRD for X." Starting from an existing BRD or Story: tell the agent to follow `AGENTS.md` and point it at the BRD/Story — it resolves the right role itself.
7. **Keep it living** — if a human corrects an agent's behavior, fix the doc that produced the mistake (`docs/process.md`, a `docs/team/*.agent.md`, a template, or a skill) rather than just that one conversation. See `docs/process.md` → Living documents.
