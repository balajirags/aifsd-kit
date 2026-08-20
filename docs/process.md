# Process — AI-augmented delivery

How work is organized in this repo. Agents must follow this file every session.

## Roles
 
1. **ba.agent** — Breaks Brd into stories. Slice stories (no CRUD mega-stories; FE by screen/flow) + Gherkin tables → human: `Stories approved`. Follows `docs/team/ba.agent.md`
2. **developer.agent** — Responsible for reading groomed tasks, implementing code, and writing results back to the repository. Follows `docs/team/developer.agent.md`
3. **reviewer.agent** — Read-only P1/P2-only review (security/critical + architecture/Spec/boundary drift; no style/test nits) of the developer's diff/PR against Spec + ACs; verdict gates whether QA runs. Follows `docs/team/reviewer.agent.md`
4. **qa.agent** — Validates ACs against a running app in a fresh/isolated context (P1/P2-only for any incidental defects) and posts PASS/FAIL/BLOCKED verdicts to the backlog. Follows `docs/team/qa.agent.md`

## Upstream authoring (outside this graph)

BRDs (and the PRD/architecture/Spec behind them) can be hand-authored against `docs/templates/`, or via the optional `docs/discovery/to-prd.agent.md` → `to-brd.agent.md` → `architect.agent.md` chain — sustained, human-in-the-loop co-authoring sessions gated on each template's own approval field, not this file's build-verify/circuit-breaker mechanics. Not part of the Orchestrator's graph below.

