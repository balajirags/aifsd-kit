#!/usr/bin/env bash
# Generates a ready-to-copy, harness-specific kit directory (<harness>-kit/) at the
# repo root from this kit's source content. Output is gitignored — regenerate on demand.
set -eo pipefail
shopt -s nullglob

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SKILLS_SRC="$REPO_ROOT/docs/skills"
HARNESSES=(claude opencode pi copilot codex)

# docs/team/*.agent.md and docs/discovery/*.agent.md themselves stay put and
# byte-identical (see CLAUDE.md) — process.md/AGENTS-example.md hardcode those
# paths. These are the roles worth an ad hoc, harness-native "/<name>" command
# so a human can invoke one directly instead of relying on AGENTS.md's own
# state-machine routing every time. (TEAM_ROLE_FILES/DISCOVERY_ROLE_FILES are
# defined further below, next to the functions that consume them.)

log() { echo "$*"; }
die() { echo "error: $*" >&2; exit 1; }

frontmatter_block() {
  awk '
    NR == 1 && $0 == "---" { infm = 1; next }
    infm && $0 == "---" { exit }
    infm { print }
  ' "$1"
}

extract_description() {
  local f="$1" line desc
  line=$(frontmatter_block "$f" | grep -m1 '^description:' || true)
  [ -n "$line" ] || die "missing description field in frontmatter: $f"
  desc="${line#description: }"
  desc="${desc%\"}"
  desc="${desc#\"}"
  [ -n "$desc" ] || die "empty description field in frontmatter: $f"
  printf '%s' "$desc"
}

validate_skills() {
  local f
  for f in "$SKILLS_SRC"/*/SKILL.md; do
    extract_description "$f" > /dev/null
  done
}

mirror_skill() {
  local src="$1" dest_root="$2" slug dest_dir
  slug=$(basename "$(dirname "$src")")
  dest_dir="$dest_root/$slug"
  mkdir -p "$dest_dir"
  cp -R "$(dirname "$src")/." "$dest_dir/"
}

mirror_all_skills() {
  local dest_root="$1" f
  for f in "$SKILLS_SRC"/*/SKILL.md; do
    mirror_skill "$f" "$dest_root"
  done
}

role_description() {
  case "$1" in
    ba) printf 'Business Analyst — grooms a BRD/Epic into stories with Gherkin ACs' ;;
    developer) printf 'Developer — implements one story end-to-end with the build-verify gate' ;;
    qa) printf 'QA — validates Story acceptance criteria against a running app' ;;
    reviewer) printf 'Code Reviewer — P1/P2-only review of a diff/PR against Spec + ACs' ;;
    to-prd) printf 'PRD co-author — brainstorm and incrementally write a PRD' ;;
    to-brd) printf 'BRD co-author — turn an approved PRD into BRDs, one per Epic' ;;
    architect) printf 'Architect co-author — HLD (docs/architecture.md) + Spec per BRD' ;;
    *) die "role_description: unknown role: $1" ;;
  esac
}

# Team roles (ba/developer/qa/reviewer) get an isolated invocation by default
# where the harness supports it — reviewer/qa treat this as a hard rule
# (docs/team/reviewer.agent.md, qa.agent.md -> "Run in an isolated context"),
# ba/developer as a soft context-hygiene default. Discovery roles never
# isolate: they're sustained, resumable, human-in-the-loop co-authoring
# sessions by design (docs/discovery/*.agent.md -> Persistence).
TEAM_ROLE_FILES=(
  "docs/team/ba.agent.md"
  "docs/team/developer.agent.md"
  "docs/team/qa.agent.md"
  "docs/team/reviewer.agent.md"
)
DISCOVERY_ROLE_FILES=(
  "docs/discovery/to-prd.agent.md"
  "docs/discovery/to-brd.agent.md"
  "docs/discovery/architect.agent.md"
)

