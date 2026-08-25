#!/usr/bin/env bash
# Generates a ready-to-copy, harness-specific kit directory (<harness>-kit/) at the
# repo root from this kit's source content. Output is gitignored — regenerate on demand.
set -eo pipefail
shopt -s nullglob

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SKILLS_SRC="$REPO_ROOT/docs/skills"
HARNESSES=(claude opencode pi copilot codex)

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

build_common() {
  local kit_dir="$1" d
  mkdir -p "$kit_dir/docs"
  cp "$REPO_ROOT/docs/process.md" "$kit_dir/docs/"
  cp -R "$REPO_ROOT/docs/team" "$kit_dir/docs/"
  cp -R "$REPO_ROOT/docs/templates" "$kit_dir/docs/"
  cp -R "$REPO_ROOT/docs/discovery" "$kit_dir/docs/"
  cp -R "$REPO_ROOT/docs/example" "$kit_dir/docs/"
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
      wiring_step='`CLAUDE.md` (a one-line `@AGENTS.md` pointer, already included) auto-loads every session — nothing else required. For an ad hoc way to invoke one role directly, add a `.claude/commands/<name>.md` slash command whose body is `@docs/team/<name>.agent.md` (or `@docs/discovery/<name>.agent.md`).'
      ;;
    opencode)
      label="OpenCode"
      skill_step='Add new skills directly at `.opencode/skills/<slug>/SKILL.md`, following the shape in `docs/templates/skill.template.md`. OpenCode discovers and judges relevance for them on its own.'
      wiring_step='OpenCode auto-loads `AGENTS.md` from the project root with zero config (it traverses upward from the working directory looking for `AGENTS.md`/`CLAUDE.md`) — nothing else required.'
      ;;
    pi)
      label="Pi"
      skill_step='Add new skills directly at `.agents/skills/<slug>/SKILL.md`, following the shape in `docs/templates/skill.template.md`. Pi discovers and judges relevance for them on its own.'
      wiring_step='Tell Pi to read `AGENTS.md` at the start of a session, or point its own instruction mechanism at it.'
      ;;
    codex)
      label="Codex"
      skill_step='Add new skills directly at `.agents/skills/<slug>/SKILL.md` (the same path Pi uses — both tools converged on it independently), following the shape in `docs/templates/skill.template.md`. Codex discovers and judges relevance for them on its own.'
      wiring_step='Tell Codex to read `AGENTS.md` at the start of a session, or point its own instruction mechanism at it.'
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
  write_kit_readme "$kit_dir" claude
  log "Built $kit_dir"
}

build_opencode() {
  local kit_dir="$REPO_ROOT/opencode-kit"
  rm -rf "$kit_dir"
  build_common "$kit_dir"
  mirror_all_skills "$kit_dir/.opencode/skills"
  write_kit_readme "$kit_dir" opencode
  log "Built $kit_dir"
}

build_pi() {
  local kit_dir="$REPO_ROOT/pi-kit"
  rm -rf "$kit_dir"
  build_common "$kit_dir"
  mirror_all_skills "$kit_dir/.agents/skills"
  write_kit_readme "$kit_dir" pi
  log "Built $kit_dir"
}

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
