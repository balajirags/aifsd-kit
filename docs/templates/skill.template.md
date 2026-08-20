---
name: <skill-slug>
description: <one or two sentences: what this skill covers and when to use it — specific enough for a harness's own relevance-matching to act on>
---

> One skill = one concern (e.g. `security`, `db`, `logging`). Keep each self-contained — every agent loads skills individually, not as a bundle. Save this file as `<skill-slug>/SKILL.md` under wherever your harness keeps skills (its native skill folder if it has one — see your harness's own docs; `docs/skills/` otherwise).

This is a real [Agent Skills](https://agentskills.io/specification) `SKILL.md` — the same shape Claude Code, OpenCode, Codex, and Pi read natively and discover on their own from their native skill folder. `scripts/build-kit.sh` places it there for you when generating a harness-specific kit; nothing in this file is kit-specific.

No role/agent tag and no declared trigger condition — skills are **agent-agnostic**, and relevance is always judged, never matched or forced. A harness with native skill support discovers and judges every skill's relevance itself, automatically — no role file needs to list a directory or decide when to read one. Whichever agent ends up applying a skill's guidance still filters it to its own job (e.g. Reviewer applies only P1/P2-relevant rules from a skill; Architect applies only design-level ones) — that filtering is the applying agent's own responsibility, driven by its own rubric, not something this file declares.

## Rules

<!-- Concrete, checkable rules — not generic advice. Prefer "do X" / "never Y" over "write clean code." -->

1.
2.

## Anti-patterns

<!-- Specific things this project has seen go wrong, or common mistakes for this stack. -->

-

## Examples

<!-- Optional: a short before/after or a canonical snippet for this project's stack. -->