Execution doesn't start on a subset: the whole initiative — PRD approved, every BRD Ready for Spec, the HLD (`docs/architecture.md`) approved, and every BRD's Spec approved — must be finalized first (`architect.agent.md`'s Finalization check). Only then does a BRD produced this way enter the Orchestrator's queue below (a standalone Story bypasses this whole discovery chain — see the Orchestrator's Input).

## Orchestrator (The Workflow)

The Orchestrator is a pure management layer. It does not perform any coding, grooming, reviewing, or testing.

**Input:** a queue of work items — a **BRD** (`docs/brd/<epic-slug>.md`), an **Epic** (`docs/epics/*.md`), or an **already-groomed Story** (Jira key, GitHub issue, or `docs/stories/**/*.md`). Each BRD/Epic is **one Epic** (see AGENTS.md → Delivery model); the Orchestrator works one Epic at a time, and within it, one story at a time.

**Responsibilities:**
1. **Dispatch**: Take the next item off the queue and check whether a ready, groomed story (with Gherkin ACs) already exists for it — under `docs/stories/<epic-slug>/`, or because the item is itself a specific Story/Jira key/GitHub issue reference. **No groomed story yet** → hand to BA first. **Already groomed** (this run or a prior one) → skip BA, hand straight to Developer. This is a state check, not a check on how the item was labeled — a BRD whose stories were already groomed in an earlier pass skips BA exactly like a standalone Story does; BA is never re-run just because the queue item happens to say "BRD."
2. **Lifecycle Management**: Trigger the BA (if needed) → Developer → Reviewer → QA graph below.
3. **Decision Making**: Route on each stage's verdict per the edges below; close a story only on QA `PASS`; close the item once every story for its Epic is closed.

**Lifecycle graph:**

```text
Pick next item from the queue (BRD / Epic / already-groomed Story)
  → Groomed story already exists for it?
       NO  → BA: break into stories + Gherkin ACs — see docs/team/ba.agent.md
       YES → skip BA

  → for each ready story (one at a time):
       Developer (implement + build-verify gate)
       → Reviewer (P1/P2-only verdict, fresh/isolated context, ideally a different model — see docs/team/reviewer.agent.md)
            ├─ APPROVE                        → QA
            ├─ REQUEST_CHANGES, cycles < 2     → back to Developer
            └─ REQUEST_CHANGES, cycles ≥ 2     → circuit breaker: escalate to human, stop
       → QA (validate ACs against running app; fresh/isolated context, P1/P2-only defect tagging — see docs/team/qa.agent.md)
            ├─ PASS → close story, next ready story for this item
            └─ FAIL → back to Developer

  → when every story for this item is closed → pick next item from the queue
```

Steps, in order:
1. Pick the next item from the queue
2. Check for an existing groomed story: none yet → launch BA Agent to break it into stories with Gherkin ACs (Epic groom) — stop for **Stories approved** per `docs/team/ba.agent.md` — then continue to step 3. Already groomed → skip straight to step 3.
3. Pick the next ready story for this item (lowest Order, not Done/In review, deps OK)
4. Launch Developer Agent to implement it, in a fresh context/session by default (see Developer rules)
5. Launch Reviewer Agent **in a fresh, isolated context** (new subagent/session — never continuing the Developer's conversation) on the resulting diff/PR
6. If Reviewer returns **REQUEST_CHANGES** and cycle count is **< 2**, loop back to step 4
7. If Reviewer returns **REQUEST_CHANGES** and cycle count is **≥ 2**, stop and escalate to a human (circuit breaker) — do not loop automatically
8. If Reviewer returns **APPROVE**, launch QA Agent to verify it
9. If QA returns **FAIL**, loop back to step 4
10. If QA returns **PASS**, close the story; repeat from step 3 until every story for this item is closed (a standalone Story has just the one, so it closes immediately)
11. Once the item is fully closed, repeat from step 1 until the queue is empty

**Known asymmetry:** the Reviewer↔Developer loop is capped at 2 `REQUEST_CHANGES` cycles before escalating to a human. The QA↔Developer loop has no such cap today — a story can bounce between Developer and QA indefinitely. This is called out deliberately rather than left ambiguous; add a cap here (mirroring Reviewer's) if your team hits runaway QA loops in practice.

## Developer rules

1. Resolve **one** work item: Jira key, `docs/stories/**/*.md`, or `docs/epics/*.md` (next ready story)
2. Run each story in a **fresh context/session by default** (new subagent/session per story) — unlike Reviewer/QA's isolation (below), this is for context-window hygiene and to stop cross-story assumption bleed, not adversarial independence. Not a hard rule: continuing straight from BA's `Stories approved` into the first story's kickoff in the same session is a fine efficiency call if the harness makes that convenient
3. **Read** whichever `docs/skills/*.md` apply to this task (always-on skills, plus any matching what Recon found — see `docs/team/developer.agent.md` Phase 1–2); empty/missing directory is not a blocker
4. Print PLAN card (tasks derived from Story ACs, files touched, Spec gaps) for visibility, then proceed straight to implementation — no human approval gate after planning
5. Implement against Spec + ACs only; flag Spec gaps
6. On any code touch, run build-verify:
   - Thresholds from `project-context` → Quality Thresholds only
   - Static analysis clean on touched files
   - Unit tests green
   - Coverage **MET**
   - **Full build GREEN**
7. No commit / PR / “complete” unless Build State is GREEN
8. Commit meaningfully after green slices; never force-push shared main

## Story quality

- Gherkin ACs as `| Scenario | Given | When | Then |` tables
- Business language in AC cells; endpoints only under Spec coverage
- Backend resource APIs: separate Create / Read-List / Update / Delete stories
- Frontend: one story per screen/flow — not per component; not one “all UI” mega-story
- Out of scope must link a follow-up story/issue — do not silently drop scope

## Living documents

When the human corrects behavior or standards:

1. Commit or stash current code work if needed
2. Update the relevant file (`project-context`, Spec, story, skill, this process, agent)
3. Confirm what changed so the next session inherits the fix

## Definition of Done (merge)

- [ ] Spec + ACs were specific enough to execute
- [ ] Build-verify GREEN (thresholds from project-context)
- [ ] Reviewer returns APPROVE (no open P1 or P2)
- [ ] QA PASS on ACs (or human waived with reason)
- [ ] A human has read and understood the AI-authored code and tests


