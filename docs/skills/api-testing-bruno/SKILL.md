---
name: api-testing-bruno
description: "Bruno CLI (.bru) collections for post-implementation HTTP-contract smoke testing against a running backend"
---

# API Testing (Bruno)

> Adapted from `.agents/skills/bruno-api-testing/SKILL.md`. Runs Bruno CLI (`bru`) collections against a locally running backend as a post-implementation E2E smoke check — this is `docs/team/developer.agent.md`'s IT step (Phase 6–8) when Bruno is the project's chosen tool for it, not a replacement for unit or integration tests.

## Rules

1. One `.bru` file per scenario, not per endpoint — an endpoint with a happy path, a validation-error case, and a not-found case is three files.
2. For every endpoint created or modified by this story, cover: happy path, validation error (400), not-found (404, if applicable), and conflict/duplicate (409, if applicable).
3. Always reference `{{baseUrl}}` and other environment variables — never hardcode a URL or a host in a request file.
4. Every request file includes an `assert` block covering at least the status code; use a `tests` block for anything beyond that (response shape, field values).
5. Keep test data deterministic — use unique codes/names per run to avoid collisions, and clean up created data afterward if the API supports delete, or rely on a reset-able test database.
6. Before running, confirm the target app is actually up (poll its health endpoint) — don't fire requests at a service that hasn't finished starting.
7. On a test failure, determine whether it's a production bug or a test bug, fix it, and re-run — cap retries at 3 attempts; if still failing after that, stop and report rather than looping indefinitely.
8. Don't use Bruno for what it isn't: unit tests (use JUnit+Mockito), integration tests needing DB-state assertions (use Testcontainers), or load testing. Bruno validates the deployed HTTP contract end-to-end — it complements those, it doesn't replace them.

## Anti-patterns

- A single `.bru` file trying to cover happy path, validation error, and not-found all in one request with branching assertions — split into separate scenario files.
- Hardcoded `http://localhost:8080/...` in a request URL instead of `{{baseUrl}}` — breaks the moment the collection runs against a different environment.
- Non-deterministic test data (e.g. reusing the same fixed `code: "TEST-001"` across runs) — the second run collides with data the first run already created.
- Retrying a failing run indefinitely instead of stopping after a bounded number of attempts and reporting.
- Reaching for Bruno to assert on database state after a write — that's an integration test's job, not an HTTP-contract test's job.

## Examples

**Request + assertions:**
```
meta { name: Create Location, type: http, seq: 1 }

post {
  url: {{baseUrl}}/api/v1/locations
  body: json
}

body:json {
  { "code": "WH-TEST-001", "name": "Test Warehouse", "type": "WAREHOUSE" }
}

assert {
  res.status: eq 201
  res.body.code: eq WH-TEST-001
}

tests {
  test("should return the created location", function() {
    expect(res.getBody().type).to.equal("WAREHOUSE");
  });
}
```

**Run a module's collection against the local environment:**
```bash
until curl -sf http://localhost:8080/actuator/health > /dev/null 2>&1; do sleep 2; done
bru run api-tests/locations/ --env local
```