# Claude Code merged custom commands into its Skills system: a single
# .claude/commands/<name>.md both creates "/<name>" AND, via `context: fork`,
# can run as an isolated subagent with no shared conversation history — and a
# `model:` override on that same file applies specifically to that forked
# subagent (see code.claude.com/docs/en/skills.md -> "Run skills in a
# subagent"). So Claude Code needs no separate agent-definition file the way
# OpenCode does below; one generated file does both jobs. `disallowed-tools`
# gives Reviewer's "read-only, never edits code" rule (reviewer.agent.md)
# real enforcement instead of just an instruction.
write_claude_role_command() {
  local dest_dir="$1" role_path="$2" isolate="$3" name desc
  name=$(basename "$role_path" .agent.md)
  desc=$(role_description "$name")
  mkdir -p "$dest_dir"
  {
    printf -- '---\n'
    printf 'description: %s\n' "$desc"
    if [ "$isolate" = "isolate" ]; then
      printf 'context: fork\n'
      printf 'background: false\n'
      printf '# model: opus   # optional: pin this role to a specific model, e.g. a different one than the implementer used — see docs/team/reviewer.agent.md -> "Prefer a different model than the implementer"\n'
      if [ "$name" = "reviewer" ]; then
        printf 'disallowed-tools: Edit, Write, NotebookEdit\n'
      fi
    fi
    printf -- '---\n'
    printf '\n'
    cat "$REPO_ROOT/$role_path"
  } > "$dest_dir/$name.md"
}

mirror_claude_role_commands() {
  local dest_dir="$1" f
  for f in "${TEAM_ROLE_FILES[@]}"; do
    write_claude_role_command "$dest_dir" "$f" isolate
  done
  for f in "${DISCOVERY_ROLE_FILES[@]}"; do
    write_claude_role_command "$dest_dir" "$f" plain
  done
}

# OpenCode keeps agents and commands as two separate mechanisms (no merge like
# Claude Code above): the agent file (.opencode/agents/<name>.md) carries
# mode/model/permission plus the role content as its system prompt; a thin
# command (.opencode/commands/<name>.md) with `agent: <name>` gives it a
# "/<name>" invocation surface. `mode: subagent` (team roles) dispatches into
# a genuinely isolated child session; `mode: primary` (discovery roles) is
# Tab-switchable so a human can hold a sustained conversation in it. Reviewer
# additionally gets `permission: {edit: deny, bash: deny}` — an enforced,
# not just requested, read-only mode.
write_opencode_role_agent() {
  local dest_dir="$1" role_path="$2" mode="$3" name desc
  name=$(basename "$role_path" .agent.md)
  desc=$(role_description "$name")
  mkdir -p "$dest_dir"
  {
    printf -- '---\n'
    printf 'description: %s\n' "$desc"
    printf 'mode: %s\n' "$mode"
    printf '# model: anthropic/claude-opus-4-...   # optional: pin this role to a specific model, e.g. a different one than the implementer used — see docs/team/reviewer.agent.md -> "Prefer a different model than the implementer"\n'
    if [ "$name" = "reviewer" ]; then
      printf 'permission:\n'
      printf '  edit: deny\n'
      printf '  bash: deny\n'
    fi
    printf -- '---\n'
    printf '\n'
    cat "$REPO_ROOT/$role_path"
  } > "$dest_dir/$name.md"
}

write_opencode_role_command() {
  local dest_dir="$1" role_path="$2" name desc
  name=$(basename "$role_path" .agent.md)
  desc=$(role_description "$name")
  mkdir -p "$dest_dir"
  {
    printf -- '---\n'
    printf 'description: %s\n' "$desc"
    printf 'agent: %s\n' "$name"
    printf -- '---\n'
    printf '\n'
    printf 'Begin the %s workflow described in your system prompt.\n' "$name"
  } > "$dest_dir/$name.md"
}

mirror_opencode_role_files() {
  local agents_dir="$1" commands_dir="$2" f
  for f in "${TEAM_ROLE_FILES[@]}"; do
    write_opencode_role_agent "$agents_dir" "$f" subagent
    write_opencode_role_command "$commands_dir" "$f"
  done
  for f in "${DISCOVERY_ROLE_FILES[@]}"; do
    write_opencode_role_agent "$agents_dir" "$f" primary
    write_opencode_role_command "$commands_dir" "$f"
  done
}

