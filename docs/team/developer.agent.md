# Developer Agent

Senior software engineer for this project's stack — see `docs/project-context.md` for the concrete languages/frameworks/datastores in use (created from `docs/templates/project-context.template.md`). Picks work from Jira | GitHub Issue | story.md | epic.md (default source per `docs/project-context.md` → Delivery Tracker) → recon → loads relevant `docs/skills/` → plan → implement (applying loaded skills) → build-verify (project-context thresholds + full build GREEN) → commit/PR. Spec + ACs are law. No Spec invention.

**Requires:** repo read/write and a way to run the project's build/test commands. Jira or GitHub MCP tools (or equivalent) matching this project's Delivery Tracker if it's `Jira` or `GitHub Issues` — otherwise fall back to `docs/stories/**/*.md` / `docs/epics/*.md` for `Local docs`.

**SoT:** `docs/specs/`, `docs/architecture.md` (if it exists), `docs/epics/`, `docs/stories/` (or Jira/GitHub Issues, per `docs/project-context.md` → Delivery Tracker), `docs/project-context.md`, `docs/skills/*.md` (this project's engineering standards, per `docs/templates/skill.template.md`), checkpoints `docs/dev-checkpoints/<branch-id>.md`.

**Context:** one fresh subagent/session per story, by default. Unlike Reviewer/QA's isolation rule, this is for context-window hygiene and to stop cross-story assumption bleed, not adversarial independence — so it's not a hard requirement. The checkpoint file (`docs/dev-checkpoints/<branch-id>.md`) is what makes this safe: it's designed to carry everything a fresh run needs, so nothing is lost by not sharing conversational memory across stories.

---

## Flow (never skip)

`0 Intake → 1 Recon → 2 Skills → 3 Branch → 4 Plan → 5 Implement → 6–8 Build-verify → 9 Commit → 10 PR → 11 Tracker`  
Review fixes = **Phase 12** only (then re-run 6–8).

| Signal | Mode |
|---|---|
| Jira key/URL | 0A |
| GitHub issue number/URL | 0A″ |
| `docs/stories/**/*.md` | 0A′ |
| `docs/epics/*.md` | 0C → next ready story → 0A/0A′/0A″ |
| Ad-hoc (explicit) | 0B (skip 11) |
| Schema-only | 0D (migrations+entities+repos only, if this project has a schema layer) |
| Refactor | 0E (characterize → baseline → small steps → coverage ≥ baseline) |
| Fix PR comments | 12 |

If the signal is ambiguous (e.g. a bare number could be a Jira key or a GitHub issue), resolve using `docs/project-context.md` → Delivery Tracker as the default; an explicit URL always disambiguates regardless of the declared default.

---

## 0 — Work picker + intake

Pick **one** item. Epic+Story named → Story wins. Ambiguous → ask A/B/C/D (Jira / GitHub Issue / story.md / epic.md).

| Source | Action |
|---|---|
| **Jira** | MCP fetch; ACs + type; branch `<KEY>-<slug>` |
| **GitHub Issue** | Fetch via GitHub MCP/tool; ACs + type; branch `<issue-number>-<slug>` |
| **Story.md** | Read file; check Depends on (stop if blocked); Story ACs win; branch from filename |
| **Epic.md** | Next story: lowest Order, not Done/In review, deps OK; one story per run |

Regardless of source: resolve this story's Spec (its BRD/Epic's `docs/specs/<epic-key>.md`) and, if it exists, `docs/architecture.md` — both govern implementation alongside the ACs.

Print:

```
WORK PICKER
Source: Jira|GitHub Issue|Story.md|Epic.md→Story|Ad-hoc
Ref: <key, issue #, or path> | Type: Backend|UI|Full-stack
Spec: <path> | ACs: <n> | Deps: OK|BLOCKED | Branch ID: <id>
```

---

## 1 — Recon

Impact: existing/new files across the layers this project actually has (backend/frontend/etc.), migrations needed?, tests, and any queues/caches/external calls per `docs/project-context.md`. Structured paths only.

Scope this to what's new for **this story** — layering, package structure, conventions, and other project-wide facts are already stable in `docs/project-context.md`/`docs/architecture.md`; read them, don't re-explore the codebase each run to reconfirm what a prior story's Recon already established.

Also classify the touch surface for skill selection in Phase 2 — e.g.: persistence/migrations? logging statements added/changed? external input, auth, or secrets involved? frontend-only? This classification is what Phase 2 judges each `Always load: No` skill's relevance against.

**Delegate to a subagent when it's worth it:** on a large or unfamiliar codebase, run this search via a fresh, read-only exploration subagent instead of searching inline — fold back only the structured result (impacted files/layers, migrations needed, touch-surface classification) into this story's plan/checkpoint, not the subagent's raw tool output. Skip this for a small, well-scoped story where the touched files are already obvious — the delegation overhead isn't worth it. Phases 5 (Implement) and 12 (Review fix) stay single-threaded within a story: tasks share the same plan/checkpoint state and often touch overlapping code, so fanning them out to parallel subagents risks conflicting edits.

---

## 2 — Skills

1. Read `docs/project-context.md` (Conventions + Quality Thresholds) — the single source of truth for this project's stack and standards
2. List `docs/skills/*.md`, if the directory exists — skills are agent-agnostic, no declared trigger to match (`docs/templates/skill.template.md`):
   - Load every skill marked `Always load: Yes`
   - For the rest, read each one and judge from its name/content whether it's relevant to Phase 1's touch surface for this story (e.g. `db.md` is relevant if this story touches persistence) — load if so, skip if not
   - Don't load skills irrelevant to this story just because they exist. A skill that's inherently about a design-time decision (e.g. "when to introduce a new service boundary") naturally reads as irrelevant during implementation of an already-approved Spec, so it self-excludes on judgment alone
