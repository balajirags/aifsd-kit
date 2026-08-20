# Spec Template

> Owner: whoever writes the technical spec (no dedicated `architect` agent ships in this kit) · Path: `docs/specs/<epic-key>.md`

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

## 3. Data model (adjust to this project's persistence choice per project-context)

### Tables / collections

| Table/collection | Columns/fields | PK | FKs | Indexes |
|---|---|---|---|---|
| | | | | |

### Migration notes

- Migration tool + version:
- Backward compatible? Y/N

## 4. Cache (if applicable)

| Key pattern | Type | TTL | Invalidation |
|---|---|---|---|
| | | | |

## 5. Async / eventing (if applicable)

| Topic/queue | Key | Producer | Consumer | Ordering | DLQ |
|---|---|---|---|---|---|
| | | | | | |

## 6. Frontend impact

- Design reference (Figma / prototype): <!-- carry forward from PRD §5 Design references if one exists, or link the finalized design here -->
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
