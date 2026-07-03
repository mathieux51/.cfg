#!/bin/zsh
# Status line for Claude Code:
#   - In a git repo: branch, upstream drift, working tree, stash.
#   - In a container of repos (like ~/ghorg/resourcly): compact summary
#     of dirty sub-repos only.
#   - Anywhere else: silent.

CWD="$(jq -r '.workspace.current_dir // .cwd // empty' 2>/dev/null)"
[ -n "$CWD" ] && cd "$CWD" 2>/dev/null

BLUE=$'\033[34m'
GREEN=$'\033[32m'
RED=$'\033[31m'
YELLOW=$'\033[33m'
CYAN=$'\033[36m'
MAGENTA=$'\033[35m'
DIM=$'\033[2m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

# Render one repo's compact st. Reads $1 as an optional label prefix.
# Assumes cwd is inside the repo.
render_repo() {
  local mode="$1"  # "aggregate" or "single"
  local branch ahead=0 behind=0 st staged modified untracked stash out="" repo=""

  branch="$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)"
  repo="$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")"

  if git rev-parse --abbrev-ref @{u} >/dev/null 2>&1; then
    read ahead behind < <(git rev-list --left-right --count HEAD...@{u} 2>/dev/null)
  fi

  st="$(git status --porcelain 2>/dev/null)"
  staged=$(printf '%s\n' "$st" | grep -c '^[MADRC]' | tr -d ' ')
  modified=$(printf '%s\n' "$st" | grep -c '^.[MD]' | tr -d ' ')
  untracked=$(printf '%s\n' "$st" | grep -c '^??' | tr -d ' ')
  stash=$(git stash list 2>/dev/null | wc -l | tr -d ' ')

  # In aggregate mode: skip entirely-clean repos.
  if [ "$mode" = "aggregate" ]; then
    [ "$ahead" = "0" ] && [ "$behind" = "0" ] && [ "$staged" = "0" ] \
      && [ "$modified" = "0" ] && [ "$untracked" = "0" ] && [ "$stash" = "0" ] \
      && return 0
  fi

  out+="${BOLD}${repo}${RESET}"
  [ "$branch" != "main" ] && [ "$branch" != "master" ] && out+="${BLUE}:${branch}${RESET}"

  [ "$ahead" != "0" ]     && out+=" ${GREEN}↑${ahead}${RESET}"
  [ "$behind" != "0" ]    && out+=" ${RED}↓${behind}${RESET}"
  [ "$staged" != "0" ]    && out+=" ${YELLOW}●${staged}${RESET}"
  [ "$modified" != "0" ]  && out+=" ${CYAN}✎${modified}${RESET}"
  [ "$untracked" != "0" ] && out+=" ${DIM}?${untracked}${RESET}"
  [ "$stash" != "0" ]     && out+=" ${MAGENTA}⚑${stash}${RESET}"

  printf '%s' "$out"
}

if git rev-parse --git-dir >/dev/null 2>&1; then
  render_repo "single"
  exit 0
fi

# Aggregate mode: scan immediate subdirs for git repos.
parts=()
for sub in */; do
  [ -d "$sub/.git" ] || continue
  out="$(cd "$sub" && render_repo "aggregate")"
  [ -n "$out" ] && parts+=("$out")
done

if [ ${#parts[@]} -gt 0 ]; then
  sep="  ${DIM}·${RESET}  "
  printf '%s' "${(pj:$sep:)parts}"
fi
