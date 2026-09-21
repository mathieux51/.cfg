# Set a beam cursor immediately (vi insert mode). New tmux windows otherwise show
# a block cursor until zle-line-init runs (~0.25s later); this kills that flash.
[[ -t 1 ]] && printf '\e[6 q'

# --- tabprobe (minimal): verifying the 2026-09-11 fpath fix. Delete when quiet.
if [[ -f ~/.tabprobe-on ]]; then
  zmodload zsh/datetime 2>/dev/null
  _TABPROBE_LOG=$HOME/.local/state/tabprobe/events.log
  _TABPROBE_T0=$EPOCHREALTIME
  print -r -- "$_TABPROBE_T0	B_zsh_start	${TMUX_PANE:-none}" >> $_TABPROBE_LOG
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Debug zsh startup performance,
# uncomment next line and zprof at EOF to see the profile
# zmodload zsh/zprof

# oh-my-zsh removed 2026-09-21. The framework was only acting as a loader for
# powerlevel10k + zsh-autosuggestions plus a history/completion config bundle;
# everything it actually contributed is reimplemented inline below. The old
# config is kept commented out. Previous file: ~/.zshrc.pre-omz-removal
#
# Path to your oh-my-zsh installation.
# export ZSH=/Users/${USER}/.oh-my-zsh
# export DEFAULT_USER='mathieu'   # omz theme convention; .p10k.zsh unsets it anyway

# ZSH_THEME="agnoster"
# ZSH_THEME="powerlevel10k/powerlevel10k"

# language
#
# export LANG=en_US
export LANG=en_US.UTF-8


# plugins
#
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# npm docker docker-compose golang rust rustup gh
# zsh-completions removed 2026-09-11: it put 191 completers on fpath but only
# 15 had their tool installed, and none were tools in daily use (git/kubectl/
# helm/docker/gh/aws/jq/rg all come from homebrew, omz cache or zsh itself).
# That was 16% of the compinit scan for openssl/node/gpgconf + macOS utils.
# plugins=(colorize zsh-autosuggestions git-auto-fetch z)
#
# Of those four, only zsh-autosuggestions and z did anything:
#   colorize        - only provides ccat/cless, which need pygmentize or chroma.
#                     Neither is installed, so both aliases were broken. Dropped.
#   git-auto-fetch  - hooks the zle-line-init widget, but the vi cursor-shape
#                     zle-line-init defined further down overwrote that binding.
#                     It had not fetched anything since 2026-06-23. Dropped; the
#                     `f` and `j` aliases below fetch explicitly anyway.
#   zsh-autosuggestions - kept, now from homebrew (see below).
#   z               - kept, plugin file copied to ~/.zsh/zsh-z.plugin.zsh.

