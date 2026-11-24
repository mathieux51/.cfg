#!/bin/zsh
# Status line for Claude Code:
#   - In a git repo: branch, upstream drift, working tree, stash.
#   - In a container of repos (like ~/ghorg/resourcly): compact summary
#     of dirty sub-repos only.
#   - Anywhere else: silent.
#
# Claude Code runs this on every message update plus every refreshInterval, in
# every open session. The old version cost 8-14s and dozens of execs per run in
# a container of ~50 repos, so 7 sessions kept git/grep/tr spawning nonstop, and
# Defender (epsext) pinned a core vetting each exec (2026-11-19). So:
#   - output is cached per cwd for CACHE_TTL seconds and served from the cache,
#   - a stale cache is served immediately and refreshed in the background,
#     with a mkdir lock so only one session rescans a given cwd at a time,
#   - one `git status --porcelain=v2 --branch` per repo; counting is done with
#     zsh builtins instead of grep/tr/wc, and JSON is parsed without jq.

zmodload zsh/datetime zsh/stat 2>/dev/null
CACHE_TTL=20

json="$(<&0)"
CWD=""
if [[ $json =~ '"current_dir"[[:space:]]*:[[:space:]]*"([^"]*)"' ]]; then
  CWD=$match[1]
elif [[ $json =~ '"cwd"[[:space:]]*:[[:space:]]*"([^"]*)"' ]]; then
  CWD=$match[1]
fi
[[ -n $CWD ]] && cd "$CWD" 2>/dev/null

BLUE=$'\033[34m'
GREEN=$'\033[32m'
RED=$'\033[31m'
YELLOW=$'\033[33m'
CYAN=$'\033[36m'
MAGENTA=$'\033[35m'
DIM=$'\033[2m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

# Render one repo's compact status. Assumes cwd is the repo's top level.
render_repo() {
  local mode="$1"  # "aggregate" or "single"
  local branch="" ahead=0 behind=0 staged=0 modified=0 untracked=0 stash=0 out="" line x y
  local -a lines

  lines=("${(@f)$(GIT_OPTIONAL_LOCKS=0 git status --porcelain=v2 --branch 2>/dev/null)}")
  for line in $lines; do
    case $line in
      '# branch.head '*) branch=${line#\# branch.head } ;;
      '# branch.oid '*)  x=${line#\# branch.oid } ;;
      '# branch.ab '*)   x=${line#\# branch.ab }; ahead=${${x%% *}#+}; behind=${${x##* }#-} ;;
      '? '*)             (( untracked++ )) ;;
      [12u]' '*)
        x=${line[3]} y=${line[4]}
        [[ $x != . ]] && (( staged++ ))
        [[ $y == [MD] ]] && (( modified++ ))
        ;;
    esac
  done
  [[ $branch == '(detached)' ]] && branch=detached

  # stash count = lines in the stash reflog (.git may be a file in worktrees)
  local gitdir=.git
  if [[ -f .git ]]; then
    x="$(<.git)"; gitdir=${x#gitdir: }
    [[ $gitdir == */worktrees/* ]] && gitdir=${gitdir%/worktrees/*}
  fi
  [[ -r $gitdir/logs/refs/stash ]] && stash=${#${(f)"$(<$gitdir/logs/refs/stash)"}}

  if [[ $mode == aggregate ]]; then
    (( ahead + behind + staged + modified + untracked + stash == 0 )) && return 0
  fi

  out+="${BOLD}${PWD:t}${RESET}"
  [[ $branch != main && $branch != master ]] && out+="${BLUE}:${branch}${RESET}"

  (( ahead ))     && out+=" ${GREEN}↑${ahead}${RESET}"
  (( behind ))    && out+=" ${RED}↓${behind}${RESET}"
  (( staged ))    && out+=" ${YELLOW}●${staged}${RESET}"
  (( modified ))  && out+=" ${CYAN}✎${modified}${RESET}"
  (( untracked )) && out+=" ${DIM}?${untracked}${RESET}"
  (( stash ))     && out+=" ${MAGENTA}⚑${stash}${RESET}"

  printf '%s' "$out"
}

compute() {
  # Inside a repo: walk up to its top level without spawning git.
  local d=$PWD
  while [[ $d != / ]]; do
    if [[ -e $d/.git ]]; then
      cd "$d" && render_repo single
      return
    fi
    d=${d:h}
  done

  # Aggregate mode: scan immediate subdirs for git repos.
  local sub out
  local -a parts
  for sub in */(N); do
    [[ -e $sub/.git ]] || continue
    out="$(cd "$sub" && render_repo aggregate)"
    [[ -n $out ]] && parts+=("$out")
  done
  if (( ${#parts} )); then
    local sep="  ${DIM}·${RESET}  "
    printf '%s' "${(pj:$sep:)parts}"
  fi
}

cache_dir=${TMPDIR:-/tmp}/claude-statusline
[[ -d $cache_dir ]] || mkdir -p $cache_dir
cache=$cache_dir/${PWD//\//%}
lock=$cache.lock

refresh() {
  compute > $cache.tmp.$$ && mv -f $cache.tmp.$$ $cache
  rmdir $lock 2>/dev/null
}

if [[ -f $cache ]]; then
  print -rn -- "$(<$cache)"
  st=()
  zstat -A st +mtime $cache 2>/dev/null
  if (( EPOCHSECONDS - ${st[1]:-0} >= CACHE_TTL )); then
    # stale: refresh in the background; drop a lock left by a killed refresh
    if [[ -d $lock ]]; then
      zstat -A st +mtime $lock 2>/dev/null
      (( EPOCHSECONDS - ${st[1]:-0} > 120 )) && rmdir $lock 2>/dev/null
    fi
    if mkdir $lock 2>/dev/null; then
      refresh </dev/null >/dev/null 2>&1 &!
    fi
  fi
elif mkdir $lock 2>/dev/null; then
  refresh
  print -rn -- "$(<$cache)"
fi
