# Process — AI-augmented delivery

How work is organized in this repo. Agents must follow this file every session.

## Roles
 
1. **ba.agent** — Breaks Brd into stories. Slice stories (no CRUD mega-stories; FE by screen/flow) + Gherkin tables → human: `Stories approved`. Follows `docs/team/ba.agent.md`
2. **developer.agent** — Responsible for reading groomed tasks, implementing code, and writing results back to the repository. Follows `docs/team/developer.agent.md`
3. **reviewer.agent** — Read-only P1/P2-only review (security/critical + architecture/Spec/boundary drift; no style/test nits) of the developer's diff/PR against Spec + ACs; verdict gates whether QA runs. Follows `docs/team/reviewer.agent.md`
4. **qa.agent** — Validates ACs against a running app in a fresh/isolated context (P1/P2-only for any incidental defects) and posts PASS/FAIL/BLOCKED verdicts to the backlog. Follows `docs/team/qa.agent.md`


## Orchestrator (The Workflow)

The Orchestrator is a pure management layer. It does not perform any coding, grooming, reviewing, or testing.

**Responsibilities:**
1. **Dispatch**: Select the next item from the backlog and launch the appropriate agent.
2. **Lifecycle Management**: Trigger the BA → Developer → Reviewer → QA graph below.
3. **Decision Making**: Route on each stage's verdict per the edges below; close the issue only on QA `PASS`.

**Lifecycle graph:**

```text
Pick issue → BA (stories + ACs)
           → Developer (implement + build-verify gate)
           → Reviewer (P1/P2-only verdict, fresh/isolated context, ideally a different model — see docs/team/reviewer.agent.md)
                ├─ APPROVE                        → QA
                ├─ REQUEST_CHANGES, cycles < 2     → back to Developer
                └─ REQUEST_CHANGES, cycles ≥ 2     → circuit breaker: escalate to human, stop
           → QA (validate ACs against running app; fresh/isolated context, P1/P2-only defect tagging — see docs/team/qa.agent.md)
                ├─ PASS → close issue, repeat from next backlog item
                └─ FAIL → back to Developer
```

Steps, in order:
1. Pick the next open issue from the backlog
2. Launch BA Agent to groom it
3. Launch Developer Agent to implement it
4. Launch Reviewer Agent **in a fresh, isolated context** (new subagent/session — never continuing the Developer's conversation) on the resulting diff/PR
5. If Reviewer returns **REQUEST_CHANGES** and cycle count is **< 2**, loop back to step 3
6. If Reviewer returns **REQUEST_CHANGES** and cycle count is **≥ 2**, stop and escalate to a human (circuit breaker) — do not loop automatically
7. If Reviewer returns **APPROVE**, launch QA Agent to verify it
8. If QA returns **FAIL**, loop back to step 3
9. If QA returns **PASS**, close the issue
10. Repeat until the backlog is empty

**Known asymmetry:** the Reviewer↔Developer loop is capped at 2 `REQUEST_CHANGES` cycles before escalating to a human. The QA↔Developer loop has no such cap today — a story can bounce between Developer and QA indefinitely. This is called out deliberately rather than left ambiguous; add a cap here (mirroring Reviewer's) if your team hits runaway QA loops in practice.

## Developer rules

1. Resolve **one** work item: Jira key, `docs/stories/**/*.md`, or `docs/epics/*.md` (next ready story)
2. **Read** whichever `docs/skills/*.md` apply to this task (always-on skills, plus any matching what Recon found — see `docs/team/developer.agent.md` Phase 1–2); empty/missing directory is not a blocker
3. Print PLAN card (tasks derived from Story ACs, files touched, Spec gaps) for visibility, then proceed straight to implementation — no human approval gate after planning
4. Implement against Spec + ACs only; flag Spec gaps
5. On any code touch, run build-verify:
   - Thresholds from `project-context` → Quality Thresholds only
   - Static analysis clean on touched files
   - Unit tests green
   - Coverage **MET**
   - **Full build GREEN**
6. No commit / PR / “complete” unless Build State is GREEN
7. Commit meaningfully after green slices; never force-push shared main

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