# Avoid the slow per-keystroke widget rebind that zsh-autosuggestions does by
# default; rebind once at startup instead. Cuts typing latency noticeably.
export ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# Skip only the completion-dir security audit (compaudit) on each start. This
# keeps oh-my-zsh's normal, fully-working compinit (Tab-completion intact,
# including cd/dir completion) and just trims the slowest safe part. A previous
# `compinit -C` fast-path shaved ~20ms but broke completion, so it's removed.
# ZSH_DISABLE_COMPFIX=true   # omz-only knob; compinit is called with -u below.
# Keep fpath/path duplicate-free. Guards the zcompdump metadata check above
# against any FPATH still inherited from a parent process.
# Homebrew's `brew shellenv` (run from ~/.zprofile, i.e. LOGIN shells only) does
# `fpath[1,0]=".../site-functions"; export FPATH`. So a login shell (every tmux
# tab) sees 15 fpath entries while a non-login `zsh -i` sees 14. oh-my-zsh stored
# `#omz fpath:` in the zcompdump and deleted the dump whenever fpath differed, so
# alternating the two forced a full compinit + zrecompile: 4.7s cold. That was the
# intermittent 5s new-tab hang. .zshrc runs for BOTH kinds of shell, so add the
# entry here unconditionally and keep fpath unexported (2026-09-11).
# NOTE (2026-09-21): with oh-my-zsh gone there is no `#omz fpath:` metadata and
# nothing deletes the zcompdump when fpath changes, so that failure mode cannot
# recur. The normalisation below is kept anyway: it keeps fpath deterministic and
# duplicate-free, which is still worth having.
# Also drop any oh-my-zsh / legacy dirs inherited via a parent's exported FPATH
# (the long-lived tmux server still exports a 20-entry FPATH from a dead
# plugins=() config).
fpath=(${fpath:#$HOME/.oh-my-zsh/*})
fpath=(${fpath:#$HOME/.zsh/completions})
# ~/.zsh/completions is on fpath as a place to drop your own completers. It is
# currently empty: oh-my-zsh's cache dir held _kubectl and _helm, but homebrew
# already ships both in site-functions (symlinked into the Cellar, so they track
# the installed version), and site-functions is searched first. Nothing was lost
# when the omz cache went away (2026-09-21).
fpath=(/opt/homebrew/share/zsh/site-functions $HOME/.zsh/completions $fpath)
typeset -U fpath path
typeset +x fpath

# source $ZSH/oh-my-zsh.sh
# --- oh-my-zsh replacement ---------------------------------------------------
# Everything below reproduces the parts of oh-my-zsh that were actually in use.

# History (was lib/history.zsh). omz silently supplied all of this.
HISTFILE="$HOME/.zsh_history"
[[ $HISTSIZE -lt 50000 ]] && HISTSIZE=50000
[[ $SAVEHIST -lt 10000 ]] && SAVEHIST=10000
setopt extended_history         # record timestamp of command in HISTFILE
setopt hist_expire_dups_first   # delete duplicates first when HISTFILE exceeds HISTSIZE
setopt hist_ignore_dups         # ignore duplicated commands in the history list
setopt hist_ignore_space        # ignore commands that start with a space
setopt hist_verify              # show expanded command before running it
setopt share_history            # share history between running shells

# Completion (was lib/completion.zsh + the compinit block in oh-my-zsh.sh)
zmodload -i zsh/complist
WORDCHARS=''
unsetopt menu_complete flowcontrol
setopt auto_menu complete_in_word always_to_end
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USERNAME -o pid,user,comm -w -w"
bindkey -M menuselect '^o' accept-and-infer-next-history

# Note: this dump path differs from oh-my-zsh's. omz derived its short host from
# `scutil --get ComputerName` ("Mathieu"); $HOST here is "mac.home", so the file
# is now ~/.zcompdump-mac-5.9 instead of ~/.zcompdump-Mathieu-5.9. The old dump
# was deleted; this one is rebuilt once and then cached as normal.
autoload -Uz compinit zrecompile
ZSH_COMPDUMP="${ZDOTDIR:-$HOME}/.zcompdump-${HOST/.*/}-${ZSH_VERSION}"
compinit -u -d "$ZSH_COMPDUMP"
# Compile the dump for faster loading (omz did this too), guarded by a lock dir.
if [[ ! "${ZSH_COMPDUMP}.zwc" -nt "$ZSH_COMPDUMP" ]] \
   && command mkdir "${ZSH_COMPDUMP}.lock" 2>/dev/null; then
  zrecompile -q -p "$ZSH_COMPDUMP"
  command rm -rf "${ZSH_COMPDUMP}.zwc.old" "${ZSH_COMPDUMP}.lock"
fi

# Directories (was lib/directories.zsh). setopt auto_cd is what makes bare
# directory paths work as commands, e.g. the `b` alias below.
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushdminus
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'
alias -- -='cd -'
for i in {1..9}; do alias "$i"="cd -$i"; done; unset i
alias md='mkdir -p'
alias rd=rmdir
function d () {
  if [[ -n $1 ]]; then
    dirs "$@"
  else
    dirs -v | head -n 10
  fi
}
compdef _dirs d

# Misc shell options (was lib/misc.zsh; multios is already on by default)
setopt long_list_jobs       # show long list format job notifications
setopt interactivecomments  # recognize # comments on the command line
alias _='sudo '

# URL quoting on paste / typing (was lib/misc.zsh). Must load before
# zsh-autosuggestions so that it wraps these, matching the old omz order.
autoload -Uz bracketed-paste-magic url-quote-magic
zle -N bracketed-paste bracketed-paste-magic
zle -N self-insert url-quote-magic

# grep (was lib/grep.zsh)
alias grep='grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv}'
alias egrep='grep -E'
alias fgrep='grep -F'

# `history` with no args listed everything under omz (omz_history); the zsh
# builtin only shows the last 16, so keep the old behaviour.
alias history='fc -l 1'

# Colors / ls (was lib/theme-and-appearance.zsh)
autoload -Uz colors && colors
setopt prompt_subst
export LSCOLORS="Gxfxcxdxbxegedabagacad"
export LS_COLORS="di=1;36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"
alias ls='ls -G'
alias ll='ls -lh'
alias la='ls -lAh'
alias lsa='ls -lah'
if command diff --color /dev/null /dev/null &>/dev/null; then
  function diff { command diff --color "$@" }
fi

# Terminal / tmux window titles (was lib/termsupport.zsh)
autoload -Uz add-zsh-hook
function _set_term_title { print -Pn "\e]2;%~\a" }
add-zsh-hook precmd _set_term_title

# Prompt: powerlevel10k, now standalone from homebrew (was the omz custom theme)
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

# zsh-autosuggestions, now standalone from homebrew (was an omz custom plugin)
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-z, copied out of the old omz plugins dir
source ~/.zsh/zsh-z.plugin.zsh
# --- end oh-my-zsh replacement -----------------------------------------------
if [[ -f ~/.tabprobe-on ]]; then print -r -- "$EPOCHREALTIME	B1_omz_done	${TMUX_PANE:-none}" >> $_TABPROBE_LOG; fi

# vi keybindings without the heavy zsh-vi-mode plugin (it adds per-keystroke lag)
bindkey -v
# Kill the 0.4s ESC delay so insert<->normal switching is instant
export KEYTIMEOUT=1

# Key bindings (was lib/key-bindings.zsh). These MUST come after `bindkey -v`,
# which resets the main keymap. omz bound viins/vicmd explicitly, which is why
# its bindings survived `bindkey -v` before. The user's own bindkeys further
# down still take precedence, since they run after this block.
# Note: omz's zle-line-init did `echoti smkx` (terminal application mode); the
# cursor-shape zle-line-init below already overrode that before the removal, so
# it is deliberately not restored here. Both ^[[X and ^[OX forms are bound.
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
autoload -Uz edit-command-line
zle -N edit-command-line

for km in viins vicmd; do
  # Up/Down: search history for lines starting with what is already typed
  bindkey -M $km "^[[A" up-line-or-beginning-search
  bindkey -M $km "^[OA" up-line-or-beginning-search
  bindkey -M $km "^[[B" down-line-or-beginning-search
  bindkey -M $km "^[OB" down-line-or-beginning-search
  # PageUp / PageDown
  bindkey -M $km "^[[5~" up-line-or-history
  bindkey -M $km "^[[6~" down-line-or-history
  # Home / End / Delete
  bindkey -M $km "^[[1~" beginning-of-line
  bindkey -M $km "^[[H"  beginning-of-line
  bindkey -M $km "^[[4~" end-of-line
  bindkey -M $km "^[[F"  end-of-line
  bindkey -M $km "^[[3~" delete-char
  # Shift-Tab cycles the completion menu backwards
  bindkey -M $km "^[[Z" reverse-menu-complete
  # Ctrl-Left / Ctrl-Right / Ctrl-Delete
  bindkey -M $km '^[[1;5C' forward-word
  bindkey -M $km '^[[1;5D' backward-word
  bindkey -M $km '^[[3;5~' kill-word
  # Backspace past the insert point, in normal mode too
  bindkey -M $km '^?' backward-delete-char
done
unset km
bindkey -M viins "^I" expand-or-complete   # Tab
# omz also ran `bindkey \ew kill-region`, `bindkey ' ' magic-space`, `bindkey
# ^[m copy-prev-shell-word` and `bindkey ^X^E edit-command-line` WITHOUT -M.
# That bound them in the emacs keymap, and the `bindkey -v` above then made
# main=viins, so none of them were ever reachable. They are left out rather
# than silently switched on. To enable edit-command-line (useful with nvim):
#   bindkey -M viins '^X^E' edit-command-line

# Cursor shape per mode: beam in insert, block in normal (no plugin, no overhead)
function zle-keymap-select zle-line-init {
  case ${KEYMAP} in
    vicmd)      printf '\e[2 q' ;;  # block
    main|viins) printf '\e[6 q' ;;  # beam
  esac
}
zle -N zle-keymap-select
zle -N zle-line-init
# Reset to beam at each new prompt
function zle-line-finish { printf '\e[6 q'; }
zle -N zle-line-finish

# Restore the editing keys vi mode drops (history search, ^A/^E, backspace fixes)
bindkey '^R' history-incremental-search-backward
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^?' backward-delete-char   # backspace past insert point
bindkey '^H' backward-delete-char
bindkey -M vicmd 'k' up-line-or-search
bindkey -M vicmd 'j' down-line-or-search

# aliases
#
# brew
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# Go
export GOPATH=$HOME/go
export GOROOT="$(brew --prefix golang)/libexec"
if [[ -f ~/.tabprobe-on ]]; then print -r -- "$EPOCHREALTIME	B2_brew_golang	${TMUX_PANE:-none}" >> $_TABPROBE_LOG; fi
export PATH="$PATH:${GOPATH}/bin:${GOROOT}/bin"

# Java
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
# nvim
export EDITOR='nvim'
export PATH="/usr/local/sbin:$PATH:$HOME/.local/bin"
# Cargo
export PATH="$HOME/.cargo/bin:$PATH"

# bun
export PATH="${PATH}:${HOME}/.bun/bin"

# python3/pip3
export PATH="${PATH}:${HOME}/Library/Python/3.9/bin"

# Ruby
eval "$(rbenv init - --no-rehash zsh)"
if [[ -f ~/.tabprobe-on ]]; then print -r -- "$EPOCHREALTIME	B3_rbenv	${TMUX_PANE:-none}" >> $_TABPROBE_LOG; fi
# export PYENV_ROOT="$HOME/.pyenv"
# export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init --path)"

# tfswitch
export PATH="$PATH:/$HOME/bin"

# gcloud
export PATH="/opt/homebrew/share/google-cloud-sdk/bin:$PATH"


alias b='~/ghorg/resourcly'
alias e='nvim'
alias v='nvim'
alias vi='nvim'
# https://github.com/tpope/vim-unimpaired/blob/e52cb4d77fae016639dba005c44e86722498ab3c/doc/unimpaired.txt#L36
# alias vi='stty stop '' -ixoff; nvim'
alias k='kubectl'
alias t='tofu'
# alias chrome='/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome'
alias firefox='/Applications/Firefox.app/Contents/MacOS/firefox'
alias s='git status -b --show-stash'
alias l='git log --color'
alias d='git diff HEAD'
alias du='git -c delta.side-by-side=false diff HEAD'
alias ds='git diff HEAD --staged'
alias dss='git --no-pager diff HEAD --staged'
# alias m='git commit --no-verify -m'
alias a='git add --intent-to-add . && git add --patch'
alias f='git fetch && git pull --rebase && git submodule update --init --recursive && git push'
alias j='git fetch && git pull --rebase && git submodule update --init --recursive'
alias terminalshare='ttyd --writable -t "theme=$(cat ~/.config/ttyd/theme.json | jq -r -c)" -t "fontFamily=MonoLisa" --browser zsh'

# alias i="git commit --interactive"
alias pr='gh pr create -a mathieux51'
alias prv='gh pr view -w'
alias prm='gh pr merge --squash --delete-branch && git pull'
# Notification when done
alias schwifty="osascript -e 'display notification \"I want to see what you got\" with title \"Show me what you got\"'"

# alias for config .cfg repo
alias gitc='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
alias zshrc='vi ~/.zshrc'
alias zshenv='vi ~/.zshenv'
alias vimrc='vi ~/.vimrc'
alias g="cd .github/workflows"
alias "docker compose"="docker-compose"
alias gam="/Users/mathieu/bin/gam7/gam"
alias pager="delta --syntax-theme=Nord --line-numbers --hunk-header-style=omit"

# functions
# function m {
#   git commit --no-verify -m "$2" -m "ref https://linear.app/enternow/issue/$1"
# }

function gocov {
  mkdir -p temp
  go test -coverprofile temp/cover.out ./...
  go tool cover -html=temp/cover.out
  go-test-coverage --config=./.testcoverage.yaml --profile=temp/cover.out
  rm -rf temp
}

function gotest {
  go test ./... -coverprofile=./cover.out -covermode=atomic -coverpkg=./... -race -short && go-test-coverage --config=.testcoverage.yaml --profile=cover.out
}

function golint {
  golangci-lint run -c .golangci.yml
}

function touch2 {
  mkdir -p "$(dirname "$1")" && touch "$1"
}

function unlock {
  terraform force-unlock -force "$1"
}

# completion
# tofu and gcloud ship no zsh completer, so they had NO tab completion at all.
# Neither line below adds an fpath entry, so neither can invalidate the zcompdump.
autoload -U +X bashcompinit && bashcompinit
# OpenTofu speaks the bash `complete -C` protocol natively (COMP_LINE/COMP_POINT).
if (( $+commands[tofu] )); then
  complete -o nospace -C tofu tofu
  complete -o nospace -C tofu t      # the `t` alias
fi
# gcloud's own completion script: 2KB, measured ~1ms.
[[ -r /opt/homebrew/share/google-cloud-sdk/completion.zsh.inc ]] \
  && source /opt/homebrew/share/google-cloud-sdk/completion.zsh.inc
# NOTE: do NOT `export fpath`. Exporting published FPATH to child processes; a
# nested zsh re-imported it, oh-my-zsh re-prepended its plugin dirs, and the grown
# fpath no longer matched the `#omz fpath:` metadata in the zcompdump, so
# oh-my-zsh deleted it and ran a full compinit + zrecompile. That cost 4.7s on a
# cold cache and caused the intermittent 5s new-tab hang (2026-09-08).
# Since oh-my-zsh was removed (2026-09-21) this particular trap is gone, but
# leaving fpath unexported is still the right default.
# ~/.zsh/completions now exists and is on fpath (see above). To add more
# completers, drop an _<tool> file in there; do NOT export fpath.
# argocd completion zsh > ~/.zsh/completions/_argocd
# k9s completion zsh > ~/.zsh/completions/_k9s
# complete -C '/opt/homebrew/bin/aws_completer' aws
# rg --generate complete-zsh > ~/.zsh/completions/_rg

# bun completions
[ -s "/Users/mathieu/.bun/_bun" ] && source "/Users/mathieu/.bun/_bun"
if [[ -f ~/.tabprobe-on ]]; then print -r -- "$EPOCHREALTIME	B4_completions	${TMUX_PANE:-none}" >> $_TABPROBE_LOG; fi

# GCP
function gcloud_completion {
  source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
  source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
}

# tools configuration
#
# ripgrep
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# fzf
export FZF_DEFAULT_COMMAND="rg --hidden --files --hidden --sort accessed"
export FZF_DEFAULT_OPTS="--layout=reverse"

# Disable pager (less)
export AWS_PAGER=""
export GH_PAGER=""

# k9s
export K9S_EDITOR=$EDITOR

# less
# export LESS="IR"
export LESS="-R"

export XDG_CONFIG_HOME="$HOME/.config"

function codesync {
  ORG="${1-baupal}"
  ghorg clone "$ORG" --token=$GHORG_GITHUB_TOKEN --skip-archived --skip-forks --include-submodules --concurrency=50 &
  # ghorg clone all-groups --base-url=$GITLAB_URL --scm=gitlab --token=$GITLAB_TOKEN --skip-archived --concurrency=50 &
  wait
}

function rgs {
  CONTEXT=${2:=10}
  rg "$1" --max-columns=200 --pretty -C $CONTEXT | less
}

function clean {
  find . -type d -name ".terraform" -exec rm -rf {} +
  find . -type f -name ".terraform.lock.hcl" -exec rm {} +
  find . -type d -name "charts" -exec rm -rf {} +
  find . -type f -name "Chart.lock" -exec rm {} +
}

function rgawk {
  separator="${2:-/}"
  index="${3:-1}"
  rg "$1" | awk -v sep="$separator" -v idx="$index" '{split($0, arr, sep); print arr[idx]}' | sort | uniq
}

function unzip_all_charts {
  local chart_dir="charts"
  local dest_dir="/tmp"
  for chart in "$chart_dir"/*.tgz; do
    if [[ -f "$chart" ]]; then
      echo "Unzipping $chart into $dest_dir..."
      tar -xzf "$chart" -C "$dest_dir"
    fi
  done
  cd /tmp
}

function swap {
  local target=${1:-1}
  tmux swap-window -t "$target"
  tmux select-window -t "$target"
}

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
if [[ -f ~/.tabprobe-on ]]; then print -r -- "$EPOCHREALTIME	B5_p10k	${TMUX_PANE:-none}" >> $_TABPROBE_LOG; fi
# zprof # Should be at the end of .zshrc

# Fix AWS CLI pyexpat/libexpat compatibility issue with Python 3.14
export DYLD_LIBRARY_PATH="/opt/homebrew/opt/expat/lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"

# The next line updates PATH for Nebius CLI.
if [ -f '/Users/mathieu/.nebius/path.zsh.inc' ]; then source '/Users/mathieu/.nebius/path.zsh.inc'; fi
if [[ -f ~/.tabprobe-on ]]; then print -r -- "$EPOCHREALTIME	B6_end_of_zshrc	${TMUX_PANE:-none}" >> $_TABPROBE_LOG; fi

# --- tabprobe (minimal): capture a snapshot if a new shell ever takes > 1s again
if [[ -f ~/.tabprobe-on ]]; then
  _tabprobe_precmd() {
    [[ -n $_TABPROBE_C ]] && return
    _TABPROBE_C=1
    local _now=$EPOCHREALTIME
    print -r -- "$_now	C_prompt_ready	${TMUX_PANE:-none}" >> $_TABPROBE_LOG
    if (( _now - _TABPROBE_T0 > 1.0 )); then
      print -r -- "$_now	SLOW	${TMUX_PANE:-none}	$(( _now - _TABPROBE_T0 ))s" >> $_TABPROBE_LOG
      ( ~/.local/bin/tabprobe-incident slow-tab "zsh-start->prompt $(( _now - _TABPROBE_T0 ))s" >/dev/null 2>&1 & )
    fi
  }
  autoload -Uz add-zsh-hook && add-zsh-hook precmd _tabprobe_precmd
fi
