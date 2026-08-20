# Architecture Template

> Owner: whoever owns this project's cross-cutting architecture (maintained by `docs/discovery/architect.agent.md`) · Path: `docs/architecture.md`
> System-wide, beyond any one BRD/Epic's Spec — covers what's shared across Specs (cross-cutting decisions, shared components, system-wide constraints). One document per project, spans all BRDs. Optional: only needed once more than one BRD/Epic exists and something is genuinely shared between them.

## Meta

| Field | Value |
|---|---|
| Status | Draft / Approved |
| Author | |
| Last updated | |

## 1. System context

<!-- One diagram or short description: this system's boundaries, its major external dependencies, who/what talks to it. -->

## 2. Cross-cutting components

<!-- Shared services/modules/libraries used by more than one BRD/Epic — what they own, who owns them. -->

| Component | Owns | Used by (BRD/Epic) |
|---|---|---|
| | | |

## 3. Cross-cutting data flows

<!-- Sequence/flow that spans more than one BRD/Epic's Spec — e.g. an event chain, a shared cache, a shared queue. -->

## 4. System-wide constraints

<!-- Non-functional constraints that apply everywhere: scaling limits, compliance/regulatory requirements, multi-tenancy rules, data-residency rules. -->

## 5. ADRs (cross-cutting only — a decision scoped to one BRD belongs in that BRD's Spec instead)

### ADR-001: Title

- Context:
- Decision:
- Consequences:
