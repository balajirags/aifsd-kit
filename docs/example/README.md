# Worked example

This folder is a fully filled-in instance of the AI-augmented delivery kit, for a fictional **Performance Marketing Platform MVP** (React + Vite + TypeScript frontend, Java 21 / Spring Boot backend, PostgreSQL, Redis, Kafka). It exists to show what a completed `docs/project-context.md` and PRD look like — it is not part of the kit itself.

- `project-context.md` — a worked example of `docs/templates/project-context.template.md`, filled in for this fictional stack.
- `prd/performance-marketing-mvp.md` — a worked example PRD, per `docs/templates/prd.template.md`.

## Adopting this kit in your own repo

Copy these into your repo as-is:

- `AGENTS.md`
- `docs/process.md`
- `docs/team/` (ba, developer, reviewer, qa role files)
- `docs/templates/` (BRD, PRD, Spec, Story, project-context templates)

Then, for your own project:

1. Copy `docs/templates/project-context.template.md` to `docs/project-context.md` and fill it in — use `docs/example/project-context.md` as a reference for the level of detail expected, not as a value to copy.
2. Write your own PRD under `docs/prd/` using `docs/templates/prd.template.md` (or use `docs/example/prd/performance-marketing-mvp.md` as a reference for shape/tone).
3. Do **not** copy this `docs/example/` folder into your repo — delete it once you've used it as reference.
