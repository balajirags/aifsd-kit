# Skill Template

> Owner: whoever owns engineering standards for this repo · Path: `docs/skills/<skill-slug>.md`
> One skill = one concern (e.g. `security.md`, `db.md`, `logging.md`). Keep each self-contained — every agent loads skills individually, not as a bundle.

## Meta

| Field | Value |
|---|---|
| Skill | `<name>` |
| Always load | Yes \| No |

No role/agent tag and no declared trigger condition — skills are **agent-agnostic**, and relevance is judged, not matched. Any agent (Developer, Reviewer, Architect, or others this kit adds later) lists `docs/skills/*.md` and, for each one where **Always load** is `No`, decides from the skill's own name and content whether it's relevant to the task at hand — no separate condition string to keep in sync with the content. `Always load: Yes` skips that judgment entirely (e.g. a blanket security policy that should never be skipped). Each agent still applies only the guidance relevant to its own job either way (e.g. Reviewer applies only P1/P2-relevant rules from a loaded skill; Architect applies only design-level ones) — that filtering is the loading agent's own responsibility, driven by its own rubric.

## Rules

<!-- Concrete, checkable rules — not generic advice. Prefer "do X" / "never Y" over "write clean code." -->

1.
2.

## Anti-patterns

<!-- Specific things this project has seen go wrong, or common mistakes for this stack. -->

-

## Examples

<!-- Optional: a short before/after or a canonical snippet for this project's stack. -->
