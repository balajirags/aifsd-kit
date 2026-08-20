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
  cp "$src" "$dest_dir/SKILL.md"
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

build_claude() {
  local kit_dir="$REPO_ROOT/claude-kit"
  rm -rf "$kit_dir"
  build_common "$kit_dir"
  printf '@AGENTS.md\n' > "$kit_dir/CLAUDE.md"
  mirror_all_skills "$kit_dir/.claude/skills"
  log "Built $kit_dir"
}

build_opencode() {
  local kit_dir="$REPO_ROOT/opencode-kit"
  rm -rf "$kit_dir"
  build_common "$kit_dir"
  mirror_all_skills "$kit_dir/.opencode/skills"
  log "Built $kit_dir"
}

build_pi() {
  local kit_dir="$REPO_ROOT/pi-kit"
  rm -rf "$kit_dir"
  build_common "$kit_dir"
  mirror_all_skills "$kit_dir/.agents/skills"
  log "Built $kit_dir"
}

build_codex() {
  local kit_dir="$REPO_ROOT/codex-kit"
  rm -rf "$kit_dir"
  build_common "$kit_dir"
  mirror_all_skills "$kit_dir/.agents/skills"
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