# Pi's core prompt templates have no model-override field and no isolated-
# session/subagent concept (verified against pi.dev/docs — that only exists
# via third-party community packages, out of scope here), so this is the
# most a role wrapper can do in core Pi: a named "/<name>" prompt that tells
# Pi to go read the file, with no isolation or per-role model claim implied.
write_role_prompt_plain() {
  local dest_dir="$1" role_path="$2" name desc
  name=$(basename "$role_path" .agent.md)
  desc=$(role_description "$name")
  mkdir -p "$dest_dir"
  {
    printf -- '---\n'
    printf 'description: %s\n' "$desc"
    printf -- '---\n'
    printf '\n'
    printf 'Follow the instructions in `%s` in this repo for the rest of this session.\n' "$role_path"
  } > "$dest_dir/$name.md"
}

mirror_role_prompts_plain() {
  local dest_dir="$1" f
  for f in "${TEAM_ROLE_FILES[@]}" "${DISCOVERY_ROLE_FILES[@]}"; do
    write_role_prompt_plain "$dest_dir" "$f"
  done
}

build_common() {
  local kit_dir="$1" d
  mkdir -p "$kit_dir/docs"
  cp "$REPO_ROOT/docs/process.md" "$kit_dir/docs/"
  cp -R "$REPO_ROOT/docs/team" "$kit_dir/docs/"
  cp -R "$REPO_ROOT/docs/templates" "$kit_dir/docs/"
  cp -R "$REPO_ROOT/docs/discovery" "$kit_dir/docs/"
  cp -R "$REPO_ROOT/docs/example" "$kit_dir/docs/"
  cp "$REPO_ROOT/docs/project-context-example.md" "$kit_dir/docs/project-context-example.md"
  cp "$REPO_ROOT/docs/templates/project-context.template.md" "$kit_dir/docs/project-context.md"
  cp "$REPO_ROOT/docs/templates/architecture.template.md" "$kit_dir/docs/architecture.md"
  for d in prd brd specs epics stories dev-checkpoints; do
    mkdir -p "$kit_dir/docs/$d"
    touch "$kit_dir/docs/$d/.gitkeep"
  done
  cp "$REPO_ROOT/AGENTS-example.md" "$kit_dir/AGENTS.md"
}

# AGENTS.md and every docs/team, docs/discovery, and docs/templates file are
# harness-agnostic on purpose: none of them name a skill path. Harnesses with a
# native skill mechanism (Claude Code, OpenCode, Pi, Codex) discover and judge
# skill relevance themselves from their own native folder, so build_* below only
# needs to put the skill files there — no text in any role file to keep in sync.

