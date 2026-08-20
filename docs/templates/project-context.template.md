# Project Context

> Owner: whoever owns delivery for this repo · Path: `docs/project-context.md`
> Copy this template to `docs/project-context.md` and fill in every section for your project. See `docs/example/project-context.md` for a fully filled-in reference.

## What We Are Building

<!-- Customize: link the PRD, e.g. @`docs/prd/<initiative>.md` -->

<!-- Customize: one-paragraph product description -->

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | |
| Backend language | |
| Backend framework | |
| Build (BE) | |
| Persistence | |
| Migrations | |
| Cache | |
| Messaging | |
| Auth | |
| HTTP clients | |
| Resilience | |
| BE tests | |
| FE tests | |

## Delivery Tracker

**Single source of truth** for where Epics/Stories live and how status gets posted back. `ba.agent`, `developer.agent`, and `qa.agent` all read this to know their default; an explicit Jira key / GitHub issue URL / file path given in a specific request always overrides this default for that one run.

| Field | Value |
|---|---|
| Tracker | `Jira` \| `GitHub Issues` \| `Local docs` (`docs/epics/`, `docs/stories/`) |
| Jira project key | <!-- if Jira --> |
| GitHub repo | <!-- if GitHub Issues, e.g. org/repo --> |

If `Local docs`, `docs/stories/<epic-slug>/` is the only place stories live. If `Jira` or `GitHub Issues`, stories live there **and** get a markdown mirror in `docs/stories/<epic-slug>/` for offline reading — the tracker is still authoritative for status.

## Architecture

- **Layering (BE):** <!-- e.g. Controller → Service → Repository -->
- **Package/module structure:** <!-- e.g. com.company.app.<module>.{api,service,domain,repository,config,messaging} -->
- **Error handling:** <!-- e.g. domain exceptions + shared error handler -->
- **Config:** env vars / profiles — never commit secrets
- **Frontend:** <!-- e.g. feature folders under frontend/src/ talking to the API via typed clients -->

## Source Layout

| Area | Path |
|---|---|
| Backend root | |
| Backend source | |
| Backend tests | |
| Migrations | |
| Backend config | |
| Frontend root | |
| Frontend source | |
| PRDs | `docs/prd/` |
| BRDs | `docs/brd/` |
| Specs | `docs/specs/` |

> Always create new files in the path matching their layer.

## Conventions

- REST paths: <!-- e.g. kebab-case under /api/v1/... -->
- DTOs / domain types: <!-- e.g. records for DTOs, entities for domain -->
- DB columns / language field casing: <!-- e.g. snake_case columns, camelCase fields -->
- Messaging topic naming: <!-- if applicable -->
- Cache key naming: <!-- if applicable -->
- FE component / hook naming: <!-- if applicable -->

## Commands

**Single source of truth** for how to build, test, lint, and run this project. `developer.agent` reads this for Build-verify (Phases 6–8) and for running the app during development; `AGENTS.md` mirrors just the everyday ones for quick reference without a second file read — if the two ever drift, this file wins.

| Purpose | Command |
|---|---|
| Install / setup | |
| Compile | |
| Static analysis / lint | |
| Unit tests + coverage | |
| Integration tests (if separate) | |
| Full build gate (must be GREEN before commit) | |
| Run locally (backend) | |
| Run locally (frontend) | |

Split into separate Backend/Frontend tables if one set of rows can't cover both — see `docs/example/project-context.md` for a filled two-stack instance.

## Quality Thresholds

**Single source of truth** for the developer agent and any build-verify step.
Agents must **Read** this section before implementing and enforce these numbers — do not hardcode different defaults.

| Metric | Minimum |
|---|---|
| Line coverage (backend, touched production files) | |
| Branch coverage (backend, touched production files) | |
| Line/statement coverage (frontend, touched files) | |
| Mutation score (touched files, optional — see below) | |
| Static analysis (touched files) | 0 new violations |
| Unit tests | All passing |
| Full build / package | Must be GREEN |

Mutation score is optional: leave the row blank/delete it if this stack has no mature mutation-testing tool (e.g. PIT for Java, Stryker for JS/TS). When a minimum is set here, `developer.agent` enforces it in build-verify the same way as coverage — line/branch coverage alone doesn't catch a test that passes without asserting anything meaningful.

**Pre-commit rule:** Do not commit unless compile, static analysis, unit tests, coverage thresholds, mutation score (if set above), and the full build command are all green.
