# Skill Template

> Owner: whoever owns engineering standards for this repo · Path: `docs/skills/<skill-slug>.md`
> One skill = one concern (e.g. `security.md`, `db.md`, `logging.md`). Keep each self-contained — developer.agent loads skills individually, not as a bundle.

## Meta

| Field | Value |
|---|---|
| Skill | `<name>` |
| Applies when | `always` \| `<condition Recon can check, e.g. "touches persistence">` |
| Scope | Developer only \| Developer + Reviewer |

## When to load

<!-- One or two lines a Recon step can pattern-match against, e.g.:
"Story touches a datastore: new/changed entity, repository, migration, or raw query." -->

## Rules

<!-- Concrete, checkable rules — not generic advice. Prefer "do X" / "never Y" over "write clean code." -->

1.
2.

## Anti-patterns

<!-- Specific things this project has seen go wrong, or common mistakes for this stack. -->

-

## Examples

<!-- Optional: a short before/after or a canonical snippet for this project's stack. -->