# Every generated kit ships its own README.md — the receiving team only has this
# directory, not this source repo's scripts/README.md, so the "how do I actually
# use this" steps have to travel with the kit itself. Steps 4/5 (skill location,
# wiring) are the only harness-specific parts; everything else is shared.
write_kit_readme() {
  local kit_dir="$1" harness="$2" label skill_step wiring_step

  case "$harness" in
    claude)
      label="Claude Code"
      skill_step='Add new skills directly at `.claude/skills/<slug>/SKILL.md`, following the shape in `docs/templates/skill.template.md`. Claude Code discovers and judges relevance for them on its own — `docs/team/*.agent.md` never names a skill path and does not need to.'
      wiring_step='`CLAUDE.md` (a one-line `@AGENTS.md` pointer, already included) auto-loads every session — nothing else required. For an ad hoc way to invoke one role directly, `.claude/commands/<name>.md` is already generated for every role (`/ba`, `/developer`, `/reviewer`, `/qa`, `/to-prd`, `/to-brd`, `/architect`). `/ba`, `/developer`, `/reviewer`, and `/qa` run with `context: fork` (a genuinely isolated subagent, no shared conversation history — the hard rule `reviewer.agent.md`/`qa.agent.md` already ask for) and a commented `# model:` line you can uncomment to pin that role to a different model than whatever implemented the change; `/reviewer` also sets `disallowed-tools: Edit, Write, NotebookEdit` so its read-only rule is enforced, not just requested. `/to-prd`, `/to-brd`, `/architect` run in your current session instead, since those are meant to be sustained, resumable co-authoring conversations, not one-shot isolated runs — they deliberately have no `model:` line, since without `context: fork` that field only overrides the model for the single turn that invokes the command (it reverts on your next message per Claude Code'"'"'s own docs), which would be more confusing than useful across a multi-turn conversation. To run a whole discovery session on a specific model, use Claude Code'"'"'s own `/model <name>` command first (it persists for the session), then invoke `/to-prd`/`/to-brd`/`/architect`.'
      ;;
    opencode)
      label="OpenCode"
      skill_step='Add new skills directly at `.opencode/skills/<slug>/SKILL.md`, following the shape in `docs/templates/skill.template.md`. OpenCode discovers and judges relevance for them on its own.'
      wiring_step='OpenCode auto-loads `AGENTS.md` from the project root with zero config (it traverses upward from the working directory looking for `AGENTS.md`/`CLAUDE.md`) — nothing else required. For an ad hoc way to invoke one role directly, both `.opencode/agents/<name>.md` and `.opencode/commands/<name>.md` are already generated for every role — type `/ba`, `/developer`, `/reviewer`, `/qa`, `/to-prd`, `/to-brd`, or `/architect` in the TUI. `ba`/`developer`/`reviewer`/`qa` are `mode: subagent` (a genuinely isolated child session each time) with a commented `# model:` line you can uncomment to pin that role to a different model than whatever implemented the change; `reviewer` also sets `permission: {edit: deny, bash: deny}` so its read-only rule is enforced, not just requested. `to-prd`/`to-brd`/`architect` are `mode: primary` instead (Tab-switchable), since those are meant to be sustained, resumable co-authoring conversations, not isolated one-shot runs.'
      ;;
    pi)
      label="Pi"
      skill_step='Add new skills directly at `.agents/skills/<slug>/SKILL.md`, following the shape in `docs/templates/skill.template.md`. Pi discovers and judges relevance for them on its own.'
      wiring_step='Tell Pi to read `AGENTS.md` at the start of a session, or point its own instruction mechanism at it. For an ad hoc way to invoke one role directly, `.pi/prompts/<name>.md` is already generated for every role (`/ba`, `/developer`, `/reviewer`, `/qa`, `/to-prd`, `/to-brd`, `/architect`) — each tells Pi to go read the matching `docs/team/`/`docs/discovery/` spec. Project-local prompt templates only load once you'"'"'ve marked this project as trusted in Pi. Unlike Claude Code/OpenCode, core Pi has no per-agent `model:` override or isolated-subagent mechanism to hook into (that only exists via third-party community packages) — so these prompts can'"'"'t give Reviewer/QA the isolated-context or different-model treatment their specs ask for; that part is on you to do manually per session until Pi ships one natively.'
      ;;
    codex)
      label="Codex"
      skill_step='Add new skills directly at `.agents/skills/<slug>/SKILL.md` (the same path Pi uses — both tools converged on it independently), following the shape in `docs/templates/skill.template.md`. Codex discovers and judges relevance for them on its own.'
      wiring_step='Tell Codex to read `AGENTS.md` at the start of a session, or point its own instruction mechanism at it. No per-role `/<name>` commands are shipped here: Codex'"'"'s only markdown-backed custom-prompt mechanism lives at the user-global `~/.codex/prompts/` (not project-local), and OpenAI has marked it deprecated in favor of Skills — so there'"'"'s no project directory to put one in. `AGENTS.md`'"'"'s own routing already resolves the right role automatically; use that instead. If you want Reviewer/QA on a different model per `reviewer.agent.md`/`qa.agent.md`, that'"'"'s a `codex --profile <name>` config file under `$CODEX_HOME` (e.g. `~/.codex/reviewer.config.toml` with `model = "..."`) — inherently per-machine, so this kit can'"'"'t generate or ship it for you.'
      ;;
    copilot)
      label="GitHub Copilot"
      skill_step='Add new skills directly at `docs/skills/<slug>/SKILL.md`, following the shape in `docs/templates/skill.template.md`. GitHub Copilot has no native skill-discovery mechanism, so `.github/copilot-instructions.md` (already generated for you) explicitly tells it to read these and apply whichever are relevant — that instruction only needs to exist once, not per skill.'
      wiring_step='`.github/copilot-instructions.md` (already generated for you) points Copilot at `AGENTS.md` and explains the skills gap above — nothing else required.'
      ;;
    *) die "write_kit_readme: unknown harness: $harness" ;;
  esac

  {
    printf '# %s kit\n' "$label"
    printf '\n'
    printf 'A ready-to-use instance of the AI-augmented delivery kit for %s, generated by `scripts/build-kit.sh %s` from the aifsd-kit source repo. Copy this directory'"'"'s contents into your project, then follow the steps below.\n' "$label" "$harness"
    printf '\n'
    printf '## 1. Copy this directory into your repo\n'
    printf '\n'
    printf "Merge everything in this folder into your project's root — don't overwrite unrelated files already there.\n"
    printf '\n'
    printf '## 2. Fill in `docs/project-context.md`\n'
    printf '\n'
    printf 'The single most important step. It already exists here as a starter (copied from `docs/templates/project-context.template.md`) — fill in your stack, source layout, conventions, build/lint/test commands, Quality Thresholds, and your **Delivery Tracker** (`Jira` / `GitHub Issues` / `Local docs`). Every role file reads this to know where stories live and how status gets posted back.\n'
    printf '\n'
    printf 'A fully filled-in reference example (Java 21/Spring Boot + React/Vite/TypeScript + PostgreSQL/Redis/Kafka) ships at `docs/example/project-context.md` — read it for the level of detail expected, not as a value to copy. Delete `docs/example/` once you'"'"'re done with it (see its own README).\n'
    printf '\n'
    printf 'If your stack is close enough to that example to start from a filled-in file instead of the blank template, `docs/project-context-example.md` is the same content ready to clone: copy it over `docs/project-context.md` and adapt it, rather than filling in the template from scratch.\n'
    printf '\n'
    printf '## 3. Fill in `docs/architecture.md` (optional)\n'
    printf '\n'
    printf 'Leave the starter file as-is until more than one BRD/Epic exists and something is genuinely shared across them.\n'
    printf '\n'
    printf '## 4. Add project skills\n'
    printf '\n'
    printf '%s\n' "$skill_step"
    printf '\n'
    printf '## 5. Wire it into your coding agent\n'
    printf '\n'
    printf '%s\n' "$wiring_step"
    printf '\n'
    printf '## 6. Run it\n'
    printf '\n'
    printf -- '- Starting from scratch: open a session and say "follow `docs/discovery/to-prd.agent.md`, let'"'"'s brainstorm a PRD for X."\n'
    printf -- '- Starting from an existing BRD or Story: tell your coding agent to follow `AGENTS.md` and point it at the BRD/Story — it resolves the right role itself.\n'
    printf '\n'
    printf '## 7. Keep it living\n'
    printf '\n'
    printf "If a human corrects an agent's behavior or a standard, fix the doc that produced the mistake (\`docs/process.md\`, a \`docs/team/*.agent.md\` or \`docs/discovery/*.agent.md\` file, or a template) rather than just that one conversation — see \`docs/process.md\` → Living documents.\n"
    printf '\n'
    printf -- '---\n'
    printf '\n'
    printf 'Regenerate this kit (or build another harness) from the aifsd-kit source repo'"'"'s `scripts/build-kit.sh` whenever `docs/skills/`, `docs/team/`, `docs/templates/`, or `AGENTS-example.md` change upstream.\n'
  } > "$kit_dir/README.md"
}

