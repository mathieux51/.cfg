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
export LANG=en_US


# plugins
#
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# npm docker docker-compose golang rust rustup cargo gh
plugins=(colorize zsh-completions zsh-autosuggestions terraform aws kubectl vi-mode helm ripgrep git-auto-fetch z)
source $ZSH/oh-my-zsh.sh

# aliases
#
export EDITOR='nvim'
export PATH="/usr/local/sbin:$PATH:$HOME/.local/bin"
# Cargo
export PATH="$HOME/.cargo/bin:$PATH"

# krew
export PATH="${PATH}:${HOME}/.krew/bin"

# python3/pip3
export PATH="${PATH}:${HOME}/Library/Python/3.9/bin"

# Ruby
export PATH="/usr/local/opt/ruby/bin:${PATH}"
# export PYENV_ROOT="$HOME/.pyenv"
# export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init --path)"

alias e='nvim'
alias v='nvim'
alias vi='nvim'
# https://github.com/tpope/vim-unimpaired/blob/e52cb4d77fae016639dba005c44e86722498ab3c/doc/unimpaired.txt#L36
# alias vi='stty stop '' -ixoff; nvim'
alias k='kubectl'
alias context='kubectx'
alias t='terraform'
# alias chrome='/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome'
alias firefox='/Applications/Firefox.app/Contents/MacOS/firefox'
alias s='git status -b --show-stash'
alias l='git log --color'
alias d='git diff HEAD'
alias ds='git diff HEAD --staged'
alias dss='git --no-pager diff HEAD --staged'
alias m='git commit -m'
alias a='git add --intent-to-add . && git add --patch'

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
alias alacrittyconfig='vi ~/.config/alacritty/alacritty.yml:141'
alias vimrc='vi ~/.vimrc'
alias weather='curl wttr.in'
# alias docker="lima nerdctl"
# alias docker-compose="lima nerdctl compose"
alias lc="limactl"

# functions
#
function gocov {
  mkdir -p temp
  go test -coverprofile temp/cover.out ./...
  go tool cover -html=temp/cover.out
  rm -rf temp
}

function sp {
  npx spotify-dl "$1"
}

function gif {
  ffmpeg -y -i "$1" -f gif - | gifsicle --delay=4 > "$2"
}

function gif_optim {
  ffmpeg -y -i "$1" -vf scale=600:-1 -pix_fmt rgb24 -r 25 -f gif - | gifsicle --delay=3 > "$2"
}

function touch2 {
  mkdir -p "$(dirname "$1")" && touch "$1"
}

function unlock {
  terraform force-unlock -force "$1"
}

# completion
# circleci completion zsh > /usr/local/share/zsh/site-functions/_circleci
# kn completion zsh > /usr/local/share/zsh/site-functions/_kn
# kustomize completion zsh > /usr/local/share/zsh/site-functions/_kustomize
# limactl completion zsh > /usr/local/share/zsh/site-functions/_limactl
argocd completion zsh > /usr/local/share/zsh/site-functions/_argocd
confluent completion zsh > /usr/local/share/zsh/site-functions/_confluent

# tools configuration
#
# ripgrep
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# fzf
export FZF_DEFAULT_COMMAND="rg --hidden --files --hidden --sort accessed"
export FZF_DEFAULT_OPTS="--layout=reverse"

# saml2aws
eval "$(saml2aws --completion-script-zsh)"

# Go
# export GOROOT="$(brew --prefix golang)/libexec"
export GOROOT="/usr/local/opt/go/libexec"
export GOPATH="$HOME/go"
export PATH="$PATH:${GOPATH}/bin:${GOROOT}/bin"

# AWS CLI
# Disable pager (less)
export AWS_PAGER=""

# k9s
export K9S_EDITOR=$EDITOR

# less
# export LESS="IR"
export LESS="-R"

# java
export PATH="/usr/local/opt/openjdk/bin:$PATH"
export CPPFLAGS="-I/usr/local/opt/openjdk/include"
export JAVA_HOME=$(/usr/libexec/java_home)

export XDG_CONFIG_HOME="$HOME/.config"

function java_fmt {
  java \
  --add-exports jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED \
  --add-exports jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED \
  --add-exports jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED \
  --add-exports jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED \
  --add-exports jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED \
  -jar ~/.local/bin/google-java-format-1.10.0-all-deps.jar \
  --replace \
  "$1"
}

function java_fmt_recursive {
  for i in $(find . -name '*.java'); do java_fmt "$i"; done
}

function github_sync {
  gh api --paginate graphql -f owner="$ORG" -f query='
  query($owner: String!, $per_page: Int = 100, $endCursor: String) {
    repositoryOwner(login: $owner) {
      repositories(first: $per_page, after: $endCursor, ownerAffiliations: OWNER) {
        nodes { sshUrl, name, isArchived }
        pageInfo { hasNextPage endCursor }
      }
    }
  }
' |
  jq -r '.data.repositoryOwner.repositories.nodes[] | select(.isArchived == false) | .sshUrl' |
  xargs -P 50 -n 1 git clone
}

function github_pull {
  ls | xargs -n 1 -P 50 sh -c 'cd "$0" && git reset --hard && (git checkout master || git checkout main) && git pull'
}

function helmdiff {
  RELEASE=$1
  REVISION=$2
  PREV_REVISION=$((REVISION-1))
  vimdiff <(helm get manifest $RELEASE --revision $REVISION) <(helm get manifest $RELEASE --revision $PREV_REVISION)
}

function rgs {
  CONTEXT=${2:=10}
  rg "$1" --max-columns=200 --pretty -C $CONTEXT | less
}

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# zprof # Should be at the end of .zshrc
