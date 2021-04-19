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
export LANG=en_US

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(colorize zsh-completions zsh-autosuggestions npm docker golang terraform aws kubectl vi-mode rust rustup cargo)
source $ZSH/oh-my-zsh.sh

# completion
#
# kubectl completion
# source <(kubectl completion zsh)
# helm completion
# source <(helm completion zsh)
# digitalocean completion
# source <(doctl completion zsh)
# eval "$(glab completion --shell zsh)"
# lab completion
# lab completion zsh > ~/.oh-my-zsh/custom/plugins/zsh-completions/src/lab
# Github CLI
gh completion -s zsh > /usr/local/share/zsh/site-functions/_gh

# aliases
export EDITOR='nvim'
export PATH="/usr/local/sbin:$PATH:$HOME/.local/bin"
# Cargo
export PATH="$HOME/.cargo/bin:$PATH"

alias e="nvim"
alias v="nvim"
alias vi="nvim"
alias vim="nvim"
alias k="kubectl"
alias t="terraform"
# alias chrome="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"
# alias firefox="/Applications/Firefox.app/Contents/MacOS/firefox"
alias s="git status -b --show-stash"
alias l="git log --color"
alias d="git diff HEAD"
alias ds="git --no-pager diff HEAD --staged"
alias m="git commit -m"
alias a='git add --intent-to-add . && git add --patch'

# alias i="git commit --interactive"
alias pr="gh pr create -a mathieux51"
alias prr="gh pr create -r TierMobility/operations -a mathieux51"
alias prv="gh pr view -w"
alias prm="gh pr merge --squash --delete-branch"

# Notification when done
alias schwifty="osascript -e 'display notification \"I want to see what you got\" with title \"Show me what you got\"'"

# alias for config .cfg repo
alias gitc='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

# tools configuration
# ripgrep
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# fzf
export FZF_DEFAULT_COMMAND="rg --hidden --files --hidden --sort accessed"
export FZF_DEFAULT_OPTS="--layout=reverse"

# saml2aws
eval "$(saml2aws --completion-script-zsh)"

# Go
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export PATH="$GOBIN:$PATH"
export GOROOT=/usr/local/go

# bash functions
function gocov {
  mkdir -p temp
  go test -coverprofile temp/cover.out ./...
  go tool cover -html=temp/cover.out
  rm -rf temp
}

function gif {
  ffmpeg -y -i "$1" -vf scale=600:-1 -pix_fmt rgb24 -r 25 -f gif - |
    gifsicle --optimize=3 --delay=3 > "$2"
}

touch2() { mkdir -p "$(dirname "$1")" && touch "$1" ; }

# AWS CLI
# Disable pager (less)
export AWS_PAGER=""

# k9s
export K9S_EDITOR=$EDITOR

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# zprof # Should be at the end of .zshrc