build_claude() {
  local kit_dir="$REPO_ROOT/claude-kit"
  rm -rf "$kit_dir"
  build_common "$kit_dir"
  printf '@AGENTS.md\n' > "$kit_dir/CLAUDE.md"
  mirror_all_skills "$kit_dir/.claude/skills"
  mirror_claude_role_commands "$kit_dir/.claude/commands"
  write_kit_readme "$kit_dir" claude
  log "Built $kit_dir"
}

build_opencode() {
  local kit_dir="$REPO_ROOT/opencode-kit"
  rm -rf "$kit_dir"
  build_common "$kit_dir"
  mirror_all_skills "$kit_dir/.opencode/skills"
  mirror_opencode_role_files "$kit_dir/.opencode/agents" "$kit_dir/.opencode/commands"
  write_kit_readme "$kit_dir" opencode
  log "Built $kit_dir"
}

build_pi() {
  local kit_dir="$REPO_ROOT/pi-kit"
  rm -rf "$kit_dir"
  build_common "$kit_dir"
  mirror_all_skills "$kit_dir/.agents/skills"
  mirror_role_prompts_plain "$kit_dir/.pi/prompts"
  write_kit_readme "$kit_dir" pi
  log "Built $kit_dir"
}

# Codex's only markdown-backed custom-prompt mechanism lives at the user-global
# ~/.codex/prompts/ (not project-local) and OpenAI has marked it deprecated in
# favor of Skills — there's no project directory to generate role commands
# into, so none are shipped here. See CLAUDE.md gotchas and the codex-kit
# README's wiring step for the explicit callout.
build_codex() {
  local kit_dir="$REPO_ROOT/codex-kit"
  rm -rf "$kit_dir"
  build_common "$kit_dir"
  mirror_all_skills "$kit_dir/.agents/skills"
  write_kit_readme "$kit_dir" codex
  log "Built $kit_dir"
}

