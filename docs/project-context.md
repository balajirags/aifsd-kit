# Project Context

## What We Are Building

Understand the product and its context from prd file @`docs/prd/performance-marketing-mvp.md`.

<!-- Customize: one-paragraph product description -->
A fullstack application with a React SPA frontend and a Spring Boot API backend. PostgreSQL is the system of record; Redis is used for caching/short-lived state; Kafka carries domain events between services.

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | React + Vite + TypeScript |
| Backend language | Java 21 |
| Backend framework | Spring Boot 3.x |
| Build (BE) | Gradle |
| Persistence | Spring Data JPA + PostgreSQL |
| Migrations | Flyway |
| Cache | Spring Data Redis |
| Messaging | Spring Kafka |
| Auth | Spring Security + JWT |
| HTTP clients | Spring Cloud OpenFeign (when calling other services) |
| Resilience | Resilience4j |
| BE tests | JUnit 5, Mockito, AssertJ, Testcontainers |
| FE tests | Vitest, Playwright (E2E) |

## Architecture

- **Layering (BE):** Controller → Service → Repository
- **Package structure:** `com.company.app.<module>.{api,service,domain,repository,config,messaging}`
- **Error handling:** Domain exceptions + `@ControllerAdvice`
- **Config:** env vars / Spring profiles — never commit secrets
- **Frontend:** feature folders under `frontend/src/` talking to the API via typed clients

## Source Layout

| Area | Path |
|---|---|
| Backend root | `backend/` |
| Backend source | `backend/src/main/java/com/company/app/` |
| Backend tests | `backend/src/test/java/com/company/app/` |
| Flyway | `backend/src/main/resources/db/migration/` |
| Backend config | `backend/src/main/resources/application.yml` |
| Frontend root | `frontend/` |
| Frontend source | `frontend/src/` |
| PRDs | `docs/prd/` |
| BRDs | `docs/brd/` |
| Specs | `docs/specs/` |

> Always create new files in the path matching their layer.

## Conventions

- REST paths: `kebab-case` under `/api/v1/...`
- DTOs: Java records; domain: JPA `@Entity`
- DB columns: `snake_case`; Java fields: `camelCase`
- Kafka topics: `domain.context.eventName.v1`
- Redis keys: `app:<bounded-context>:<entity>:<id>`
- FE components: PascalCase; hooks: `use*` prefix

## Quality Thresholds

**Single source of truth** for the developer agent and `build-verify` skill.
Agents must **Read** this section before Phases 6–8 and enforce these numbers — do not hardcode different defaults.

| Metric | Minimum |
|---|---|
| Line coverage (backend, touched production files) | 80% |
| Branch coverage (backend, touched production files) | 70% |
| Line/statement coverage (frontend, touched files) | 80% |
| Static analysis (touched files) | 0 new violations |
| Unit tests | All passing |
| Full build / package | Must be GREEN |

**Pre-commit rule:** Do not commit unless compile, static analysis, unit tests, coverage thresholds, and the profile **full build** command are all green.
