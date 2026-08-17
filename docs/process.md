# Process — AI-augmented delivery

How work is organized in this repo. Agents must follow this file every session.

## Roles
 
1. **ba.agent** — Breaks Brd into stories. Slice stories (no CRUD mega-stories; FE by screen/flow) + Gherkin tables → human: `Stories approved`. Follows `docs/team/ba.agent.md`
2. **developer.agent** — Responsible for reading groomed tasks, implementing code, and writing results back to the repository. Follows `docs/team/developer.agent.md`
3. **qa.agent** — Responsible for reading implementation/tests and posting PASS/FAIL verdicts to the backlog. Follows `docs/team/qa.agent.md`


## Orchestrator (The Workflow)

The Orchestrator is a pure management layer. It does not perform any coding, grooming, or testing.

**Responsibilities:**
1. **Dispatch**: Select the next item from the backlog and launch the appropriate agent.
2. **Lifecycle Management**: Trigger the BA $\to$ Developer $\to$ QA loop.
3. **Decision Making**: On `FAIL` from QA, restart the Developer agent. On `PASS`, close the issue.

**Lifecycle:**
1. Pick the next open issue from the backlog
2. Launch BA Agent to groom it
3. Launch Developer Agent to implement it
4. Launch QA Agent to verify it
5. If QA returns **FAIL**, loop back to step 3
6. If QA returns **PASS**, close the issue
7. Repeat until the backlog is empty

## Developer rules

1. Resolve **one** work item: Jira key, `docs/stories/**/*.md`, or `docs/epics/*.md` (next ready story)
2. **Read** skills from `.github/skills/` (registry + profile + build-verify)
3. Print PLAN card → **stop** until `plan approved` / `implement` / `go` / `lgtm`
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
- [ ] Reviewer has no open P1 (or human accepted COMMENT-only)
- [ ] QA PASS on ACs (or human waived with reason)
- [ ] A human has read and understood the AI-authored code and tests


