# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Debug zsh startup performance,
# uncomment next line and zprof at EOF to see the profile
# zmodload zsh/zprof

# Path to your oh-my-zsh installation.
export ZSH=/Users/${USER}/.oh-my-zsh
export DEFAULT_USER='mathieu'

# ZSH_THEME="agnoster"
ZSH_THEME="powerlevel10k/powerlevel10k"

# language
#
# export LANG=en_US
export LANG=en_US.UTF-8


# plugins
#
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# npm docker docker-compose golang rust rustup gh
plugins=(colorize zsh-completions zsh-autosuggestions terraform aws kubectl zsh-vi-mode helm git-auto-fetch z)
source $ZSH/oh-my-zsh.sh

# configure zsh-vi-mode
export ZVM_CURSOR_STYLE_ENABLED=true
export ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
export ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
export ZVM_VI_HIGHLIGHT_FOREGROUND=#2E3440      # Nord0 - almost black
export ZVM_VI_HIGHLIGHT_BACKGROUND=#88C0D0      # Nord8 - Frost blue
export ZVM_VI_HIGHLIGHT_EXTRASTYLE=bold         # Extra: make it bold

# aliases
#
# brew
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# Go
export GOPATH=$HOME/go
export GOROOT="$(brew --prefix golang)/libexec"
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
# export PYENV_ROOT="$HOME/.pyenv"
# export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init --path)"

# tfswitch
export PATH="$PATH:/$HOME/bin"


alias b='~/ghorg/baupal'
alias e='nvim'
alias v='nvim'
alias vi='nvim'
# https://github.com/tpope/vim-unimpaired/blob/e52cb4d77fae016639dba005c44e86722498ab3c/doc/unimpaired.txt#L36
# alias vi='stty stop '' -ixoff; nvim'
alias k='kubectl'
alias context='kubectx'
alias t='tofu'
# alias chrome='/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome'
alias firefox='/Applications/Firefox.app/Contents/MacOS/firefox'
alias s='git status -b --show-stash'
alias l='git log --color'
alias d='git diff HEAD'
alias ds='git diff HEAD --staged'
alias dss='git --no-pager diff HEAD --staged'
# alias m='git commit --no-verify -m'
alias a='git add --intent-to-add . && git add --patch'
alias f='git fetch && git pull --rebase && git submodule update --init --recursive && git push'
alias j='git fetch && git pull --rebase && git submodule update --init --recursive'
alias terminalshare='ttyd --writable -t "theme=$(cat ~/.config/ttyd/theme.json | jq -r -c)" -t "fontFamily=MonoLisa" --browser zsh'

# alias i="git commit --interactive"
alias pr='gh pr create -a mathieux51'
alias prr='gh pr create -r TierMobility/operations -a mathieux51'
alias prv='gh pr view -w'
alias prm='gh pr merge --squash --delete-branch && git pull'
# Notification when done
alias schwifty="osascript -e 'display notification \"I want to see what you got\" with title \"Show me what you got\"'"

# alias for config .cfg repo
alias gitc='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
alias zshrc='vi ~/.zshrc'
alias zshenv='vi ~/.zshenv'
alias vimrc='vi ~/.vimrc'
# alias docker="lima nerdctl"
# alias docker-compose="lima nerdctl compose"
alias lc="limactl"
alias g="cd .github/workflows"

# functions
function m {
  git commit --no-verify -m "$2" -m "ref https://linear.app/enternow/issue/$1"
}

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
export fpath=($fpath ~/.zsh/completions)
# circleci completion zsh > ~/.zsh/completions/_circleci
# argocd completion zsh > ~/.zsh/completions/_argocd
# confluent completion zsh > ~/.zsh/completions/_confluent
# k9s completion zsh > ~/.zsh/completions/_k9s
# complete -C '/opt/homebrew/bin/aws_completer' aws
# rg --generate complete-zsh > ~/.zsh/completions/_rg

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
  # ghorg clone TierMobility --token=$GITHUB_TOKEN --skip-archived --skip-forks --concurrency=50 &
  ghorg clone "$ORG" --token=$GITHUB_TOKEN --skip-archived --skip-forks --include-submodules --concurrency=50 &
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

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# zprof # Should be at the end of .zshrc

# bun completions
[ -s "/Users/mathieu/.bun/_bun" ] && source "/Users/mathieu/.bun/_bun"