build_copilot() {
  local kit_dir="$REPO_ROOT/copilot-kit"
  rm -rf "$kit_dir"
  build_common "$kit_dir"
  mkdir -p "$kit_dir/.github"
  {
    printf 'Follow `AGENTS.md` in this repo for delivery process, roles, and skills.\n'
    printf '\n'
    printf 'Copilot has no native skill-discovery mechanism, unlike this kit'"'"'s other supported harnesses: read `docs/skills/*/SKILL.md` yourself and apply whichever are relevant to the current task — they are not surfaced automatically.\n'
  } > "$kit_dir/.github/copilot-instructions.md"
  mirror_all_skills "$kit_dir/docs/skills"
  write_kit_readme "$kit_dir" copilot
  log "Built $kit_dir"
}

dispatch() {
  case "$1" in
    claude) build_claude ;;
    opencode) build_opencode ;;
    pi) build_pi ;;
    copilot) build_copilot ;;
    codex) build_codex ;;
    *) die "unknown harness: $1 (expected one of: ${HARNESSES[*]}, or 'all')" ;;
  esac
}

dispatch_all() {
  local h
  for h in "${HARNESSES[@]}"; do
    dispatch "$h"
  done
}

interactive_menu() {
  local choice_input choices choice name h
  echo "Build which kit?"
  echo "  1) claude"
  echo "  2) opencode"
  echo "  3) pi"
  echo "  4) copilot"
  echo "  5) codex"
  echo "  6) all"
  read -rp "Enter number(s)/name(s), space-separated: " choice_input
  choices=($choice_input)
  for choice in "${choices[@]}"; do
    case "$choice" in
      1) name=claude ;;
      2) name=opencode ;;
      3) name=pi ;;
      4) name=copilot ;;
      5) name=codex ;;
      6) name=all ;;
      *) name="$choice" ;;
    esac
    if [ "$name" = "all" ]; then
      dispatch_all
    else
      dispatch "$name"
    fi
  done
}

main() {
  validate_skills
  if [ "$#" -eq 0 ]; then
    interactive_menu
  else
    local arg
    for arg in "$@"; do
      if [ "$arg" = "all" ]; then
        dispatch_all
      else
        dispatch "$arg"
      fi
    done
  fi
}

main "$@"
