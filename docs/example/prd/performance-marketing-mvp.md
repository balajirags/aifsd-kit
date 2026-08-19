# Performance Marketing Platform — MVP
> Example PRD, per `docs/templates/prd.template.md` · Path: `docs/example/prd/performance-marketing-mvp.md`

## Meta

| Field | Value |
|---|---|
| Initiative | Performance Marketing Platform (MVP) |
| Status | Draft |
| Owner | `prd` agent |
| Last updated | 2026-08-12 |

## 1. Vision

Provide performance marketers and growth ops a lightweight, unified platform to manage ad campaigns across Meta and Google, ingest spend and conversion events, and optimize budgets to improve ROAS.

## 2. Problem

Performance teams manage multiple ad platforms in spreadsheets and ad UIs, creating manual reconciliation, slow optimization cycles, and poor visibility into true campaign-level ROAS.

## 3. Goals

- Launch an MVP by 2026-10-10.
- Enable marketers to monitor spend and conversion performance across Meta and Google in one dashboard.
- Deliver basic automated budget suggestions that help users reach a sustained ROAS > 2x (user metric).
- Support 100 brands for the initial roll-out with scalable ingestion and near-real-time dashboarding.

## 4. Non-goals

- No production-grade access control, roles, or SSO for MVP (auth disabled by requirement).
- No enterprise billing, advanced attribution modeling, or deep ML-driven optimizers in MVP.

## 5. Personas and journeys

### Persona

- Performance Marketer: manages daily campaign budgets and optimizations across channels.
- Growth Ops Engineer: ingests platform-level spend/attribution data and validates data quality.

### Primary journeys

1. Connect an ad account (Meta or Google) and begin ingesting spend and conversions.
2. View unified dashboard showing spend, conversions, and ROAS by campaign and brand.
3. Receive simple budget recommendations to reallocate spend toward higher-ROAS campaigns.

## 6. Success metrics

| Metric | Target | How measured |
|---|---|---|
| Product launch | 2026-10-10 | Release date / deploy to staging & prod pipelines |
| User ROAS | > 2x (per guidance) | Before/after comparison for pilot customers over 30 days |
| Adoption | 100 brands onboarded (MVP pilot) | Number of distinct brand accounts connected |
| Data throughput | Support 1,000 campaigns/day (100 brands × 10/day) | Operational metrics from ingestion pipeline |
| Dashboard freshness | < 30s from event ingestion to surface update (near-real-time) | End-to-end pipeline latency metrics |

## 7. Scope

### In scope

- Entities: Campaigns, Ad Accounts, Brands.
- Ingestion: spend and conversion events from Meta and Google connectors.
- Storage: PostgreSQL for relational data; Redis for cache/fast lookups.
- Streaming: Kafka for decoupled ingestion and processing.
- Basic dashboard: spend, conversions, ROAS over time, top campaigns, per-brand view.
- Basic budget optimization module: simple heuristics (rule-based reallocation) producing recommendations.

### Out of scope

- User authentication, RBAC, and SSO (explicitly excluded for MVP).
- Cross-channel advanced attribution (multi-touch) and ML-driven budget optimization (deferred to post-MVP).
- Billing, invoicing, and enterprise reporting.

## 8. Assumptions

- No legal/regulatory constraints (no GDPR/CCPA requirements for MVP).
- Each brand will create ~10 campaigns per day; initial pilot = 100 brands → ~1,000 campaigns/day.
- Average events per campaign are modest; initial ingestion target ≈ 100k events/day (~1.2/s) — telemetry will drive adjustments.
- Connectors for Meta and Google provide spend and conversion event export (or webhook/CSV ingestion) for MVP.
- No auth simplifies initial rollout and testing with pilot customers.

## 9. NFR summary

| Concern | Requirement |
|---|---|
| Latency | Dashboard reflects ingested events within 30s |
| Availability | Target 99.9% uptime for ingestion and dashboard services |
| Security / compliance | Follow secure-by-default code patterns; no PII retention assumptions; secrets from env (12-factor) |
| Scale | Support 100 brands and ~1,000 campaigns/day initially; design for horizontal scale via Kafka + stateless Spring Boot services |

Implementation notes: follow 12-factor rules, structured JSON logging to stdout, parameterized DB queries (no raw SQL), and environment-driven config.

## 10. Open questions

- Event schema: which conversion event fields are required (e.g., value, currency, timestamp, attribution window)?
- Connector auth: how will pilot customers grant access to Meta/Google (tokens, CSV upload, webhook)?
- Budget optimizer: risk tolerance and allowed action cadence (daily vs hourly reallocations)?
- Telemetry & SLAs: acceptable error budgets and retention windows for raw event data?
- Pilot onboarding: who will be first 5 pilot brands and how will success be measured operationally?

## Gate 0

- [ ] Approved for BRD breakdown

- Notes for Gate 0 reviewer: confirm timeline (2026-10-10), acceptance of no-auth constraint for MVP, and approval to proceed to BRD/specification.