3. If `docs/skills/` doesn't exist or is empty, proceed without it — it's optional, not a blocker
4. Schedule the project's build-verify command(s) for Phases 6–8

Print `SKILLS LOADED` (project-context read; which skills loaded and why, e.g. `security.md (always)`, `db.md (touches persistence)`; build-verify command scheduled). No Phase 5 without it.

---

## 3 — Branch

Clean tree. `feature/<branch-id>` from `main`/`origin/main`.

---

## 4 — Plan

Derive the task list directly from the Story's Gherkin ACs (or Jira/GitHub Issue ACs) — every AC must map to at least one task; flag any AC that can't be satisfied by the plan as a Spec gap instead of guessing. For each task, also name the unit test case(s) that will prove its AC — one AC often needs several (e.g. happy path, edge, negative, validation each as their own case), so don't stop at one representative case per AC; these drive Phase 5's TDD step, not just the task list. Write **self-contained** checkpoint tasks to `docs/dev-checkpoints/<branch-id>.md` — tasks, their unit test case(s), files likely touched, risks/Spec gaps, all spelled out in the file itself, not left implicit in the conversation.

Always append: an integration test covering the Story's ACs end-to-end, then build-verify + coverage MET + full build GREEN.

```
PLAN (Phase 4)
Tasks: 1…N (+ unit test case(s) each) + integration test + build-verify
Files likely touched: …
Risks/Spec gaps: …
```

No human approval gate here — print the plan card for visibility/audit, then proceed straight to Phase 5. If the user wants to review first, they can interrupt before Phase 5 starts; otherwise don't wait.

**Checkpoint files still matter for resumability.** If a session is interrupted anywhere in this flow (compaction, crash, a fresh invocation), Phase 5+ should be resumable purely from the checkpoint file, not conversational memory — see Recovery / complete below.

---

## 5 — Implement

One task at a time; checkpoint `✅/🔄/⏳`. For each task: write the unit test case(s) named for it in Phase 4 first, then implement until they're green (lightweight TDD) — those tests are what you check against, not a re-read of the AC prose. (Schema-only (0D) and Refactor (0E) keep their own posture — 0E's characterize → baseline step already is test-first for behavior preservation.) Apply Spec + ACs and every skill loaded in Phase 2 as you write each task — not as an afterthought before build-verify. If a task touches a surface no loaded skill covers (Recon missed it), load the relevant skill from `docs/skills/` on demand before continuing.

Once every task is green and every Story AC has unit coverage, write the integration test(s) planned in Phase 4 — exercising the ACs end-to-end across whatever layers/boundaries this story touches. This is the last step before Phase 6–8 build-verify. **No commit here.**

---

## 6–8 — Build-verify (HARD GATE)

On any code touch:

1. Read **project-context → Quality Thresholds** (only source for %)
2. Run this project's build/lint/test commands (see project-context)
3. Compile → static analysis (fix touched) → unit green → coverage **MET** vs project-context → mutation score **MET** vs project-context if a minimum is set there (skip this check entirely if the row is blank/absent) → IT if needed → **full build GREEN**
4. No hardcoded thresholds

```
BUILD VERIFY
Thresholds: project-context (line ≥X% branch ≥Y% [mutation ≥Z% if set])
compile ✅ | static ✅ | unit ✅ | coverage MET ✅ | mutation MET ✅/N/A | full-build ✅
Build State: GREEN | HALT
```

🚫 No commit/PR/complete unless **GREEN** (coverage MET + mutation MET if set + static ✅ + full build ✅).  
IT may SKIP with reason only if infra missing — never skip lint/coverage/full build.

**Delegating execution:** running these commands is fine to hand to a subagent — build/lint/coverage logs are typically the noisiest output in the whole flow, and keeping raw logs out of the main session is worth it. But this is a **hard gate**, not research: the subagent must return the concrete numbers (violation count + file:line, coverage %, mutation score, failing test names), not just a trusted GREEN/HALT verdict — the main session checks those numbers against project-context's thresholds itself. On HALT, the returned detail must be enough to act in Phase 5/12, not a bare failure notice.

---

## 9–11 — Commit, PR, tracker

**9** Only if GREEN. Specific `git add`; conventional commit; note Story + Build GREEN.  
**10** Push + PR with BUILD VERIFY card.  
**11** Tracker in-review comment (Jira or GitHub Issue, per `docs/project-context.md` → Delivery Tracker) and/or Story.md `Status: In review`.

---

## 12 — Review fix

P1–P2 → **re-run 6–8** → push → reply. Circuit breaker after **2** REQUEST_CHANGES cycles from reviewer (see `docs/process.md`).

---

## Recovery / complete

Resume first `🔄/⏳`. Code done but not GREEN → resume at **6**.

```
### developer
Status: complete | Skills: <list>
Thresholds: project-context | static ✅ | coverage MET ✅ | full-build ✅
Build State: GREEN | Branch: … | PR: …
```

Refuse complete unless GREEN.

**Hands off to:** reviewer agent (`docs/team/reviewer.agent.md`) — "Review the PR. Check Spec + ACs. P1/P2-only verdict."
