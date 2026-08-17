# Spec Template

> Owner: `architect` agent · Path: `docs/specs/<epic-key>.md`

## Meta

| Field | Value |
|---|---|
| Epic | `<EPIC-KEY>` |
| BRD | `docs/brd/<slug>.md` |
| Status | Draft / Approved |
| Author | |

## 1. Context and goals

## 2. REST API contract

| Method | Path | Request | Response | Errors |
|---|---|---|---|---|
| | `/api/v1/...` | | | |

### Example payloads

```json
{}
```

## 3. Postgres model

### Tables

| Table | Columns | PK | FKs | Indexes |
|---|---|---|---|---|
| | | | | |

### Migration notes

- Flyway version:
- Backward compatible? Y/N

## 4. Redis

| Key pattern | Type | TTL | Invalidation |
|---|---|---|---|
| `app:...` | | | |

## 5. Kafka

| Topic | Key | Producer | Consumer | Ordering | DLQ |
|---|---|---|---|---|---|
| `domain.context.event.v1` | | | | | |

## 6. Frontend impact

- Routes/pages:
- Components/state:
- API client methods:

## 7. ADRs

### ADR-001: Title

- Context:
- Decision:
- Consequences:

## 8. Security and 12-factor

- Authz rules:
- Secrets / config:
- PII considerations:
